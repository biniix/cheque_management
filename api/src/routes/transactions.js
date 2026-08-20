const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');
const { audit } = require('../utils/audit');

router.use(auth);

router.get('/', async (req, res) => {
  try {
    const transactions = await db.all(
      `SELECT t.*, a.bank_name, a.account_name
       FROM transactions t
       JOIN accounts a ON t.account_id = a.id
       ORDER BY t.date DESC, t.created_at DESC`
    );
    res.json({ success: true, data: transactions });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/', async (req, res) => {
  const conn = await db.beginTransaction();
  try {
    const { account_id, type, method, amount, date, payee, description, reference_no } = req.body;

    const [accountRows] = await conn.query('SELECT * FROM accounts WHERE id = ?', [account_id]);
    const account = accountRows[0];
    if (!account) {
      await db.rollback(conn);
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    const signedAmount = parseFloat(amount);
    const [result] = await conn.query(
      `INSERT INTO transactions (account_id, type, method, amount, date, payee, reference_no, description)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        account_id,
        type,
        method || 'cash',
        signedAmount,
        date,
        payee || '',
        reference_no || '',
        description || '',
      ]
    );

    const newBalance = parseFloat(account.balance) + signedAmount;
    await conn.query('UPDATE accounts SET balance = ? WHERE id = ?', [newBalance, account_id]);

    await db.commit(conn);

    const transaction = await db.get('SELECT * FROM transactions WHERE id = ?', [result.insertId]);

    audit(req, 'create', 'transaction', transaction.id,
      `Recorded ${type} of ETB ${Math.abs(parseFloat(amount))} on ${account.bank_name}${payee ? ` to ${payee}` : ''}`);

    res.status(201).json({ success: true, data: transaction, newBalance });
  } catch (err) {
    await db.rollback(conn).catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id', async (req, res) => {
  const conn = await db.beginTransaction();
  try {
    const txn = await getUserTransaction(req.params.id);
    if (!txn) {
      await db.rollback(conn);
      return res.status(404).json({ success: false, message: 'Transaction not found' });
    }
    const linked = await conn.query('SELECT id FROM cheques WHERE transaction_id = ?', [txn.id]);
    if (linked[0].length > 0) {
      await db.rollback(conn);
      return res.status(400).json({
        success: false,
        message: 'This transaction is linked to a cheque and cannot be edited here',
      });
    }

    const { type, method, amount, date, payee, description } = req.body;

    const newAmount = amount !== undefined ? parseFloat(amount) : parseFloat(txn.amount);
    if (isNaN(newAmount) || newAmount <= 0) {
      await db.rollback(conn);
      return res.status(400).json({ success: false, message: 'Amount must be a positive number' });
    }

    let signedAmount = newAmount;
    if (txn.type === 'transfer' || txn.type === 'cheque_issued') {
      signedAmount = -newAmount;
    } else if (type && (type === 'transfer' || type === 'cheque_issued')) {
      signedAmount = -newAmount;
    }

    const [accounts] = await conn.query('SELECT * FROM accounts WHERE id = ?', [txn.account_id]);
    const account = accounts[0];
    if (!account) {
      await db.rollback(conn);
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    const oldSigned = parseFloat(txn.amount);
    const newBalance = parseFloat(account.balance) - oldSigned + signedAmount;

    await conn.query(
      `UPDATE transactions SET type = ?, method = ?, amount = ?, date = ?, payee = ?, description = ? WHERE id = ?`,
      [
        type ?? txn.type,
        method ?? txn.method ?? 'cash',
        signedAmount,
        date ?? txn.date,
        payee !== undefined ? payee : (txn.payee || ''),
        description !== undefined ? description : (txn.description || ''),
        txn.id,
      ]
    );
    await conn.query('UPDATE accounts SET balance = ? WHERE id = ?', [newBalance, txn.account_id]);

    await db.commit(conn);

    const updated = await getUserTransaction(txn.id);

    audit(req, 'update', 'transaction', txn.id,
      `Edited transaction (${txn.type}) on ${txn.bank_name}`);

    res.json({ success: true, data: updated, newBalance });
  } catch (err) {
    await db.rollback(conn).catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  const conn = await db.beginTransaction();
  try {
    const txn = await getUserTransaction(req.params.id);
    if (!txn) {
      await db.rollback(conn);
      return res.status(404).json({ success: false, message: 'Transaction not found' });
    }
    const linked = await conn.query('SELECT id FROM cheques WHERE transaction_id = ?', [txn.id]);
    if (linked[0].length > 0) {
      await db.rollback(conn);
      return res.status(400).json({
        success: false,
        message: 'This transaction is linked to a cheque and cannot be deleted',
      });
    }

    const [accounts] = await conn.query('SELECT * FROM accounts WHERE id = ?', [txn.account_id]);
    const account = accounts[0];
    if (account) {
      const newBalance = parseFloat(account.balance) - parseFloat(txn.amount);
      await conn.query('UPDATE accounts SET balance = ? WHERE id = ?', [newBalance, txn.account_id]);
    }

    await conn.query('DELETE FROM transactions WHERE id = ?', [txn.id]);
    await db.commit(conn);

    audit(req, 'delete', 'transaction', txn.id,
      `Deleted transaction (${txn.type}) on ${txn.bank_name}`);

    res.json({ success: true, message: 'Transaction deleted' });
  } catch (err) {
    await db.rollback(conn).catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
