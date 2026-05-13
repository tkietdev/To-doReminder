import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_model.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/task_provider.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhóm của tôi'), centerTitle: true),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, _) {
          if (groupProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = groupProvider.groups;

          if (groups.isEmpty) {
            return _buildEmptyView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              final userId = context.read<AuthProvider>().currentUser?.id;

              if (userId != null) {
                await groupProvider.loadGroups(userId);
                if (context.mounted) {
                  await context.read<TaskProvider>().loadTasks(userId);
                }
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];

                return _GroupCard(
                  group: group,
                  onTap: () => _showGroupDetail(context, group),
                  onEdit: () => _showEditGroupDialog(context, group),
                  onDelete: () => _showDeleteConfirmation(context, group),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGroupDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 90, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Chưa có nhóm nào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút + để tạo nhóm mới',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tạo nhóm mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhóm',
                    hintText: 'Nhập tên nhóm',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Nhập mô tả nhóm',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description = descController.text.trim();

                if (name.isEmpty) {
                  _showSnackBar(context, 'Vui lòng nhập tên nhóm', Colors.red);
                  return;
                }

                final user = context.read<AuthProvider>().currentUser;

                if (user == null) {
                  _showSnackBar(context, 'Bạn cần đăng nhập', Colors.red);
                  return;
                }

                final now = DateTime.now();

                final group = Group(
                  id: '',
                  name: name,
                  description: description,
                  creatorId: user.id,
                  memberIds: [user.id],
                  createdAt: now,
                  updatedAt: now,
                );

                final error = await context.read<GroupProvider>().addGroup(
                  group,
                );

                if (!context.mounted) return;

                Navigator.pop(dialogContext);

                _showSnackBar(
                  context,
                  error == null ? 'Tạo nhóm thành công' : error,
                  error == null ? Colors.green : Colors.red,
                );
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }

  void _showAddMemberDialog(BuildContext context, Group group) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thêm thành viên'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email thành viên',
              hintText: 'Nhập email người dùng',
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
                final email = emailController.text.trim();

                if (email.isEmpty) {
                  _showSnackBar(context, 'Vui lòng nhập email', Colors.red);
                  return;
                }

                final error = await context
                    .read<GroupProvider>()
                    .addMemberByEmail(groupId: group.id, email: email);

                if (!context.mounted) return;

                Navigator.pop(dialogContext);

                _showSnackBar(
                  context,
                  error == null ? 'Thêm thành viên thành công' : error,
                  error == null ? Colors.green : Colors.red,
                );
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  void _showEditGroupDialog(BuildContext context, Group group) {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sửa nhóm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhóm',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description = descController.text.trim();

                if (name.isEmpty) {
                  _showSnackBar(
                    context,
                    'Tên nhóm không được để trống',
                    Colors.red,
                  );
                  return;
                }

                final updatedGroup = group.copyWith(
                  name: name,
                  description: description,
                  updatedAt: DateTime.now(),
                );

                final error = await context.read<GroupProvider>().updateGroup(
                  updatedGroup,
                );

                if (!context.mounted) return;

                Navigator.pop(dialogContext);

                _showSnackBar(
                  context,
                  error == null ? 'Cập nhật nhóm thành công' : error,
                  error == null ? Colors.green : Colors.red,
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showGroupDetail(BuildContext context, Group group) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';
    final isCreator = group.isCreator(currentUserId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Text(
                          group.name.isNotEmpty
                              ? group.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(bottomSheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    group.description.isEmpty
                        ? 'Chưa có mô tả'
                        : group.description,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  _InfoTile(
                    icon: Icons.people,
                    title: 'Thành viên',
                    value: '${group.memberIds.length} thành viên',
                  ),
                  _InfoTile(
                    icon: Icons.person,
                    title: 'Người tạo',
                    value: group.creatorId,
                  ),
                  _InfoTile(
                    icon: Icons.calendar_today,
                    title: 'Ngày tạo',
                    value: _formatDate(group.createdAt),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Công việc nhóm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, _) {
                      final tasks = taskProvider.getTasksByGroupId(group.id);

                      if (tasks.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Chưa có công việc nhóm',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }

                      return Column(
                        children: tasks.map((task) {
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                task.isCompleted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: task.isCompleted
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              title: Text(task.title),
                              subtitle: Text(
                                task.description.isEmpty
                                    ? 'Không có mô tả'
                                    : task.description,
                              ),
                              trailing: Text(
                                _formatDate(task.deadline),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (isCreator) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _showAddMemberDialog(context, group);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Thêm thành viên'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _showEditGroupDialog(context, group);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Sửa nhóm'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _showDeleteConfirmation(context, group);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa nhóm'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Group group) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';

    if (!group.isCreator(currentUserId)) {
      _showSnackBar(context, 'Chỉ chủ nhóm mới có thể xóa', Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
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

                _showSnackBar(
                  context,
                  error == null ? 'Xóa nhóm thành công' : error,
                  error == null ? Colors.green : Colors.red,
                );
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().currentUser?.id ?? '';
    final isCreator = group.isCreator(currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.12),
                child: Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (group.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.people, size: 15, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberIds.length} thành viên',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (isCreator) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star,
                            size: 15,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Chủ nhóm',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) {
                  return [
                    if (isCreator)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Sửa nhóm'),
                          ],
                        ),
                      ),
                    if (isCreator)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Xóa nhóm',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
