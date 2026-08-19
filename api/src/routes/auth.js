const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const router = express.Router();
const db = require('../utils/db');
const auth = require('../middleware/auth');
const { logActivity, audit } = require('../utils/audit');

/** Best-effort client IP for audit entries. */
function clientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  return (forwarded || (req.socket && req.socket.remoteAddress) || '').toString();
}

/** Parse the module_access JSON column into an array (tolerant of bad data). */
function parseModules(row) {
  try {
    const parsed = JSON.parse(row.module_access || '[]');
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
}

/** Shape a user row for API responses (never expose password_hash). */
function formatUser(user) {
  return {
    id: user.id,
    name: user.name,
    employee_id: user.employee_id,
    role: user.role || 'employee',
    position: user.position || '',
    is_active: user.is_active === 1 || user.is_active === true,
    module_access: parseModules(user),
    must_change_password: user.must_change_password === 1 || user.must_change_password === true,
  };
}

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login with employee ID and password
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [employee_id, password]
 *             properties:
 *               employee_id:
 *                 type: string
 *                 example: admin
 *               password:
 *                 type: string
 *                 format: password
 *                 example: password
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 token:
 *                   type: string
 *                 user:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     name:
 *                       type: string
 *                     employee_id:
 *                       type: string
 *                     role:
 *                       type: string
 *                       enum: [admin, employee]
 *                     position:
 *                       type: string
 *                     is_active:
 *                       type: boolean
 *                     module_access:
 *                       type: array
 *                       items:
 *                         type: string
 *       401:
 *         description: Invalid credentials
 *       403:
 *         description: Account deactivated
 *       500:
 *         description: Server error
 */
router.post('/login', async (req, res) => {
  try {
    const { employee_id, password } = req.body;

    // BINARY forces a byte-wise (case-sensitive) match — 'emp-001' and
    // 'EMP-001' are different accounts regardless of the column collation.
    const user = await db.get('SELECT * FROM users WHERE BINARY employee_id = ?', [employee_id]);
    if (!user) {
      logActivity({
        action: 'login_failed',
        entityType: 'auth',
        details: `Failed login attempt for ${employee_id} (unknown account)`,
        ipAddress: clientIp(req),
      });
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    if (user.is_active !== 1 && user.is_active !== true) {
      logActivity({
        userId: user.id,
        userName: user.name || '',
        employeeId: user.employee_id || '',
        action: 'login_failed',
        entityType: 'auth',
        details: `Login blocked for ${user.name} (${user.employee_id}) — account deactivated`,
        ipAddress: clientIp(req),
      });
      return res.status(403).json({ success: false, message: 'Your account has been deactivated. Contact your administrator.' });
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      logActivity({
        userId: user.id,
        userName: user.name || '',
        employeeId: user.employee_id || '',
        action: 'login_failed',
        entityType: 'auth',
        details: `Failed login attempt for ${user.name} (${user.employee_id})`,
        ipAddress: clientIp(req),
      });
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });

    logActivity({
      userId: user.id,
      userName: user.name || '',
      employeeId: user.employee_id || '',
      action: 'login',
      entityType: 'auth',
      details: `${user.name} (${user.employee_id}) logged in`,
      ipAddress: clientIp(req),
    });

    res.json({
      success: true,
      token,
      user: formatUser(user)
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * @swagger
 * /auth/change-password:
 *   post:
 *     summary: Change the logged-in user's password (requires the current password)
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [old_password, new_password]
 *             properties:
 *               old_password:
 *                 type: string
 *                 format: password
 *               new_password:
 *                 type: string
 *                 format: password
 *                 minLength: 6
 *                 description: Min. 6 characters, must contain both letters and numbers
 *     responses:
 *       200:
 *         description: Password changed
 *       400:
 *         description: Validation error or wrong current password
 *       401:
 *         description: Not authenticated
 *       500:
 *         description: Server error
 */
router.post('/change-password', auth, async (req, res) => {
  try {
    const { old_password, new_password } = req.body;

    if (!old_password || !new_password) {
      return res.status(400).json({ success: false, message: 'Current and new password are required' });
    }
    if (String(new_password).length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }
    if (!/[a-zA-Z]/.test(String(new_password)) || !/[0-9]/.test(String(new_password))) {
      return res.status(400).json({ success: false, message: 'Password must contain both letters and numbers' });
    }

    const user = await db.get('SELECT * FROM users WHERE id = ?', [req.userId]);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const valid = await bcrypt.compare(String(old_password), user.password_hash);
    if (!valid) {
      return res.status(400).json({ success: false, message: 'Current password is incorrect' });
    }

    const passwordHash = await bcrypt.hash(String(new_password), 10);
    await db.run(
      'UPDATE users SET password_hash = ?, must_change_password = 0 WHERE id = ?',
      [passwordHash, user.id]
    );

    audit(req, 'password_change', 'auth', user.id,
      `${user.name} (${user.employee_id}) changed their password`);

    res.json({ success: true, message: 'Password changed successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * @swagger
 * /auth/logout:
 *   post:
 *     summary: Log the current user's logout (records an audit entry)
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Logout recorded
 *       401:
 *         description: Not authenticated
 */
router.post('/logout', auth, async (req, res) => {
  const user = req.user;
  audit(req, 'logout', 'auth', user.id,
    `${user.name} (${user.employee_id}) logged out`);
  res.json({ success: true, message: 'Logged out' });
});

module.exports = router;
