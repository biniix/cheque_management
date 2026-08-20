const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');
const { audit } = require('../utils/audit');

router.use(auth);

router.get('/', async (req, res) => {
  try {
    const { bank } = req.query;
    let sql = 'SELECT * FROM cheque_designs';
    const params = [];
    if (bank) {
      sql += ' WHERE bank_key = ?';
      params.push(String(bank));
    }
    sql += ' ORDER BY bank_key, denomination';

    const rows = await db.all(sql, params);
    const data = rows.map((r) => {
      let layout = {};
      try {
        layout = JSON.parse(r.layout_json || '{}');
      } catch (_) {
        layout = {};
      }
      return {
        id: r.id,
        bank_key: r.bank_key,
        denomination: r.denomination,
        layout,
        created_at: r.created_at,
        updated_at: r.updated_at,
      };
    });
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/', adminOnly, async (req, res) => {
  try {
    const bankKey = String((req.body || {}).bank_key || '').trim();
    const denomination = String((req.body || {}).denomination || '');
    const layout = (req.body || {}).layout;

    if (!bankKey) {
      return res.status(400).json({ success: false, message: 'bank_key is required' });
    }
    if (!layout) {
      return res.status(400).json({ success: false, message: 'layout is required' });
    }

    const layoutJson = typeof layout === 'string' ? layout : JSON.stringify(layout);
    const label = `${bankKey}${denomination ? ` (${denomination})` : ''}`;

    const existing = await db.get(
      'SELECT id FROM cheque_designs WHERE bank_key = ? AND denomination = ?',
      [bankKey, denomination]
    );

    if (existing) {
      await db.run(
        'UPDATE cheque_designs SET layout_json = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
        [layoutJson, existing.id]
      );
      audit(req, 'update', 'cheque_design', existing.id, `${label} cheque design updated`);
      return res.json({
        success: true,
        data: { id: existing.id, bank_key: bankKey, denomination, layout },
      });
    }

    const result = await db.run(
      'INSERT INTO cheque_designs (bank_key, denomination, layout_json) VALUES (?, ?, ?)',
      [bankKey, denomination, layoutJson]
    );
    audit(req, 'create', 'cheque_design', result.lastID, `${label} cheque design created`);
    return res.status(201).json({
      success: true,
      data: { id: result.lastID, bank_key: bankKey, denomination, layout },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
