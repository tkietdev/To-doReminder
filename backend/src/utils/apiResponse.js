function success(res, data = null, message = 'OK', statusCode = 200) {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
    error: null,
  });
}

function error(res, message = 'Error', statusCode = 500, details = null) {
  return res.status(statusCode).json({
    success: false,
    message,
    data: null,
    error: details,
  });
}

module.exports = { success, error };
