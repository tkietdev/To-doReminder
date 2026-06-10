const express = require('express');

const taskController = require('../controllers/task.controller');
const authenticate = require('../middleware/auth.middleware');
const { requireFields } = require('../middleware/validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', taskController.listTasks);
router.post('/', requireFields(['title', 'deadline']), taskController.createTask);
router.get('/:id', taskController.getTask);
router.put('/:id', taskController.updateTask);
router.patch('/:id/toggle', taskController.toggleTaskCompletion);
router.delete('/:id', taskController.deleteTask);

module.exports = router;
