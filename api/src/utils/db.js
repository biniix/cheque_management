const mysql = require('mysql2/promise');

let pool;

function getPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'cheque_management_db',
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      enableKeepAlive: true,
      keepAliveInitialDelay: 0,
    });
  }
  return pool;
}

async function all(sql, params = []) {
  const conn = await getPool().getConnection();
  try {
    const [rows] = await conn.query(sql, params);
    return rows;
  } finally {
    conn.release();
  }
}

async function get(sql, params = []) {
  const conn = await getPool().getConnection();
  try {
    const [rows] = await conn.query(sql, params);
    return rows[0] || null;
  } finally {
    conn.release();
  }
}

async function run(sql, params = []) {
  const conn = await getPool().getConnection();
  try {
    const [result] = await conn.query(sql, params);
    return {
      lastID: result.insertId,
      changes: result.affectedRows,
    };
  } finally {
    conn.release();
  }
}

// Transaction support
async function beginTransaction() {
  const conn = await getPool().getConnection();
  await conn.beginTransaction();
  return conn;
}

async function commit(conn) {
  try {
    await conn.commit();
  } finally {
    conn.release();
  }
}

async function rollback(conn) {
  try {
    await conn.rollback();
  } finally {
    conn.release();
  }
}

async function exec(sql) {
  const conn = await getPool().getConnection();
  try {
    const statements = sql.split(';').filter(s => s.trim().length > 0);
    for (const stmt of statements) {
      await conn.query(stmt);
    }
  } finally {
    conn.release();
  }
}

module.exports = { all, get, run, beginTransaction, commit, rollback, exec, getPool };
