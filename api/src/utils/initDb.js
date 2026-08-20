require('dotenv').config();
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

async function initDatabase() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
  });

  const dbName = process.env.DB_NAME || 'database';
  await conn.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
  await conn.query(`USE \`${dbName}\``);

  console.log(`📦 MySQL database: ${dbName}`);

  await conn.query(`
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        employee_id VARCHAR(50) COLLATE utf8mb4_bin UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(20) NOT NULL DEFAULT 'employee',
        position VARCHAR(100) NOT NULL DEFAULT '',
        is_active TINYINT(1) NOT NULL DEFAULT 1,
        module_access TEXT,
        must_change_password TINYINT(1) NOT NULL DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await migrateUsersTable(conn);
  await migrateTransactionsTable(conn);
  await migrateChequesTable(conn);

  const adminHash = await bcrypt.hash('password', 10);
  await conn.query(
    `INSERT INTO users (name, employee_id, password_hash, role, position, is_active, module_access)
     SELECT 'Administrator', 'admin', ?, 'admin', 'System Administrator', 1, ?
     WHERE NOT EXISTS (SELECT 1 FROM users WHERE employee_id = 'admin')`,
    [adminHash, JSON.stringify(['home', 'accounts', 'customers', 'transactions', 'cheques'])]
  );

  await conn.query(`
    CREATE TABLE IF NOT EXISTS accounts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        bank_name VARCHAR(255) NOT NULL,
        bank_key VARCHAR(100) DEFAULT '',
        account_name VARCHAR(255) DEFAULT '',
        account_number VARCHAR(100) DEFAULT '',
        balance DECIMAL(15,2) NOT NULL DEFAULT 0,
        is_visible TINYINT(1) DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await conn.query(`
    CREATE TABLE IF NOT EXISTS customers (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        name VARCHAR(255) NOT NULL,
        bank_name VARCHAR(255) DEFAULT '',
        bank_key VARCHAR(100) DEFAULT '',
        bank_account_number VARCHAR(100) DEFAULT '',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await conn.query(`
    CREATE TABLE IF NOT EXISTS transactions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        account_id INT NOT NULL,
        customer_id INT DEFAULT NULL,
        type VARCHAR(50) NOT NULL,
        method VARCHAR(30) NOT NULL DEFAULT 'cash',
        amount DECIMAL(15,2) NOT NULL,
        date DATE NOT NULL,
        payee VARCHAR(255) DEFAULT '',
        reference_no VARCHAR(100) DEFAULT '',
        description TEXT DEFAULT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await conn.query(`
    CREATE TABLE IF NOT EXISTS chequebooks (
        id INT AUTO_INCREMENT PRIMARY KEY,
        account_id INT NOT NULL,
        size INT NOT NULL,
        start_number VARCHAR(20) NOT NULL,
        end_number VARCHAR(20) NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await conn.query(`
    CREATE TABLE IF NOT EXISTS cheques (
        id INT AUTO_INCREMENT PRIMARY KEY,
        chequebook_id INT NOT NULL,
        transaction_id INT DEFAULT NULL,
        cheque_number VARCHAR(20) NOT NULL,
        date DATE NOT NULL,
        payee VARCHAR(255) DEFAULT '',
        amount DECIMAL(15,2) NOT NULL,
        amount_in_words TEXT NOT NULL,
        bearer_or_order VARCHAR(20) DEFAULT 'bearer',
        crossed TINYINT(1) DEFAULT 0,
        status VARCHAR(20) DEFAULT 'Issued',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (chequebook_id) REFERENCES chequebooks(id) ON DELETE CASCADE,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  await conn.query(`
    CREATE TABLE IF NOT EXISTS cheque_designs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        bank_key VARCHAR(100) NOT NULL,
        denomination VARCHAR(50) NOT NULL DEFAULT '',
        layout_json TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uq_cheque_design (bank_key, denomination)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  const designCount = await conn.query('SELECT COUNT(*) AS n FROM cheque_designs');
  if (designCount[0][0].n === 0) {
    const seeds = [
      ['cbe', '', JSON.stringify({
        logo: { position: 'center', size: 40 },
        colors: { primary: '#1A1D26', accent: '#2563EB', muted: '#9CA3AF', border: '#1A1D26' },
        header: { show_head_office: true },
        cheque_number: { position: 'below' },
        amount_box: { align: 'right' },
        micr: { show: false, text: '0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0' },
        status_pill: { show: true }
      })],
      ['dashen', '', JSON.stringify({
        logo: { position: 'left', size: 36 },
        colors: { primary: '#1A1D26', accent: '#2563EB', muted: '#9CA3AF', border: '#1A1D26' },
        header: { show_head_office: true },
        cheque_number: { position: 'right' },
        amount_box: { align: 'right' },
        micr: { show: false, text: '0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0' },
        status_pill: { show: true }
      })],
    ];
    for (const [bankKey, denom, layoutJson] of seeds) {
      await conn.query(
        'INSERT INTO cheque_designs (bank_key, denomination, layout_json) VALUES (?, ?, ?)',
        [bankKey, denom, layoutJson]
      );
    }
    console.log('  ↪ Seeded 2 placeholder cheque design templates (cbe, dashen)');
  }

  await conn.query(`
    CREATE TABLE IF NOT EXISTS audit_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT DEFAULT NULL,
        user_name VARCHAR(255) NOT NULL DEFAULT '',
        employee_id VARCHAR(50) NOT NULL DEFAULT '',
        action VARCHAR(30) NOT NULL,
        entity_type VARCHAR(30) NOT NULL DEFAULT '',
        entity_id INT DEFAULT NULL,
        details TEXT,
        ip_address VARCHAR(45) NOT NULL DEFAULT '',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_audit_created (created_at),
        INDEX idx_audit_action (action),
        -- Keep the trail even after an employee is deleted (user_id -> NULL,
        -- the name/employee_id snapshot survives).
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  `);

  console.log(' All tables ready');
  await conn.end();
}

async function migrateTransactionsTable(conn) {
  const [columns] = await conn.query('SHOW COLUMNS FROM transactions');
  const names = columns.map(c => c.Field);
  if (!names.includes('method')) {
    await conn.query("ALTER TABLE transactions ADD COLUMN method VARCHAR(30) NOT NULL DEFAULT 'cash' AFTER type");
    console.log('  ↪ Added transactions.method');
  }
}

async function migrateUsersTable(conn) {
  const [columns] = await conn.query('SHOW COLUMNS FROM users');
  const names = columns.map(c => c.Field);

  if (!names.includes('employee_id')) {
    if (names.includes('email')) {
      await conn.query('ALTER TABLE users CHANGE COLUMN email employee_id VARCHAR(50) NOT NULL');
      console.log('  ↪ Renamed users.email → users.employee_id');
    } else {
      await conn.query("ALTER TABLE users ADD COLUMN employee_id VARCHAR(50) NOT NULL DEFAULT '' AFTER name");
      console.log('  ↪ Added users.employee_id');
    }
  }

  const [indexes] = await conn.query('SHOW INDEX FROM users');
  const hasUniqueEmployeeId = indexes.some(
    i => i.Column_name === 'employee_id' && i.Non_unique === 0
  );
  if (!hasUniqueEmployeeId) {
    try {
      await conn.query('ALTER TABLE users ADD UNIQUE INDEX idx_users_employee_id (employee_id)');
      console.log('  ↪ Added unique index on users.employee_id');
    } catch (err) {
      console.warn('  ⚠ Could not add unique index on employee_id:', err.message);
    }
  }

  try {
    const [cols] = await conn.query('SHOW COLUMNS FROM users');
    const col = cols.find(c => c.Field === 'employee_id');
    if (col && col.Collation && col.Collation !== 'utf8mb4_bin') {
      await conn.query('ALTER TABLE users MODIFY employee_id VARCHAR(50) COLLATE utf8mb4_bin NOT NULL');
      console.log('  ↪ Made users.employee_id case-sensitive (utf8mb4_bin)');
    }
  } catch (err) {
    console.warn('  ⚠ Could not make employee_id case-sensitive:', err.message);
  }

  const additions = [
    ["role VARCHAR(20) NOT NULL DEFAULT 'employee' AFTER employee_id", 'role'],
    ["position VARCHAR(100) NOT NULL DEFAULT '' AFTER role", 'position'],
    ['is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER position', 'is_active'],
    ['module_access TEXT AFTER is_active', 'module_access'],
    ['must_change_password TINYINT(1) NOT NULL DEFAULT 0 AFTER module_access', 'must_change_password'],
  ];
  for (const [ddl, colName] of additions) {
    if (!names.includes(colName)) {
      await conn.query(`ALTER TABLE users ADD COLUMN ${ddl}`);
      console.log(`  ↪ Added users.${colName}`);
    }
  }
}

async function migrateChequesTable(conn) {
  const [columns] = await conn.query('SHOW COLUMNS FROM cheques');
  const names = columns.map(c => c.Field);
  if (!names.includes('deducted')) {
    await conn.query("ALTER TABLE cheques ADD COLUMN deducted TINYINT(1) NOT NULL DEFAULT 1 AFTER status");
    console.log('  ↪ Added cheques.deducted');
  }
}

if (require.main === module) {
  initDatabase().catch(err => {
    console.error('❌ Database initialization failed:', err);
    process.exit(1);
  });
}

module.exports = initDatabase;
