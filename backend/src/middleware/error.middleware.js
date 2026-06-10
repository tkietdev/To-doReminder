const { error } = require('../utils/apiResponse');

function notFound(req, res) {
  return error(res, `Route not found: ${req.method} ${req.originalUrl}`, 404);
}

function errorHandler(err, req, res, next) {
  const statusCode = err.statusCode || 500;
  const details = process.env.NODE_ENV === 'production' ? null : err.details || err.message;

  return error(res, err.message || 'Internal server error', statusCode, details);
}

module.exports = { notFound, errorHandler };
