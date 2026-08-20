const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');
const { generateRef } = require('../utils/helpers');
const { audit } = require('../utils/audit');

router.use(auth);

router.post('/', async (req, res) => {
  const conn = await db.beginTransaction();
  try {
    const { account_id, customer_id, amount, date, method = 'cash', description = '' } = req.body;

    const [accounts] = await conn.query('SELECT * FROM accounts WHERE id = ?', [account_id]);
    const account = accounts[0];
    if (!account) {
      await db.rollback(conn);
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    let customerName = '';
    if (customer_id) {
      const [customers] = await conn.query('SELECT * FROM customers WHERE id = ?', [customer_id]);
      const customer = customers[0];
      if (!customer) {
        await db.rollback(conn);
        return res.status(404).json({ success: false, message: 'Customer not found' });
      }
      customerName = customer.name;
    }

    const newBalance = parseFloat(account.balance) - parseFloat(amount);
    const warnings = [];
    if (newBalance < 0) {
      warnings.push(`This transfer will overdraw the account (new balance: ETB ${newBalance.toFixed(2)})`);
    } else if (newBalance < 5000) {
      warnings.push(`Low balance warning: ETB ${newBalance.toFixed(2)} remaining`);
    }

    const refNo = generateRef('TRF');

    const [txnResult] = await conn.query(
      'INSERT INTO transactions (account_id, customer_id, type, method, amount, date, reference_no, description, payee) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [account_id, customer_id || null, 'transfer', method, -amount, date, refNo, description, customerName]
    );
    const txnId = txnResult.insertId;

    await conn.query('UPDATE accounts SET balance = ? WHERE id = ?', [newBalance, account_id]);

    await db.commit(conn);

    const [txns] = await conn.query('SELECT * FROM transactions WHERE id = ?', [txnId]);

    audit(req, 'create', 'transfer', txnId,
      `Transferred ETB ${amount} from ${account.bank_name}` +
      (customerName ? ` to ${customerName}` : ''));

    res.status(201).json({
      success: true,
      warnings: warnings.length > 0 ? warnings : undefined,
      data: { transaction: txns[0], newBalance }
    });
  } catch (err) {
    await db.rollback(conn).catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
