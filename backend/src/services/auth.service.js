const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { randomUUID } = require('crypto');

const pool = require('../config/database');
const env = require('../config/env');
const AppError = require('../utils/AppError');
const { toUser } = require('../models/user.model');

function signToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, name: user.name },
    env.jwt.secret,
    { expiresIn: env.jwt.expiresIn }
  );
}

async function register({ email, password, name }) {
  const normalizedEmail = String(email).trim().toLowerCase();
  const displayName = String(name).trim();

  if (String(password).length < 6) {
    throw new AppError('Password must be at least 6 characters', 400);
  }

  const [existing] = await pool.execute(
    'SELECT id FROM users WHERE email = :email LIMIT 1',
    { email: normalizedEmail }
  );

  if (existing.length > 0) {
    throw new AppError('Email already exists', 409);
  }

  const id = randomUUID();
  const passwordHash = await bcrypt.hash(password, 10);

  await pool.execute(
    `INSERT INTO users (id, email, name, password_hash)
     VALUES (:id, :email, :name, :passwordHash)`,
    { id, email: normalizedEmail, name: displayName, passwordHash }
  );

  const user = await getUserById(id);
  return { user, token: signToken(user) };
}

async function login({ email, password }) {
  const normalizedEmail = String(email).trim().toLowerCase();
  const [rows] = await pool.execute(
    'SELECT * FROM users WHERE email = :email LIMIT 1',
    { email: normalizedEmail }
  );

  const userRow = rows[0];
  if (!userRow) {
    throw new AppError('Invalid email or password', 401);
  }

  const isValid = await bcrypt.compare(password, userRow.password_hash);
  if (!isValid) {
    throw new AppError('Invalid email or password', 401);
  }

  const user = toUser(userRow);
  return { user, token: signToken(user) };
}

async function getUserById(id) {
  const [rows] = await pool.execute(
    'SELECT id, email, name, created_at FROM users WHERE id = :id LIMIT 1',
    { id }
  );

  return toUser(rows[0]);
}

async function updateProfile(userId, { name }) {
  const displayName = String(name || '').trim();
  if (!displayName) {
    throw new AppError('Name is required', 400);
  }

  await pool.execute(
    'UPDATE users SET name = :name WHERE id = :userId',
    { name: displayName, userId }
  );

  return getUserById(userId);
}

async function changePassword(userId, { currentPassword, newPassword }) {
  if (String(newPassword || '').length < 6) {
    throw new AppError('New password must be at least 6 characters', 400);
  }

  const [rows] = await pool.execute(
    'SELECT password_hash FROM users WHERE id = :userId LIMIT 1',
    { userId }
  );

  if (!rows[0]) {
    throw new AppError('User not found', 404);
  }

  const isValid = await bcrypt.compare(currentPassword || '', rows[0].password_hash);
  if (!isValid) {
    throw new AppError('Current password is incorrect', 401);
  }

  const passwordHash = await bcrypt.hash(newPassword, 10);
  await pool.execute(
    'UPDATE users SET password_hash = :passwordHash WHERE id = :userId',
    { passwordHash, userId }
  );

  return true;
}

module.exports = {
  register,
  login,
  getUserById,
  updateProfile,
  changePassword,
};
