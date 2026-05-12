import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  TaskPriority? _filterPriority;
  bool? _filterCompleted;

  List<Task> get tasks {
    var filtered = List<Task>.from(_tasks);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        final query = _searchQuery.toLowerCase();

        return task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query);
      }).toList();
    }

    if (_filterPriority != null) {
      filtered = filtered.where((task) {
        return task.priority == _filterPriority;
      }).toList();
    }

    if (_filterCompleted != null) {
      filtered = filtered.where((task) {
        return task.isCompleted == _filterCompleted;
      }).toList();
    }

    filtered.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      return a.deadline.compareTo(b.deadline);
    });

    return filtered;
  }

  List<Task> get allTasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  TaskPriority? get filterPriority => _filterPriority;
  bool? get filterCompleted => _filterCompleted;

  Future<void> loadTasks(String userId) async {
    try {
      _setLoading(true);

      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .get();

      _tasks = snapshot.docs.map((doc) {
        return Task.fromFirestore(doc);
      }).toList();

      _setLoading(false);
    } catch (e) {
      debugPrint('Load tasks error: $e');
      _setLoading(false);
    }
  }

  Future<String?> addTask(Task task) async {
    try {
      final docRef = await _firestore
          .collection('tasks')
          .add(task.toFirestore());

      final newTask = task.copyWith(id: docRef.id);

      _tasks.add(newTask);
      notifyListeners();

      return null;
    } catch (e) {
      return 'Thêm công việc thất bại: $e';
    }
  }

  Future<String?> updateTask(Task task) async {
    try {
      if (task.id.isEmpty) {
        return 'Không tìm thấy công việc';
      }

      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(task.toFirestore());

      final index = _tasks.indexWhere((item) {
        return item.id == task.id;
      });

      if (index != -1) {
        _tasks[index] = task;
      }

      notifyListeners();
      return null;
    } catch (e) {
      return 'Cập nhật công việc thất bại: $e';
    }
  }

  Future<String?> deleteTask(String taskId, String userId) async {
    try {
      if (taskId.isEmpty) {
        return 'Không tìm thấy công việc';
      }

      await _firestore.collection('tasks').doc(taskId).delete();

      _tasks.removeWhere((task) {
        return task.id == taskId;
      });

      notifyListeners();
      return null;
    } catch (e) {
      return 'Xóa công việc thất bại: $e';
    }
  }

  Future<String?> toggleTaskCompletion(String taskId, String userId) async {
    try {
      final index = _tasks.indexWhere((task) {
        return task.id == taskId;
      });

      if (index == -1) {
        return 'Không tìm thấy công việc';
      }

      final oldTask = _tasks[index];

      final updatedTask = oldTask.copyWith(
        isCompleted: !oldTask.isCompleted,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': updatedTask.isCompleted,
        'updatedAt': Timestamp.fromDate(updatedTask.updatedAt),
      });

      _tasks[index] = updatedTask;
      notifyListeners();

      return null;
    } catch (e) {
      return 'Cập nhật trạng thái thất bại: $e';
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterPriority(TaskPriority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void setFilterCompleted(bool? completed) {
    _filterCompleted = completed;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterPriority = null;
    _filterCompleted = null;
    notifyListeners();
  }

  List<Task> getOverdueTasks() {
    return _tasks.where((task) {
      return task.isOverdue;
    }).toList();
  }

  List<Task> getUpcomingTasks() {
    return _tasks.where((task) {
      return task.isUpcoming;
    }).toList();
  }

  List<Task> getCompletedTasks() {
    return _tasks.where((task) {
      return task.isCompleted;
    }).toList();
  }

  List<Task> getPendingTasks() {
    return _tasks.where((task) {
      return !task.isCompleted;
    }).toList();
  }

  void clearTasks() {
    _tasks.clear();
    _searchQuery = '';
    _filterPriority = null;
    _filterCompleted = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
