const { randomUUID } = require('crypto');

const pool = require('../config/database');
const AppError = require('../utils/AppError');
const { toGroup } = require('../models/group.model');

async function getMemberIds(groupId, connection = pool) {
  const [rows] = await connection.execute(
    'SELECT user_id FROM group_members WHERE group_id = :groupId ORDER BY joined_at ASC',
    { groupId }
  );

  return rows.map((row) => row.user_id);
}

async function hydrateGroup(row, connection = pool) {
  return toGroup(row, await getMemberIds(row.id, connection));
}

async function listGroups(userId) {
  const [rows] = await pool.execute(
    `SELECT g.*
     FROM groups g
     INNER JOIN group_members gm ON gm.group_id = g.id
     WHERE gm.user_id = :userId
     ORDER BY g.updated_at DESC`,
    { userId }
  );

  return Promise.all(rows.map((row) => hydrateGroup(row)));
}

async function getGroupById(groupId, userId = null) {
  const params = { groupId };
  let sql = 'SELECT g.* FROM groups g WHERE g.id = :groupId';

  if (userId) {
    sql = `
      SELECT g.*
      FROM groups g
      INNER JOIN group_members gm ON gm.group_id = g.id
      WHERE g.id = :groupId AND gm.user_id = :userId
    `;
    params.userId = userId;
  }

  const [rows] = await pool.execute(sql, params);
  return rows[0] ? hydrateGroup(rows[0]) : null;
}

async function createGroup(userId, payload) {
  const name = String(payload.name || '').trim();
  const description = String(payload.description || '').trim();

  if (!name) {
    throw new AppError('Group name is required', 400);
  }

  const id = randomUUID();
  const requestedMembers = Array.isArray(payload.memberIds) ? payload.memberIds : [];
  const memberIds = [...new Set([userId, ...requestedMembers.filter(Boolean)])];

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    await connection.execute(
      `INSERT INTO groups (id, name, description, creator_id)
       VALUES (:id, :name, :description, :creatorId)`,
      { id, name, description, creatorId: userId }
    );

    for (const memberId of memberIds) {
      await connection.execute(
        'INSERT IGNORE INTO group_members (group_id, user_id) VALUES (:groupId, :userId)',
        { groupId: id, userId: memberId }
      );
    }

    await connection.commit();
  } catch (err) {
    await connection.rollback();
    throw err;
  } finally {
    connection.release();
  }

  return getGroupById(id, userId);
}

async function updateGroup(groupId, userId, payload) {
  const group = await getGroupById(groupId, userId);
  if (!group) {
    throw new AppError('Group not found', 404);
  }
  if (group.creatorId !== userId) {
    throw new AppError('Only group creator can update this group', 403);
  }

  const name = String(payload.name || '').trim();
  const description = String(payload.description || '').trim();

  if (!name) {
    throw new AppError('Group name is required', 400);
  }

  await pool.execute(
    `UPDATE groups
     SET name = :name, description = :description, updated_at = CURRENT_TIMESTAMP
     WHERE id = :groupId`,
    { name, description, groupId }
  );

  return getGroupById(groupId, userId);
}

async function deleteGroup(groupId, userId) {
  const group = await getGroupById(groupId, userId);
  if (!group) {
    throw new AppError('Group not found', 404);
  }
  if (group.creatorId !== userId) {
    throw new AppError('Only group creator can delete this group', 403);
  }

  await pool.execute('DELETE FROM groups WHERE id = :groupId', { groupId });
  return true;
}

async function addMemberByEmail(groupId, requesterId, email) {
  const normalizedEmail = String(email || '').trim().toLowerCase();
  if (!normalizedEmail) {
    throw new AppError('Email is required', 400);
  }

  const group = await getGroupById(groupId, requesterId);
  if (!group) {
    throw new AppError('Group not found', 404);
  }
  if (group.creatorId !== requesterId) {
    throw new AppError('Only group creator can add members', 403);
  }

  const [users] = await pool.execute(
    'SELECT id FROM users WHERE email = :email LIMIT 1',
    { email: normalizedEmail }
  );

  if (!users[0]) {
    throw new AppError('User not found with this email', 404);
  }

  return addMember(groupId, requesterId, users[0].id);
}

async function addMember(groupId, requesterId, memberId) {
  const group = await getGroupById(groupId, requesterId);
  if (!group) {
    throw new AppError('Group not found', 404);
  }
  if (group.creatorId !== requesterId) {
    throw new AppError('Only group creator can add members', 403);
  }

  const [users] = await pool.execute(
    'SELECT id FROM users WHERE id = :memberId LIMIT 1',
    { memberId }
  );
  if (!users[0]) {
    throw new AppError('User not found', 404);
  }

  await pool.execute(
    'INSERT IGNORE INTO group_members (group_id, user_id) VALUES (:groupId, :memberId)',
    { groupId, memberId }
  );
  await pool.execute(
    'UPDATE groups SET updated_at = CURRENT_TIMESTAMP WHERE id = :groupId',
    { groupId }
  );

  return getGroupById(groupId, requesterId);
}

async function removeMember(groupId, requesterId, memberId) {
  const group = await getGroupById(groupId, requesterId);
  if (!group) {
    throw new AppError('Group not found', 404);
  }
  if (group.creatorId !== requesterId) {
    throw new AppError('Only group creator can remove members', 403);
  }
  if (group.creatorId === memberId) {
    throw new AppError('Cannot remove group creator', 400);
  }

  await pool.execute(
    'DELETE FROM group_members WHERE group_id = :groupId AND user_id = :memberId',
    { groupId, memberId }
  );
  await pool.execute(
    'UPDATE groups SET updated_at = CURRENT_TIMESTAMP WHERE id = :groupId',
    { groupId }
  );

  return getGroupById(groupId, requesterId);
}

module.exports = {
  listGroups,
  getGroupById,
  createGroup,
  updateGroup,
  deleteGroup,
  addMemberByEmail,
  addMember,
  removeMember,
};
