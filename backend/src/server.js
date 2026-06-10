const app = require('./app');
const pool = require('./config/database');
const env = require('./config/env');
const initializeDatabase = require('./config/initDatabase');

async function start() {
  await initializeDatabase();
  await pool.query('SELECT 1');

  app.listen(env.port, () => {
    console.log(`TaskMate API listening on http://localhost:${env.port}`);
  });
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
