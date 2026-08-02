const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');
const { generateRef, generateChequeNumber } = require('../utils/helpers');
const { numberToWords } = require('../utils/numberToWords');

router.use(auth);

// ── Helper: format a raw DB cheque row for the Flutter app ──
function formatCheque(cheque) {
  if (!cheque) return null;
  return {
    ...cheque,
    // crossed is TINYINT(1) in MySQL → convert to boolean for Flutter
    crossed: cheque.crossed === 1 || cheque.crossed === true,
    // amount as number
    amount: parseFloat(cheque.amount),
  };
}

/**
 * @swagger
 * /cheques/books:
 *   get:
 *     summary: Get all cheque books
 *     tags: [Cheques]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of cheque books
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/ChequeBook'
 *       500:
 *         description: Server error
 */
router.get('/books', async (req, res) => {
  try {
    const books = await db.all(`
      SELECT cb.*, a.bank_name, a.account_name 
      FROM chequebooks cb 
      JOIN accounts a ON cb.account_id = a.id 
      WHERE a.user_id = ?
    `, [req.userId]);

    for (const book of books) {
      const row = await db.get('SELECT COUNT(*) as count FROM cheques WHERE chequebook_id = ?', [book.id]);
      book.used = row.count;
      book.remaining = book.size - book.used;
    }
    res.json({ success: true, data: books });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * @swagger
 * /cheques/books:
 *   post:
 *     summary: Create a new cheque book
 *     tags: [Cheques]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [account_id, size, start_number]
 *             properties:
 *               account_id:
 *                 type: integer
 *               size:
 *                 type: integer
 *                 description: Number of cheques
 *                 example: 25
 *               start_number:
 *                 type: string
 *                 example: "1001"
 *     responses:
 *       201:
 *         description: Cheque book created
 *       404:
 *         description: Account not found
 *       500:
 *         description: Server error
 */
router.post('/books', async (req, res) => {
  try {
    const { account_id, size, start_number } = req.body;
    const account = await db.get('SELECT * FROM accounts WHERE id = ? AND user_id = ?', [account_id, req.userId]);
    if (!account) return res.status(404).json({ success: false, message: 'Account not found' });

    const startNum = parseInt(start_number);
    const endNum = startNum + size - 1;
    const end_number = endNum.toString().padStart(start_number.length, '0');

    const result = await db.run(
      'INSERT INTO chequebooks (account_id, size, start_number, end_number) VALUES (?, ?, ?, ?)',
      [account_id, size, start_number, end_number]
    );
    const book = await db.get('SELECT * FROM chequebooks WHERE id = ?', [result.lastID]);
    res.status(201).json({ success: true, data: book });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * @swagger
 * /cheques/books/{id}/next-number:
 *   get:
 *     summary: Get the next available cheque number for a cheque book
 *     tags: [Cheques]
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
 *         description: Next cheque number
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     nextNumber:
 *                       type: string
 *                     remaining:
 *                       type: integer
 *       400:
 *         description: Cheque book is full
 *       404:
 *         description: Cheque book not found
 *       500:
 *         description: Server error
 */
router.get('/books/:id/next-number', async (req, res) => {
  try {
    const book = await db.get(`
      SELECT cb.*, a.user_id FROM chequebooks cb 
      JOIN accounts a ON cb.account_id = a.id 
      WHERE cb.id = ?
    `, [req.params.id]);

    if (!book || book.user_id !== req.userId) {
      return res.status(404).json({ success: false, message: 'Cheque book not found' });
    }

    const row = await db.get('SELECT COUNT(*) as count FROM cheques WHERE chequebook_id = ?', [req.params.id]);
    const usedCount = row.count;
    if (usedCount >= book.size) {
      return res.status(400).json({ success: false, message: 'Cheque book is full' });
    }

    const nextNum = generateChequeNumber(book.start_number, usedCount);
    res.json({ success: true, data: { nextNumber: nextNum, remaining: book.size - usedCount } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * @swagger
 * /cheques:
 *   post:
 *     summary: Write (issue) a new cheque
 *     tags: [Cheques]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [chequebook_id, date, amount]
 *             properties:
 *               chequebook_id:
 *                 type: integer
 *               date:
 *                 type: string
 *                 format: date
 *               payee:
 *                 type: string
 *               amount:
 *                 type: number
 *               bearer_or_order:
 *                 type: string
 *                 enum: [bearer, order]
 *                 default: bearer
 *               crossed:
 *                 type: boolean
 *                 default: false
 *     responses:
 *       201:
 *         description: Cheque issued
 *       400:
 *         description: Validation error
 *       404:
 *         description: Cheque book not found
 *       409:
 *         description: Insufficient funds
 *       500:
 *         description: Server error
 */
router.post('/', async (req, res) => {
  const conn = await db.beginTransaction();
  try {
    const { chequebook_id, date, payee, amount, bearer_or_order, crossed = false } = req.body;

    const [books] = await conn.query(`
      SELECT cb.*, a.id as account_id, a.balance, a.user_id, a.bank_name 
      FROM chequebooks cb 
      JOIN accounts a ON cb.account_id = a.id 
      WHERE cb.id = ?
    `, [chequebook_id]);

    const book = books[0];
    if (!book || book.user_id !== req.userId) {
      await db.rollback(conn);
      return res.status(404).json({ success: false, message: 'Cheque book not found' });
    }

    if (bearer_or_order === 'order' && (!payee || payee.trim() === '')) {
      await db.rollback(conn);
      return res.status(400).json({ success: false, message: 'Order cheque requires a payee name' });
    }

    const [countRows] = await conn.query('SELECT COUNT(*) as count FROM cheques WHERE chequebook_id = ?', [chequebook_id]);
    const chequeNumber = generateChequeNumber(book.start_number, countRows[0].count);

    const chequeDate = new Date(date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const isPostDated = chequeDate > today;
    const sufficient = parseFloat(book.balance) >= parseFloat(amount);
    let deductBalance = false;
    const warnings = [];

    if (sufficient) {
      deductBalance = true;
    } else if (isPostDated) {
      warnings.push(`Insufficient funds. Deposit ETB ${(amount - book.balance).toFixed(2)} before ${date} to honor this cheque.`);
    } else {
      await db.rollback(conn);
      return res.status(409).json({
        success: false,
        code: 'INSUFFICIENT_FUNDS',
        message: 'Insufficient funds. Deposit funds or cancel the cheque.',
        shortfall: amount - book.balance
      });
    }

    const amountInWords = numberToWords(amount);
    const refNo = generateRef('CHQ');

    const [txnResult] = await conn.query(
      'INSERT INTO transactions (account_id, type, amount, date, reference_no, description) VALUES (?, ?, ?, ?, ?, ?)',
      [book.account_id, 'cheque_issued', -amount, date, refNo, `Cheque #${chequeNumber} to ${payee || 'Bearer'}`]
    );
    const txnId = txnResult.insertId;

    const [chqResult] = await conn.query(
      'INSERT INTO cheques (chequebook_id, transaction_id, cheque_number, date, payee, amount, amount_in_words, bearer_or_order, crossed, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [chequebook_id, txnId, chequeNumber, date, payee || '', amount, amountInWords, bearer_or_order, crossed ? 1 : 0, 'Issued']
    );
    const chequeId = chqResult.insertId;

    let newBalance = parseFloat(book.balance);
    if (deductBalance) {
      newBalance = book.balance - parseFloat(amount);
      await conn.query('UPDATE accounts SET balance = ? WHERE id = ?', [newBalance, book.account_id]);
    }

    const receiptRef = generateRef();
    await conn.query('INSERT INTO receipts (transaction_id, reference_no) VALUES (?, ?)', [txnId, receiptRef]);

    await db.commit(conn);

    const [cheques] = await conn.query('SELECT * FROM cheques WHERE id = ?', [chequeId]);
    const [txns] = await conn.query('SELECT * FROM transactions WHERE id = ?', [txnId]);

    res.status(201).json({
      success: true,
      warnings: warnings.length > 0 ? warnings : undefined,
      data: { cheque: formatCheque(cheques[0]), transaction: txns[0], newBalance, deducted: deductBalance }
    });
  } catch (err) {
    await db.rollback(conn).catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * @swagger
 * /cheques:
 *   get:
 *     summary: Get all cheques
 *     tags: [Cheques]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of cheques
 *       500:
 *         description: Server error
 */
router.get('/', async (req, res) => {
  try {
    const cheques = await db.all(`
      SELECT c.*, cb.account_id, a.bank_name 
      FROM cheques c 
      JOIN chequebooks cb ON c.chequebook_id = cb.id 
      JOIN accounts a ON cb.account_id = a.id 
      WHERE a.user_id = ? 
      ORDER BY c.date DESC
    `, [req.userId]);
    res.json({ success: true, data: cheques.map(formatCheque) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * @swagger
 * /cheques/{id}:
 *   get:
 *     summary: Get a single cheque by ID
 *     tags: [Cheques]
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
 *         description: Cheque details
 *       404:
 *         description: Cheque not found
 *       500:
 *         description: Server error
 */
router.get('/:id', async (req, res) => {
  try {
    const cheque = await db.get(`
      SELECT c.*, a.bank_name, a.account_name, a.account_number 
      FROM cheques c 
      JOIN chequebooks cb ON c.chequebook_id = cb.id 
      JOIN accounts a ON cb.account_id = a.id 
      WHERE c.id = ? AND a.user_id = ?
    `, [req.params.id, req.userId]);
    if (!cheque) return res.status(404).json({ success: false, message: 'Cheque not found' });
    res.json({ success: true, data: formatCheque(cheque) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * @swagger
 * /cheques/{id}/status:
 *   patch:
 *     summary: Update cheque status (e.g. mark as Void)
 *     tags: [Cheques]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [status]
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [Issued, Encashed, Void]
 *     responses:
 *       200:
 *         description: Status updated
 *       404:
 *         description: Cheque not found
 *       500:
 *         description: Server error
 */
router.patch('/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const cheque = await db.get(`
      SELECT c.*, cb.account_id, a.balance, a.user_id 
      FROM cheques c 
      JOIN chequebooks cb ON c.chequebook_id = cb.id 
      JOIN accounts a ON cb.account_id = a.id 
      WHERE c.id = ? AND a.user_id = ?
    `, [req.params.id, req.userId]);
    if (!cheque) return res.status(404).json({ success: false, message: 'Cheque not found' });

    await db.run('UPDATE cheques SET status = ? WHERE id = ?', [status, req.params.id]);

    // Refund amount to account when voiding
    if (status === 'Void' && cheque.amount > 0) {
      const newBalance = parseFloat(cheque.balance) + parseFloat(cheque.amount);
      await db.run('UPDATE accounts SET balance = ? WHERE id = ?', [newBalance, cheque.account_id]);
    }

    const updated = await db.get('SELECT * FROM cheques WHERE id = ?', [req.params.id]);
    res.json({ success: true, data: formatCheque(updated) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
