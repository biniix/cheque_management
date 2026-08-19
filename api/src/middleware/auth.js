const jwt = require('jsonwebtoken');
const db = require('../utils/db');

async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization || req.headers.Authorization;
  const token = authHeader?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'No token provided' });
  }

  let decoded;
  try {
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }

  try {
    const user = await db.get('SELECT * FROM users WHERE id = ?', [decoded.userId]);
    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }
    if (user.is_active !== 1 && user.is_active !== true) {
      return res.status(403).json({ success: false, message: 'Account is deactivated' });
    }

    req.userId = user.id;
    req.userRole = user.role;
    req.user = user;
    next();
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
}

module.exports = authMiddleware;
