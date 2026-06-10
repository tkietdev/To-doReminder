const fs = require('fs/promises');
const path = require('path');
const mysql = require('mysql2/promise');
const env = require('./env');

const schemaPath = path.resolve(__dirname, '../../database/schema.sql');

function escapeId(identifier) {
  return `\`${String(identifier).replace(/`/g, '``')}\``;
}

function splitSqlStatements(sql) {
  return sql
    .split(';')
    .map((statement) => statement.trim())
    .filter(Boolean);
}

function shouldSkipStatement(statement) {
  return /^CREATE\s+DATABASE\b/i.test(statement) || /^USE\b/i.test(statement);
}

function isDuplicateIndexError(error) {
  return error && (error.code === 'ER_DUP_KEYNAME' || error.errno === 1061);
}

async function initializeDatabase() {
  const connection = await mysql.createConnection({
    host: env.db.host,
    port: env.db.port,
    user: env.db.user,
    password: env.db.password,
    multipleStatements: false,
  });

  try {
    await connection.query(
      `CREATE DATABASE IF NOT EXISTS ${escapeId(env.db.name)} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
    );
    await connection.query(`USE ${escapeId(env.db.name)}`);

    const schemaSql = await fs.readFile(schemaPath, 'utf8');
    const statements = splitSqlStatements(schemaSql).filter(
      (statement) => !shouldSkipStatement(statement)
    );

    for (const statement of statements) {
      try {
        await connection.query(statement);
      } catch (error) {
        if (!isDuplicateIndexError(error)) {
          throw error;
        }
      }
    }
  } finally {
    await connection.end();
  }
}

module.exports = initializeDatabase;
