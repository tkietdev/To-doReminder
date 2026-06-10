const AppError = require('../utils/AppError');

function requireFields(fields) {
  return (req, res, next) => {
    const missing = fields.filter((field) => {
      const value = req.body[field];
      return value === undefined || value === null || String(value).trim() === '';
    });

    if (missing.length > 0) {
      return next(new AppError('Missing required fields', 400, { missing }));
    }

    return next();
  };
}

module.exports = { requireFields };
