const taskService = require('../services/task.service');
const { success } = require('../utils/apiResponse');
const AppError = require('../utils/AppError');

async function listTasks(req, res, next) {
  try {
    const tasks = await taskService.listTasks(req.user.id, req.query);
    return success(res, { tasks }, 'Get tasks successfully');
  } catch (err) {
    return next(err);
  }
}

async function getTask(req, res, next) {
  try {
    const task = await taskService.getTaskById(req.params.id, req.user.id);
    if (!task) throw new AppError('Task not found', 404);
    return success(res, { task }, 'Get task successfully');
  } catch (err) {
    return next(err);
  }
}

async function createTask(req, res, next) {
  try {
    const task = await taskService.createTask(req.user.id, req.body);
    return success(res, { task }, 'Create task successfully', 201);
  } catch (err) {
    return next(err);
  }
}

async function updateTask(req, res, next) {
  try {
    const task = await taskService.updateTask(req.params.id, req.user.id, req.body);
    return success(res, { task }, 'Update task successfully');
  } catch (err) {
    return next(err);
  }
}

async function toggleTaskCompletion(req, res, next) {
  try {
    const task = await taskService.toggleTaskCompletion(req.params.id, req.user.id);
    return success(res, { task }, 'Toggle task completion successfully');
  } catch (err) {
    return next(err);
  }
}

async function deleteTask(req, res, next) {
  try {
    await taskService.deleteTask(req.params.id, req.user.id);
    return success(res, null, 'Delete task successfully');
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listTasks,
  getTask,
  createTask,
  updateTask,
  toggleTaskCompletion,
  deleteTask,
};
