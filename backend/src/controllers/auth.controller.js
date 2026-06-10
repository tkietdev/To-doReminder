const authService = require('../services/auth.service');
const { success } = require('../utils/apiResponse');

async function register(req, res, next) {
  try {
    const data = await authService.register(req.body);
    return success(res, data, 'Register successfully', 201);
  } catch (err) {
    return next(err);
  }
}

async function login(req, res, next) {
  try {
    const data = await authService.login(req.body);
    return success(res, data, 'Login successfully');
  } catch (err) {
    return next(err);
  }
}

async function me(req, res, next) {
  try {
    const user = await authService.getUserById(req.user.id);
    return success(res, { user }, 'Get current user successfully');
  } catch (err) {
    return next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const user = await authService.updateProfile(req.user.id, req.body);
    return success(res, { user }, 'Update profile successfully');
  } catch (err) {
    return next(err);
  }
}

async function changePassword(req, res, next) {
  try {
    await authService.changePassword(req.user.id, req.body);
    return success(res, null, 'Change password successfully');
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  register,
  login,
  me,
  updateProfile,
  changePassword,
};
