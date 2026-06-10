const groupService = require('../services/group.service');
const { success } = require('../utils/apiResponse');
const AppError = require('../utils/AppError');

async function listGroups(req, res, next) {
  try {
    const groups = await groupService.listGroups(req.user.id);
    return success(res, { groups }, 'Get groups successfully');
  } catch (err) {
    return next(err);
  }
}

async function getGroup(req, res, next) {
  try {
    const group = await groupService.getGroupById(req.params.id, req.user.id);
    if (!group) throw new AppError('Group not found', 404);
    return success(res, { group }, 'Get group successfully');
  } catch (err) {
    return next(err);
  }
}

async function createGroup(req, res, next) {
  try {
    const group = await groupService.createGroup(req.user.id, req.body);
    return success(res, { group }, 'Create group successfully', 201);
  } catch (err) {
    return next(err);
  }
}

async function updateGroup(req, res, next) {
  try {
    const group = await groupService.updateGroup(req.params.id, req.user.id, req.body);
    return success(res, { group }, 'Update group successfully');
  } catch (err) {
    return next(err);
  }
}

async function deleteGroup(req, res, next) {
  try {
    await groupService.deleteGroup(req.params.id, req.user.id);
    return success(res, null, 'Delete group successfully');
  } catch (err) {
    return next(err);
  }
}

async function addMemberByEmail(req, res, next) {
  try {
    const group = await groupService.addMemberByEmail(
      req.params.id,
      req.user.id,
      req.body.email
    );
    return success(res, { group }, 'Add member successfully');
  } catch (err) {
    return next(err);
  }
}

async function addMember(req, res, next) {
  try {
    const group = await groupService.addMember(req.params.id, req.user.id, req.body.userId);
    return success(res, { group }, 'Add member successfully');
  } catch (err) {
    return next(err);
  }
}

async function removeMember(req, res, next) {
  try {
    const group = await groupService.removeMember(req.params.id, req.user.id, req.params.userId);
    return success(res, { group }, 'Remove member successfully');
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listGroups,
  getGroup,
  createGroup,
  updateGroup,
  deleteGroup,
  addMemberByEmail,
  addMember,
  removeMember,
};
