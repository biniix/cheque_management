const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const db = require('../utils/db');

router.use(auth);

router.get('/', async (req, res) => {
  try {
    const accounts = await db.all('SELECT * FROM accounts');

    const totalBalance = accounts.reduce((sum, a) => sum + parseFloat(a.balance || 0), 0);
    const alerts = [];

    accounts.forEach(acc => {
      if (acc.balance < 5000) {
        alerts.push({
          type: 'low_balance',
          severity: acc.balance < 0 ? 'critical' : 'warning',
          message: `${acc.bank_name} balance (ETB ${parseFloat(acc.balance || 0).toFixed(2)}) is below ETB 5,000`,
          accountId: acc.id
        });
      }
    });

    const accountIds = accounts.map(a => a.id);
    let recentTransactions = [];
    let monthlySpending = { income: 0, expense: 0 };

    if (accountIds.length > 0) {
      const placeholders = accountIds.map(() => '?').join(',');

      recentTransactions = await db.all(
        `SELECT t.*, a.bank_name, a.account_name
         FROM transactions t
         JOIN accounts a ON t.account_id = a.id
         WHERE t.account_id IN (${placeholders})
         ORDER BY t.date DESC, t.created_at DESC
         LIMIT 10`,
        accountIds
      );

      const now = new Date();
      const firstOfMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;

      const monthlyRows = await db.all(
        `SELECT SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END) as income,
                SUM(CASE WHEN t.amount < 0 THEN ABS(t.amount) ELSE 0 END) as expense
         FROM transactions t
         WHERE t.account_id IN (${placeholders})
           AND t.date >= ?`,
        [...accountIds, firstOfMonth]
      );

      if (monthlyRows.length > 0) {
        monthlySpending = {
          income: parseFloat(monthlyRows[0].income || 0),
          expense: parseFloat(monthlyRows[0].expense || 0),
        };
      }
    }

    res.json({
      success: true,
      data: {
        totalBalance,
        totalAccounts: accounts.length,
        accounts,
        alerts,
        recentTransactions,
        monthlySpending,
      }
    });
  } catch (err) {
    console.error('Dashboard error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
