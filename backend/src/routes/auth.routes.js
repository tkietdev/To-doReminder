const express = require('express');

const authController = require('../controllers/auth.controller');
const authenticate = require('../middleware/auth.middleware');
const { requireFields } = require('../middleware/validate.middleware');

const router = express.Router();

router.post('/register', requireFields(['email', 'password', 'name']), authController.register);
router.post('/login', requireFields(['email', 'password']), authController.login);
router.get('/me', authenticate, authController.me);
router.patch('/profile', authenticate, requireFields(['name']), authController.updateProfile);
router.patch(
  '/password',
  authenticate,
  requireFields(['currentPassword', 'newPassword']),
  authController.changePassword
);

module.exports = router;
