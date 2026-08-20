const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');
const { generateRef } = require('../utils/helpers');
const { audit } = require('../utils/audit');

router.use(auth);

function accountLabel(account) {
  return account.account_name
    ? `${account.bank_name} (${account.account_name})`
    : account.bank_name;
}

router.get('/', async (req, res) => {
  try {
    const accounts = await db.all('SELECT * FROM accounts');
    res.json({ success: true, data: accounts });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { bank_name, bank_key, account_name, account_number, balance = 0 } = req.body;
    const result = await db.run(
      'INSERT INTO accounts (user_id, bank_name, bank_key, account_name, account_number, balance) VALUES (?, ?, ?, ?, ?, ?)',
      [req.userId, bank_name, bank_key || '', account_name || '', account_number || '', balance]
    );
    const account = await db.get('SELECT * FROM accounts WHERE id = ?', [result.lastID]);

    audit(req, 'create', 'account', account.id, `Created ${accountLabel(account)} account`);

    res.status(201).json({ success: true, data: account });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const account = await db.get('SELECT * FROM accounts WHERE id = ?', [req.params.id]);
    if (!account) return res.status(404).json({ success: false, message: 'Account not found' });
    const transactions = await db.all(
      'SELECT * FROM transactions WHERE account_id = ? ORDER BY date DESC, created_at DESC',
      [req.params.id]
    );
    res.json({ success: true, data: { ...account, transactions } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const account = await db.get('SELECT * FROM accounts WHERE id = ?', [req.params.id]);
    if (!account) return res.status(404).json({ success: false, message: 'Account not found' });
    const { bank_name, bank_key, account_name, account_number, balance, is_visible } = req.body;
    await db.run(
      'UPDATE accounts SET bank_name = ?, bank_key = ?, account_name = ?, account_number = ?, balance = ?, is_visible = ? WHERE id = ?',
      [
        bank_name ?? account.bank_name,
        bank_key ?? account.bank_key,
        account_name ?? account.account_name,
        account_number ?? account.account_number,
        balance ?? account.balance,
        is_visible !== undefined ? (is_visible ? 1 : 0) : account.is_visible,
        req.params.id
      ]
    );
    const updated = await db.get('SELECT * FROM accounts WHERE id = ?', [req.params.id]);

    audit(req, 'update', 'account', updated.id, `Updated ${accountLabel(updated)} account`);

    res.json({ success: true, data: updated });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const account = await db.get('SELECT * FROM accounts WHERE id = ?', [req.params.id]);
    if (!account) return res.status(404).json({ success: false, message: 'Account not found' });
    await db.run('DELETE FROM accounts WHERE id = ?', [req.params.id]);

    audit(req, 'delete', 'account', account.id, `Deleted ${accountLabel(account)} account`);

    res.json({ success: true, message: 'Account deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/:id/deposit', async (req, res) => {
  const conn = await db.beginTransaction();
  try {
    const { amount, date, method = 'cash', description = '' } = req.body;
    const accountId = parseInt(req.params.id);

    const [accounts] = await conn.query('SELECT * FROM accounts WHERE id = ?', [accountId]);
    const account = accounts[0];
    if (!account) {
      await db.rollback(conn);
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    const newBalance = parseFloat(account.balance) + parseFloat(amount);
    const refNo = generateRef('DEP');

    const [txnResult] = await conn.query(
      'INSERT INTO transactions (account_id, type, method, amount, date, reference_no, description) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [accountId, 'deposit', method, amount, date, refNo, description]
    );
    const txnId = txnResult.insertId;

    await conn.query('UPDATE accounts SET balance = ? WHERE id = ?', [newBalance, accountId]);

    await db.commit(conn);

    const [txns] = await conn.query('SELECT * FROM transactions WHERE id = ?', [txnId]);

    audit(req, 'create', 'transaction', txnId,
      `Deposited ETB ${amount} into ${accountLabel(account)}`);

    res.status(201).json({
      success: true,
      data: { transaction: txns[0], newBalance }
    });
  } catch (err) {
    await db.rollback(conn).catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
