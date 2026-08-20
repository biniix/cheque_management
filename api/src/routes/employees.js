const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');
const { audit } = require('../utils/audit');

router.use(auth);

function adminOnly(req, res, next) {
  if (req.userRole !== 'admin') {
    return res.status(403).json({ success: false, message: 'Admin access required' });
  }
  next();
}

function parseModules(row) {
  try {
    const parsed = JSON.parse(row.module_access || '[]');
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
}

function formatEmployee(user) {
  return {
    id: user.id,
    name: user.name,
    employee_id: user.employee_id,
    role: user.role || 'employee',
    position: user.position || '',
    is_active: user.is_active === 1 || user.is_active === true,
    module_access: parseModules(user),
    must_change_password: user.must_change_password === 1 || user.must_change_password === true,
    created_at: user.created_at,
  };
}

async function nextEmployeeId() {
  const rows = await db.all("SELECT employee_id FROM users WHERE employee_id LIKE 'EMP-%'");
  let max = 0;
  for (const row of rows) {
    const match = /^EMP-(\d+)$/i.exec((row.employee_id || '').trim());
    if (match) {
      max = Math.max(max, parseInt(match[1], 10));
    }
  }
  return `EMP-${String(max + 1).padStart(3, '0')}`;
}

router.get('/', adminOnly, async (req, res) => {
  try {
    const users = await db.all('SELECT * FROM users ORDER BY created_at ASC');
    res.json({ success: true, data: users.map(formatEmployee) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/', adminOnly, async (req, res) => {
  try {
    const { name, position = '', password, module_access = [] } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'Full name is required' });
    }
    if (!password || String(password).length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }
    if (!Array.isArray(module_access)) {
      return res.status(400).json({ success: false, message: 'module_access must be an array' });
    }

    const employeeId = await nextEmployeeId();
    const passwordHash = await bcrypt.hash(String(password), 10);

    const result = await db.run(
      `INSERT INTO users (name, employee_id, password_hash, role, position, is_active, module_access, must_change_password)
       VALUES (?, ?, ?, 'employee', ?, 1, ?, 1)`,
      [name.trim(), employeeId, passwordHash, position.trim(), JSON.stringify(module_access)]
    );

    const user = await db.get('SELECT * FROM users WHERE id = ?', [result.lastID]);

    audit(req, 'create', 'employee', result.lastID,
      `Created employee ${user.name} (${user.employee_id})`);

    res.status(201).json({ success: true, data: formatEmployee(user) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id', adminOnly, async (req, res) => {
  try {
    const employee = await db.get('SELECT * FROM users WHERE id = ?', [req.params.id]);
    if (!employee) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }

    const { name, position, password, module_access } = req.body;

    if (name !== undefined && (!name || !name.trim())) {
      return res.status(400).json({ success: false, message: 'Full name cannot be empty' });
    }
    if (password !== undefined && password !== '' && String(password).length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }
    if (module_access !== undefined && !Array.isArray(module_access)) {
      return res.status(400).json({ success: false, message: 'module_access must be an array' });
    }

    const updates = [];
    const params = [];
    const passwordReset = password !== undefined && password !== '';

    if (name !== undefined) {
      updates.push('name = ?');
      params.push(name.trim());
    }
    if (position !== undefined) {
      updates.push('position = ?');
      params.push(position.trim());
    }
    if (passwordReset) {
      updates.push('password_hash = ?');
      params.push(await bcrypt.hash(String(password), 10));

      updates.push('must_change_password = 1');
    }
    if (module_access !== undefined) {
      updates.push('module_access = ?');
      params.push(JSON.stringify(module_access));
    }

    if (updates.length > 0) {
      params.push(req.params.id);
      await db.run(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`, params);
    }

    const updated = await db.get('SELECT * FROM users WHERE id = ?', [req.params.id]);

    audit(req, 'update', 'employee', updated.id,
      `Updated employee ${updated.name} (${updated.employee_id})` +
      (passwordReset ? ' — password reset by admin' : ''));

    res.json({ success: true, data: formatEmployee(updated) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/:id/status', adminOnly, async (req, res) => {
  try {
    const { is_active } = req.body;
    const employee = await db.get('SELECT * FROM users WHERE id = ?', [req.params.id]);
    if (!employee) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }
    if (employee.role === 'admin') {
      return res.status(400).json({ success: false, message: 'The admin account cannot be deactivated' });
    }

    await db.run('UPDATE users SET is_active = ? WHERE id = ?', [is_active ? 1 : 0, req.params.id]);
    const updated = await db.get('SELECT * FROM users WHERE id = ?', [req.params.id]);

    audit(req, 'status_change', 'employee', updated.id,
      `${is_active ? 'Activated' : 'Deactivated'} account for ${updated.name} (${updated.employee_id})`);

    res.json({ success: true, data: formatEmployee(updated) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/:id', adminOnly, async (req, res) => {
  try {
    const employee = await db.get('SELECT * FROM users WHERE id = ?', [req.params.id]);
    if (!employee) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }
    if (employee.role === 'admin') {
      return res.status(400).json({ success: false, message: 'The admin account cannot be deleted' });
    }

    await db.run('DELETE FROM users WHERE id = ?', [req.params.id]);

    audit(req, 'delete', 'employee', employee.id,
      `Deleted employee ${employee.name} (${employee.employee_id})`);

    res.json({ success: true, message: 'Employee deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
