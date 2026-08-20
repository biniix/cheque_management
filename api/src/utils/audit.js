const db = require('./db');

async function logActivity({
  userId = null,
  userName = '',
  employeeId = '',
  action,
  entityType = '',
  entityId = null,
  details = '',
  ipAddress = '',
} = {}) {
  try {
    await db.run(
      `INSERT INTO audit_logs (user_id, user_name, employee_id, action, entity_type, entity_id, details, ip_address)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, userName, employeeId, action, entityType, entityId, details, ipAddress]
    );
  } catch (err) {
    console.error('audit: failed to write log entry:', err.message);
  }
}

function audit(req, action, entityType, entityId, details) {
  const user = req.user || {};
  const forwarded = req.headers['x-forwarded-for'];
  const ip = (forwarded || (req.socket && req.socket.remoteAddress) || '').toString();
  return logActivity({
    userId: user.id,
    userName: user.name || '',
    employeeId: user.employee_id || '',
    action,
    entityType,
    entityId,
    details,
    ipAddress: ip,
  });
}

module.exports = { logActivity, audit };
