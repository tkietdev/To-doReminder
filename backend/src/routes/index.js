const express = require('express');

const authRoutes = require('./auth.routes');
const groupRoutes = require('./group.routes');
const taskRoutes = require('./task.routes');

const router = express.Router();

router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'TaskMate API is running',
    data: { status: 'ok' },
    error: null,
  });
});

router.use('/auth', authRoutes);
router.use('/groups', groupRoutes);
router.use('/tasks', taskRoutes);

module.exports = router;
