const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');

router.use(auth);

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
