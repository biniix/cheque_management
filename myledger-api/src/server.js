require('dotenv').config();
const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');

async function startServer() {
  // Initialize database tables before starting
  try {
    const initDatabase = require('./utils/initDb');
    await initDatabase();
    console.log('✅ Database initialized');
  } catch (err) {
    console.error('❌ Database initialization failed:', err);
    process.exit(1);
  }

  const app = express();
  const PORT = process.env.PORT || 3000;

  app.use(cors());
  app.use(express.json());

  const swaggerOptions = {
    definition: {
      openapi: '3.0.0',
      info: {
        title: 'My Ledger API',
        version: '1.0.0',
        description: 'Money Management API for My Ledger Flutter Web App'
      },
      servers: [{ url: `http://localhost:${PORT}/api` }],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT'
          }
        },
        schemas: {
          ChequeBook: {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              account_id: { type: 'integer' },
              size: { type: 'integer' },
              start_number: { type: 'string' },
              end_number: { type: 'string' },
              bank_name: { type: 'string' },
              account_name: { type: 'string' },
              used: { type: 'integer' },
              remaining: { type: 'integer' }
            }
          },
          Cheque: {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              chequebook_id: { type: 'integer' },
              cheque_number: { type: 'string' },
              date: { type: 'string', format: 'date' },
              payee: { type: 'string' },
              amount: { type: 'number' },
              amount_in_words: { type: 'string' },
              bearer_or_order: { type: 'string', enum: ['bearer', 'order'] },
              crossed: { type: 'boolean' },
              status: { type: 'string', enum: ['Issued', 'Encashed', 'Void'] }
            }
          }
        }
      }
    },
    apis: ['./src/routes/*.js']
  };

  const specs = swaggerJsdoc(swaggerOptions);
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

  app.use('/api/auth', require('./routes/auth'));
  app.use('/api/accounts', require('./routes/accounts'));
  app.use('/api/customers', require('./routes/customers'));
  app.use('/api/transfers', require('./routes/transfers'));
  app.use('/api/cheques', require('./routes/cheques'));
  app.use('/api/dashboard', require('./routes/dashboard'));
  app.use('/api/receipts', require('./routes/receipts'));
  app.use('/api/transactions', require('./routes/transactions'));

  app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
  });

  app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ success: false, message: 'Internal server error' });
  });

  app.listen(PORT, () => {
    console.log(`✅ My Ledger API running on http://localhost:${PORT}`);
    console.log(`📚 Swagger UI: http://localhost:${PORT}/api-docs`);
  });
}

startServer();
