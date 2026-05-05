import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/group_model.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Task> _tasks = [];
  List<Group> _groups = [];
  bool _isLoading = false;
  String _searchQuery = '';
  TaskPriority? _filterPriority;
  bool? _filterCompleted;

  List<Task> get tasks {
    var filtered = _tasks;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by priority
    if (_filterPriority != null) {
      filtered = filtered.where((task) => task.priority == _filterPriority).toList();
    }

    // Filter by completion status
    if (_filterCompleted != null) {
      filtered = filtered.where((task) => task.isCompleted == _filterCompleted).toList();
    }

    // Sort by deadline (upcoming first)
    filtered.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.deadline.compareTo(b.deadline);
    });

    return filtered;
  }

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  TaskPriority? get filterPriority => _filterPriority;
  bool? get filterCompleted => _filterCompleted;

  // Load tasks từ Firestore
  Future<void> loadTasks(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      _tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Load tasks error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load groups từ Firestore
  Future<void> loadGroups(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .get();

      _groups = snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Load groups error: $e');
    }
  }

  // Thêm task mới
  Future<String?> addTask(Task task) async {
    try {
      final docRef = await _firestore.collection('tasks').add(task.toFirestore());
      final newTask = task.copyWith(id: docRef.id);
      _tasks.add(newTask);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Thêm công việc thất bại: $e';
    }
  }

  // Cập nhật task
  Future<String?> updateTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).update(task.toFirestore());

      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
      return null; // Success
    } catch (e) {
      return 'Cập nhật công việc thất bại: $e';
    }
  }

  // Xóa task
  Future<String?> deleteTask(String taskId, String userId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Xóa công việc thất bại: $e';
    }
  }

  // Toggle hoàn thành task
  Future<void> toggleTaskCompletion(String taskId, String userId) async {
    try {
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return;

      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': updatedTask.isCompleted,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _tasks[taskIndex] = updatedTask;
      notifyListeners();
    } catch (e) {
      debugPrint('Toggle task error: $e');
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set filter priority
  void setFilterPriority(TaskPriority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  // Set filter completed
  void setFilterCompleted(bool? completed) {
    _filterCompleted = completed;
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _filterPriority = null;
    _filterCompleted = null;
    _searchQuery = '';
    notifyListeners();
  }

  // Get overdue tasks
  List<Task> getOverdueTasks() {
    return _tasks.where((task) => task.isOverdue).toList();
  }

  // Get upcoming tasks
  List<Task> getUpcomingTasks() {
    return _tasks.where((task) => task.isUpcoming).toList();
  }

  // Get completed tasks
  List<Task> getCompletedTasks() {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  // Get pending tasks
  List<Task> getPendingTasks() {
    return _tasks.where((task) => !task.isCompleted).toList();
  }

  // Thêm group mới
  Future<String?> addGroup(Group group) async {
    try {
      final docRef = await _firestore.collection('groups').add(group.toFirestore());
      final newGroup = group.copyWith(id: docRef.id);
      _groups.add(newGroup);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Thêm nhóm thất bại: $e';
    }
  }

  // Cập nhật group
  Future<String?> updateGroup(Group group) async {
    try {
      await _firestore.collection('groups').doc(group.id).update(group.toFirestore());

      final index = _groups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _groups[index] = group;
        notifyListeners();
      }
      return null; // Success
    } catch (e) {
      return 'Cập nhật nhóm thất bại: $e';
    }
  }

  // Xóa group
  Future<String?> deleteGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).delete();
      _groups.removeWhere((group) => group.id == groupId);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Xóa nhóm thất bại: $e';
    }
  }
}