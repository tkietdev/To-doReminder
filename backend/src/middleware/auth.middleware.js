const jwt = require('jsonwebtoken');
const env = require('../config/env');
const AppError = require('../utils/AppError');

function authenticate(req, res, next) {
  const header = req.headers.authorization || '';
  const [type, token] = header.split(' ');

  if (type !== 'Bearer' || !token) {
    return next(new AppError('Missing authorization token', 401));
  }

  try {
    req.user = jwt.verify(token, env.jwt.secret);
    return next();
  } catch (err) {
    return next(new AppError('Invalid or expired token', 401));
  }
}

module.exports = authenticate;
