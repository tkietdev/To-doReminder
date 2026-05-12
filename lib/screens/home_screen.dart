import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/group_provider.dart';

import '../models/task_model.dart';

import 'add_edit_task_screen.dart';
import 'login_screen.dart';
import 'groups_screen.dart';

import '../services/notification_service.dart';
import '../widgets/task_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final groupProvider = context.read<GroupProvider>();

    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      await taskProvider.loadTasks(userId);
      await groupProvider.loadGroups(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }

  Widget _buildTaskList() {
    return Consumer2<AuthProvider, TaskProvider>(
      builder: (context, auth, taskProvider, _) {
        if (taskProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = taskProvider.tasks;

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có công việc nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn nút + để thêm công việc mới',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              return TaskCard(
                task: task,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditTaskScreen(task: task),
                    ),
                  );
                },
                onToggle: () {
                  final userId = auth.currentUser?.id;

                  if (userId != null) {
                    taskProvider.toggleTaskCompletion(task.id, userId);
                  }
                },
                onDelete: () {
                  _showDeleteConfirmation(task, taskProvider, auth);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatisticsView() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final allTasks = taskProvider.tasks;
        final completedTasks = allTasks.where((t) => t.isCompleted).length;
        final pendingTasks = allTasks.length - completedTasks;
        final overdueTasks = taskProvider.getOverdueTasks().length;
        final upcomingTasks = taskProvider.getUpcomingTasks().length;

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thống kê công việc',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildStatItem(
                        'Tổng công việc',
                        allTasks.length.toString(),
                        Icons.list_alt,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'Đã hoàn thành',
                        completedTasks.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'Đang thực hiện',
                        pendingTasks.toString(),
                        Icons.pending,
                        Colors.orange,
                      ),
                      _buildStatItem(
                        'Quá hạn',
                        overdueTasks.toString(),
                        Icons.warning,
                        Colors.red,
                      ),
                      _buildStatItem(
                        'Sắp đến hạn',
                        upcomingTasks.toString(),
                        Icons.access_time,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (overdueTasks > 0)
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Công việc quá hạn',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...taskProvider.getOverdueTasks().map((task) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM').format(task.deadline),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    Task task,
    TaskProvider taskProvider,
    AuthProvider auth,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc muốn xóa công việc "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final userId = auth.currentUser?.id;

                if (userId != null) {
                  taskProvider.deleteTask(task.id, userId);
                }

                Navigator.pop(dialogContext);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _getSelectedView() {
    switch (_selectedIndex) {
      case 0:
        return _buildTaskList();
      case 1:
        return _buildStatisticsView();
      case 2:
        return const GroupsScreen();
      default:
        return _buildTaskList();
    }
  }

  Future<void> _showPendingNotifications() async {
    final pending = await NotificationService().getPendingNotifications();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pending Notifications (${pending.length})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: pending.isEmpty
                  ? const [Text('Không có thông báo nào đang chờ')]
                  : pending.map((n) {
                      return ListTile(
                        title: Text(n.title ?? 'No title'),
                        subtitle: Text(n.body ?? 'No body'),
                      );
                    }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showAccountDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thông tin tài khoản'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tên: ${auth.currentUser?.name ?? ''}'),
              const SizedBox(height: 8),
              Text('Email: ${auth.currentUser?.email ?? ''}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(AuthProvider auth) async {
    await auth.logout();

    if (!mounted) return;

    context.read<TaskProvider>().clearTasks();
    context.read<GroupProvider>().clearGroups();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('TaskMate'),
            actions: [
              if (_selectedIndex == 0)
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterSheet,
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'account') {
                    _showAccountDialog(auth);
                  } else if (value == 'notifications') {
                    await _showPendingNotifications();
                  } else if (value == 'logout') {
                    await _logout(auth);
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'account',
                      child: Row(
                        children: [
                          Icon(Icons.person),
                          SizedBox(width: 8),
                          Text('Thông tin tài khoản'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'notifications',
                      child: Row(
                        children: [
                          Icon(Icons.list),
                          SizedBox(width: 8),
                          Text('Xem Notifications'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Đăng xuất',
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
          body: Column(
            children: [
              if (_selectedIndex == 0)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm công việc...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<TaskProvider>().setSearchQuery('');
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      context.read<TaskProvider>().setSearchQuery(value);
                      setState(() {});
                    },
                  ),
                ),
              Expanded(child: _getSelectedView()),
            ],
          ),
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddEditTaskScreen(),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            selectedItemColor: Theme.of(context).colorScheme.primary,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Công việc',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Thống kê',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Nhóm'),
            ],
          ),
        );
      },
    );
  }
}
