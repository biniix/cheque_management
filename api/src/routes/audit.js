const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');

router.use(auth);

/** Admin-only guard — only admins may view the audit trail. */
function adminOnly(req, res, next) {
  if (req.userRole !== 'admin') {
    return res.status(403).json({ success: false, message: 'Admin access required' });
  }
  next();
}

/**
 * @swagger
 * /audit-logs:
 *   get:
 *     summary: List activity/audit logs (admin only)
 *     tags: [Audit Logs]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 300 }
 *         description: Max rows to return (capped at 1000)
 *       - in: query
 *         name: action
 *         schema: { type: string, enum: [login, login_failed, logout, create, update, delete, password_change, status_change] }
 *       - in: query
 *         name: entity
 *         schema: { type: string }
 *         description: entity_type filter (employee, account, customer, transaction, transfer, cheque, chequebook, auth)
 *       - in: query
 *         name: entityId
 *         schema: { type: integer }
 *         description: Only rows for this specific entity row (used together with entity)
 *       - in: query
 *         name: q
 *         schema: { type: string }
 *         description: Search in user name, employee ID or details
 *     responses:
 *       200:
 *         description: List of audit log entries (newest first)
 *       403:
 *         description: Admin access required
 *       500:
 *         description: Server error
 */
router.get('/', adminOnly, async (req, res) => {
  try {
    const { action, entity, q } = req.query;
    const limit = Math.min(parseInt(req.query.limit, 10) || 300, 1000);

    const where = [];
    const params = [];
    if (action) {
      where.push('action = ?');
      params.push(String(action));
    }
    if (entity) {
      where.push('entity_type = ?');
      params.push(String(entity));
    }
    if (req.query.entityId !== undefined && req.query.entityId !== '') {
      const entityId = parseInt(req.query.entityId, 10);
      if (!Number.isNaN(entityId)) {
        where.push('entity_id = ?');
        params.push(entityId);
      }
    }
    if (q) {
      const like = `%${String(q)}%`;
      where.push('(user_name LIKE ? OR employee_id LIKE ? OR details LIKE ?)');
      params.push(like, like, like);
    }

    const sql =
      'SELECT * FROM audit_logs' +
      (where.length > 0 ? ` WHERE ${where.join(' AND ')}` : '') +
      ' ORDER BY created_at DESC, id DESC LIMIT ?';
    params.push(limit);

    const logs = await db.all(sql, params);
    res.json({ success: true, data: logs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
