function toTask(row, memberIds = []) {
  if (!row) return null;

  return {
    id: row.id,
    title: row.title,
    description: row.description || '',
    deadline: new Date(row.deadline).toISOString(),
    priority: row.priority,
    isCompleted: Boolean(row.is_completed),
    userId: row.user_id,
    groupId: row.group_id,
    memberIds,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

module.exports = { toTask };
