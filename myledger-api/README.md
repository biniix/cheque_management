# MyLedger API

Backend API for MyLedger - Multi-Bank Personal Ledger & Cheque Management System.

## Quick Start

```bash
# 1. Install dependencies
npm install

# 2. Initialize database
npm run init-db

# 3. Start server
npm run dev
```

Server runs on `http://localhost:3000`

Swagger UI: `http://localhost:3000/api-docs`

## API Endpoints

| Module | Base Path |
|--------|-----------|
| Auth | `/api/auth` |
| Accounts | `/api/accounts` |
| Customers | `/api/customers` |
| Transfers | `/api/transfers` |
| Cheques | `/api/cheques` |
| Dashboard | `/api/dashboard` |
| Receipts | `/api/receipts` |

## Auth

All endpoints (except login/register) require JWT token in header:
```
Authorization: Bearer <your_token>
```

## Tech Stack
- Node.js + Express
- SQLite (sqlite3)
- JWT Authentication
- Swagger/OpenAPI 3.0
