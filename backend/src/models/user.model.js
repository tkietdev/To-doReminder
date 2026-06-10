function toUser(row) {
  if (!row) return null;

  return {
    id: row.id,
    email: row.email,
    name: row.name,
    createdAt: new Date(row.created_at).toISOString(),
  };
}

module.exports = { toUser };
