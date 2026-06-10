function toGroup(row, memberIds = []) {
  if (!row) return null;

  return {
    id: row.id,
    name: row.name,
    description: row.description || '',
    creatorId: row.creator_id,
    memberIds,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

module.exports = { toGroup };
