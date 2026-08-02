const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');

router.use(auth);

/**
 * @swagger
 * /receipts:
 *   get:
 *     summary: Get all receipts for the logged-in user
 *     tags: [Receipts]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of receipts
 *       500:
 *         description: Server error
 */
router.get('/', async (req, res) => {
  try {
    const receipts = await db.all(`
      SELECT r.*, t.type, t.amount, t.date as txn_date, t.description, 
             a.bank_name, a.account_name,
             c.name as customer_name
      FROM receipts r
      JOIN transactions t ON r.transaction_id = t.id
      JOIN accounts a ON t.account_id = a.id
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE a.user_id = ?
      ORDER BY r.generated_at DESC
    `, [req.userId]);
    res.json({ success: true, data: receipts });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * @swagger
 * /receipts/{id}:
 *   get:
 *     summary: Get a single receipt by ID
 *     tags: [Receipts]
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
 *         description: Receipt details
 *       404:
 *         description: Receipt not found
 *       500:
 *         description: Server error
 */
router.get('/:id', async (req, res) => {
  try {
    const receipt = await db.get(`
      SELECT r.*, t.type, t.amount, t.date as txn_date, t.description, 
             a.bank_name, a.account_name, a.account_number,
             c.name as customer_name, c.bank_name as customer_bank
      FROM receipts r
      JOIN transactions t ON r.transaction_id = t.id
      JOIN accounts a ON t.account_id = a.id
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE r.id = ? AND a.user_id = ?
    `, [req.params.id, req.userId]);
    if (!receipt) return res.status(404).json({ success: false, message: 'Receipt not found' });
    res.json({ success: true, data: receipt });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
