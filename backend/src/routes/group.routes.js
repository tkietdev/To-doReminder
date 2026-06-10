const express = require('express');

const groupController = require('../controllers/group.controller');
const authenticate = require('../middleware/auth.middleware');
const { requireFields } = require('../middleware/validate.middleware');

const router = express.Router();

router.use(authenticate);

router.get('/', groupController.listGroups);
router.post('/', requireFields(['name']), groupController.createGroup);
router.get('/:id', groupController.getGroup);
router.put('/:id', requireFields(['name']), groupController.updateGroup);
router.delete('/:id', groupController.deleteGroup);
router.post('/:id/members/email', requireFields(['email']), groupController.addMemberByEmail);
router.post('/:id/members', requireFields(['userId']), groupController.addMember);
router.delete('/:id/members/:userId', groupController.removeMember);

module.exports = router;
