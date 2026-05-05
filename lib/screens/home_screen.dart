import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'add_edit_task_screen.dart';
import 'login_screen.dart';
import '../services/notification_service.dart';
// import 'groups_screen.dart'; // Tạm comment nếu chưa có file này
import '../widgets/task_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await taskProvider.loadTasks(authProvider.currentUser!.id);
      await taskProvider.loadGroups(authProvider.currentUser!.id);
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
                Icon(
                  Icons.task_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có công việc nào',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn nút + để thêm công việc mới',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
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
              return TaskCard(
                task: tasks[index],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditTaskScreen(task: tasks[index]),
                    ),
                  );
                },
                onToggle: () {
                  taskProvider.toggleTaskCompletion(
                    tasks[index].id,
                    auth.currentUser!.id,
                  );
                },
                onDelete: () {
                  _showDeleteConfirmation(tasks[index], taskProvider, auth);
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

        return ListView(
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
        );
      },
    );
  }

  // ✅ THÊM VIEW CHO TAB NHÓM
  Widget _buildGroupsView() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final groups = taskProvider.groups;

        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có nhóm nào',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tính năng đang phát triển',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(group.name[0].toUpperCase()),
                ),
                title: Text(group.name),
                subtitle: Text('${group.memberIds.length} thành viên'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to group detail
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đang phát triển'),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
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

  void _showDeleteConfirmation(Task task, TaskProvider taskProvider, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa công việc "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              taskProvider.deleteTask(task.id, auth.currentUser!.id);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ✅ HÀM CHỌN VIEW THEO INDEX
  Widget _getSelectedView() {
    switch (_selectedIndex) {
      case 0:
        return _buildTaskList();
      case 1:
        return _buildStatisticsView();
      case 2:
        return _buildGroupsView();
      default:
        return _buildTaskList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('TaskMate'),
            actions: [
              if (_selectedIndex == 0) // Chỉ hiện filter ở tab Công việc
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterSheet,
                ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Thông tin tài khoản'),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(Duration.zero, () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Thông tin tài khoản'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tên: ${auth.currentUser?.name}'),
                                const SizedBox(height: 8),
                                Text('Email: ${auth.currentUser?.email}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    onTap: () async {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
              // Thêm PopupMenuItem Xem Notifications
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Xem Notifications'),
                  ],
                ),
                onTap: () async {
                  final pending = await NotificationService().getPendingNotifications();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Pending Notifications (${pending.length})'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: pending.map((n) =>
                                ListTile(
                                  title: Text(n.title ?? 'No title'),
                                  subtitle: Text(n.body ?? 'No body'),
                                )
                            ).toList(),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar - chỉ hiện ở tab Công việc
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
                          Provider.of<TaskProvider>(context, listen: false)
                              .setSearchQuery('');
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      Provider.of<TaskProvider>(context, listen: false)
                          .setSearchQuery(value);
                    },
                  ),
                ),

              // ✅ SỬ DỤNG HÀM _getSelectedView() thay vì ternary operator
              Expanded(
                child: _getSelectedView(),
              ),
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Công việc',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Thống kê',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Nhóm',
              ),
            ],
            selectedItemColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}