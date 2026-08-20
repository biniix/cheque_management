const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');
const { audit } = require('../utils/audit');

router.use(auth);

router.get('/', async (req, res) => {
  try {
    const customers = await db.all('SELECT * FROM customers');
    res.json({ success: true, data: customers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { name, bank_name, bank_key, bank_account_number } = req.body;
    const result = await db.run(
      'INSERT INTO customers (user_id, name, bank_name, bank_key, bank_account_number) VALUES (?, ?, ?, ?, ?)',
      [req.userId, name, bank_name || '', bank_key || '', bank_account_number || '']
    );
    const customer = await db.get('SELECT * FROM customers WHERE id = ?', [result.lastID]);

    audit(req, 'create', 'customer', customer.id, `Created customer ${customer.name}`);

    res.status(201).json({ success: true, data: customer });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const customer = await db.get('SELECT * FROM customers WHERE id = ?', [req.params.id]);
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });

    const { name, bank_name, bank_key, bank_account_number } = req.body;
    await db.run(
      'UPDATE customers SET name = COALESCE(?, name), bank_name = COALESCE(?, bank_name), bank_key = COALESCE(?, bank_key), bank_account_number = COALESCE(?, bank_account_number) WHERE id = ?',
      [name || null, bank_name || null, bank_key || null, bank_account_number || null, req.params.id]
    );

    const updated = await db.get('SELECT * FROM customers WHERE id = ?', [req.params.id]);

    audit(req, 'update', 'customer', updated.id, `Updated customer ${updated.name}`);

    res.json({ success: true, data: updated });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const customer = await db.get('SELECT * FROM customers WHERE id = ?', [req.params.id]);
    if (!customer) return res.status(404).json({ success: false, message: 'Customer not found' });

    await db.run('DELETE FROM customers WHERE id = ?', [req.params.id]);

    audit(req, 'delete', 'customer', customer.id, `Deleted customer ${customer.name}`);

    res.json({ success: true, message: 'Customer deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
