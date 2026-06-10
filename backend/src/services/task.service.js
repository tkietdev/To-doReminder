const { randomUUID } = require('crypto');

const pool = require('../config/database');
const AppError = require('../utils/AppError');
const { toTask } = require('../models/task.model');

const allowedPriorities = new Set(['low', 'medium', 'high', 'urgent']);

async function getTaskMemberIds(taskId, connection = pool) {
  const [rows] = await connection.execute(
    'SELECT user_id FROM task_members WHERE task_id = :taskId ORDER BY user_id ASC',
    { taskId }
  );

  return rows.map((row) => row.user_id);
}

async function hydrateTask(row, connection = pool) {
  return toTask(row, await getTaskMemberIds(row.id, connection));
}

async function listTasks(userId, filters = {}) {
  const params = { userId };
  const where = [
    `(t.user_id = :userId OR EXISTS (
      SELECT 1 FROM task_members tm WHERE tm.task_id = t.id AND tm.user_id = :userId
    ))`,
  ];

  if (filters.groupId) {
    where.push('t.group_id = :groupId');
    params.groupId = filters.groupId;
  }

  if (filters.priority && allowedPriorities.has(filters.priority)) {
    where.push('t.priority = :priority');
    params.priority = filters.priority;
  }

  if (filters.isCompleted !== undefined) {
    where.push('t.is_completed = :isCompleted');
    params.isCompleted = String(filters.isCompleted) === 'true' ? 1 : 0;
  }

  if (filters.search) {
    where.push('(t.title LIKE :search OR t.description LIKE :search)');
    params.search = `%${filters.search}%`;
  }

  const [rows] = await pool.execute(
    `SELECT DISTINCT t.*
     FROM tasks t
     WHERE ${where.join(' AND ')}
     ORDER BY t.is_completed ASC, t.deadline ASC`,
    params
  );

  return Promise.all(rows.map((row) => hydrateTask(row)));
}

async function getTaskById(taskId, userId) {
  const [rows] = await pool.execute(
    `SELECT t.*
     FROM tasks t
     WHERE t.id = :taskId
       AND (t.user_id = :userId OR EXISTS (
         SELECT 1 FROM task_members tm WHERE tm.task_id = t.id AND tm.user_id = :userId
       ))
     LIMIT 1`,
    { taskId, userId }
  );

  return rows[0] ? hydrateTask(rows[0]) : null;
}

async function getGroupMemberIds(groupId, userId) {
  const [rows] = await pool.execute(
    `SELECT gm.user_id
     FROM group_members gm
     WHERE gm.group_id = :groupId
       AND EXISTS (
         SELECT 1 FROM group_members mine
         WHERE mine.group_id = gm.group_id AND mine.user_id = :userId
       )
     ORDER BY gm.joined_at ASC`,
    { groupId, userId }
  );

  return rows.map((row) => row.user_id);
}

function normalizeTaskPayload(payload, requireAll = true) {
  const title = payload.title === undefined ? undefined : String(payload.title).trim();
  const description =
    payload.description === undefined ? '' : String(payload.description || '').trim();
  const priority = payload.priority || 'medium';
  const deadline = payload.deadline ? new Date(payload.deadline) : null;
  const isCompleted =
    payload.isCompleted === undefined ? false : Boolean(payload.isCompleted);

  if (requireAll && !title) {
    throw new AppError('Task title is required', 400);
  }
  if (title !== undefined && !title) {
    throw new AppError('Task title is required', 400);
  }
  if (!allowedPriorities.has(priority)) {
    throw new AppError('Invalid task priority', 400);
  }
  if (requireAll && (!deadline || Number.isNaN(deadline.getTime()))) {
    throw new AppError('Valid deadline is required', 400);
  }
  if (deadline && Number.isNaN(deadline.getTime())) {
    throw new AppError('Valid deadline is required', 400);
  }

  return { title, description, deadline, priority, isCompleted };
}

async function createTask(userId, payload) {
  const task = normalizeTaskPayload(payload);
  const groupId = payload.groupId || null;
  let memberIds = [];

  if (groupId) {
    memberIds = await getGroupMemberIds(groupId, userId);
    if (!memberIds.includes(userId)) {
      throw new AppError('Group not found or user is not a member', 404);
    }
  }

  const id = randomUUID();
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    await connection.execute(
      `INSERT INTO tasks
       (id, title, description, deadline, priority, is_completed, user_id, group_id)
       VALUES
       (:id, :title, :description, :deadline, :priority, :isCompleted, :userId, :groupId)`,
      {
        id,
        title: task.title,
        description: task.description,
        deadline: task.deadline,
        priority: task.priority,
        isCompleted: task.isCompleted ? 1 : 0,
        userId,
        groupId,
      }
    );

    for (const memberId of memberIds) {
      await connection.execute(
        'INSERT IGNORE INTO task_members (task_id, user_id) VALUES (:taskId, :userId)',
        { taskId: id, userId: memberId }
      );
    }

    await connection.commit();
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }

  return getTaskById(id, userId);
}

async function updateTask(taskId, userId, payload) {
  const existing = await getTaskById(taskId, userId);
  if (!existing) {
    throw new AppError('Task not found', 404);
  }

  const next = normalizeTaskPayload(payload, false);
  const updates = [];
  const params = { taskId };

  if (next.title !== undefined) {
    updates.push('title = :title');
    params.title = next.title;
  }
  if (payload.description !== undefined) {
    updates.push('description = :description');
    params.description = next.description;
  }
  if (next.deadline) {
    updates.push('deadline = :deadline');
    params.deadline = next.deadline;
  }
  if (payload.priority !== undefined) {
    updates.push('priority = :priority');
    params.priority = next.priority;
  }
  if (payload.isCompleted !== undefined) {
    updates.push('is_completed = :isCompleted');
    params.isCompleted = next.isCompleted ? 1 : 0;
  }

  if (updates.length === 0) {
    return existing;
  }

  updates.push('updated_at = CURRENT_TIMESTAMP');

  await pool.execute(
    `UPDATE tasks SET ${updates.join(', ')} WHERE id = :taskId`,
    params
  );

  return getTaskById(taskId, userId);
}

async function toggleTaskCompletion(taskId, userId) {
  const existing = await getTaskById(taskId, userId);
  if (!existing) {
    throw new AppError('Task not found', 404);
  }

  await pool.execute(
    `UPDATE tasks
     SET is_completed = NOT is_completed, updated_at = CURRENT_TIMESTAMP
     WHERE id = :taskId`,
    { taskId }
  );

  return getTaskById(taskId, userId);
}

async function deleteTask(taskId, userId) {
  const existing = await getTaskById(taskId, userId);
  if (!existing) {
    throw new AppError('Task not found', 404);
  }
  if (existing.userId !== userId) {
    throw new AppError('Only task owner can delete this task', 403);
  }

  await pool.execute('DELETE FROM tasks WHERE id = :taskId', { taskId });
  return true;
}

module.exports = {
  listTasks,
  getTaskById,
  createTask,
  updateTask,
  toggleTaskCompletion,
  deleteTask,
};
