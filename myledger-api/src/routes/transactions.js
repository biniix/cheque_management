const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');

router.use(auth);

/**
 * @swagger
 * /transactions:
 *   post:
 *     summary: Save a transaction to the server
 *     tags: [Transactions]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [account_id, type, amount, date]
 *             properties:
 *               account_id:
 *                 type: integer
 *               type:
 *                 type: string
 *                 example: deposit
 *               amount:
 *                 type: number
 *                 example: 5000
 *               date:
 *                 type: string
 *                 format: date
 *                 example: 2026-07-30
 *               payee:
 *                 type: string
 *               description:
 *                 type: string
 *               reference_no:
 *                 type: string
 *     responses:
 *       201:
 *         description: Transaction created
 *       404:
 *         description: Account not found
 *       500:
 *         description: Server error
 */
router.post('/', async (req, res) => {
  try {
    const { account_id, type, amount, date, payee, description, reference_no } = req.body;

    // Verify the account belongs to this user
    const account = await db.get('SELECT * FROM accounts WHERE id = ? AND user_id = ?', [account_id, req.userId]);
    if (!account) {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    const result = await db.run(
      `INSERT INTO transactions (account_id, type, amount, date, payee, reference_no, description)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        account_id,
        type,
        amount,
        date,
        payee || '',
        reference_no || '',
        description || '',
      ]
    );

    const transaction = await db.get('SELECT * FROM transactions WHERE id = ?', [result.lastID]);
    res.status(201).json({ success: true, data: transaction });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
