const db = require('./db');

/**
 * Write an activity/audit log entry.
 *
 * Deliberately never throws: audit failures must not break the actual
 * operation being logged, so every route can call this fire-and-forget.
 */
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

/**
 * Convenience wrapper that pulls the actor's identity off the Express request
 * (set by the auth middleware) and the client's IP.
 *
 * Actions: login, login_failed, logout, create, update, delete,
 * password_change, status_change
 */
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
