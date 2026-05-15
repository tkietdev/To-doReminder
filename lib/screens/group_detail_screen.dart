import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_model.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/task_provider.dart';
import 'add_edit_task_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().currentUser?.id ?? '';
    final isCreator = group.isCreator(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          if (isCreator)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'add_member') {
                  _showAddMemberDialog(context);
                }

                if (value == 'delete') {
                  _showDeleteDialog(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'add_member',
                  child: Row(
                    children: [
                      Icon(Icons.person_add),
                      SizedBox(width: 8),
                      Text('Thêm thành viên'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa nhóm', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = context.read<AuthProvider>().currentUser?.id;

          if (userId != null) {
            await context.read<GroupProvider>().loadGroups(userId);
            await context.read<TaskProvider>().loadTasks(userId);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(context, isCreator),
            const SizedBox(height: 16),
            _buildMembers(context, isCreator),
            const SizedBox(height: 16),
            _buildGroupTasks(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditTaskScreen(initialGroupId: group.id),
            ),
          );
        },
        icon: const Icon(Icons.add_task),
        label: const Text('Thêm task'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCreator) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              group.description.isEmpty ? 'Chưa có mô tả' : group.description,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people, size: 18),
                const SizedBox(width: 6),
                Text('${group.memberIds.length} thành viên'),
                if (isCreator) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.star, size: 18, color: Colors.orange),
                  const SizedBox(width: 4),
                  const Text('Chủ nhóm'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembers(BuildContext context, bool isCreator) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách thành viên',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...group.memberIds.map((userId) {
              final isOwner = userId == group.creatorId;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(userId.substring(0, 1).toUpperCase()),
                ),
                title: Text(userId),
                subtitle: Text(isOwner ? 'Chủ nhóm' : 'Thành viên'),
                trailing: isCreator && !isOwner
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        onPressed: () {
                          _removeMember(context, userId);
                        },
                      )
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTasks(BuildContext context) {
    final tasks = context.watch<TaskProvider>().getTasksByGroupId(group.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Công việc nhóm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              Text(
                'Chưa có công việc nhóm',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...tasks.map((task) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task.isCompleted ? Colors.green : Colors.grey,
                  ),
                  title: Text(task.title),
                  subtitle: Text(task.description),
                  trailing: Text('${task.deadline.day}/${task.deadline.month}'),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thêm thành viên'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email thành viên',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final error = await context
                    .read<GroupProvider>()
                    .addMemberByEmail(
                      groupId: group.id,
                      email: emailController.text.trim(),
                    );

                if (!context.mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Thêm thành viên thành công'),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  void _removeMember(BuildContext context, String userId) async {
    final error = await context.read<GroupProvider>().removeMember(
      groupId: group.id,
      userId: userId,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Đã xóa thành viên'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa nhóm'),
          content: Text('Bạn có chắc muốn xóa nhóm "${group.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                final error = await context.read<GroupProvider>().deleteGroup(
                  group.id,
                );

                if (!context.mounted) return;

                Navigator.pop(dialogContext);

                if (error == null) {
                  Navigator.pop(context);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Xóa nhóm thành công'),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
