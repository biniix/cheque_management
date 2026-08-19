const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');
const { audit } = require('../utils/audit');

router.use(auth);

/**
 * @swagger
 * /customers:
 *   get:
 *     summary: Get all customers (shared company ledger)
 *     tags: [Customers]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of customers
 *       500:
 *         description: Server error
 */
router.get('/', async (req, res) => {
  try {
    // Shared company ledger: every authenticated user sees all customers.
    const customers = await db.all('SELECT * FROM customers');
    res.json({ success: true, data: customers });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * @swagger
 * /customers:
 *   post:
 *     summary: Create a new customer
 *     tags: [Customers]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name]
 *             properties:
 *               name:
 *                 type: string
 *               bank_name:
 *                 type: string
 *               bank_key:
 *                 type: string
 *               bank_account_number:
 *                 type: string
 *     responses:
 *       201:
 *         description: Customer created
 *       500:
 *         description: Server error
 */
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

/**
 * @swagger
 * /customers/{id}:
 *   put:
 *     summary: Update a customer
 *     tags: [Customers]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               bank_name:
 *                 type: string
 *               bank_key:
 *                 type: string
 *               bank_account_number:
 *                 type: string
 *     responses:
 *       200:
 *         description: Customer updated
 *       404:
 *         description: Customer not found
 *       500:
 *         description: Server error
 */
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

/**
 * @swagger
 * /customers/{id}:
 *   delete:
 *     summary: Delete a customer
 *     tags: [Customers]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Customer deleted
 *       404:
 *         description: Customer not found
 *       500:
 *         description: Server error
 */
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
