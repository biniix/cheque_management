-- ============================================================
-- Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS `cheque_management_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `cheque_management_db`;

-- -----------------------------------------------------------
-- Users table
-- -----------------------------------------------------------
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- NOTE: The default admin account (employee_id: admin / password: password)
-- is seeded by src/utils/initDb.js at startup using a runtime bcrypt hash.
-- must_change_password=1 means the user must pick their own password at next
-- login (used for employees whose password was set/reset by the admin).

-- -----------------------------------------------------------
-- Accounts table
-- -----------------------------------------------------------
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- Customers table
-- -----------------------------------------------------------
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- Transactions table
-- -----------------------------------------------------------
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- Chequebooks table
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS chequebooks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    size INT NOT NULL,
    start_number VARCHAR(20) NOT NULL,
    end_number VARCHAR(20) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- Cheques table
-- -----------------------------------------------------------
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- Audit log table (activity log)
-- -----------------------------------------------------------
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
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------
-- Cheque design templates
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS cheque_designs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bank_key VARCHAR(100) NOT NULL,
    denomination VARCHAR(50) NOT NULL DEFAULT '',
    layout_json TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_cheque_design (bank_key, denomination)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
