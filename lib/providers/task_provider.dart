import 'package:flutter/foundation.dart';

import '../models/task_model.dart';
import '../services/api_client.dart';

class TaskProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  TaskPriority? _filterPriority;
  bool? _filterCompleted;

  List<Task> get tasks {
    var filtered = List<Task>.from(_tasks);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((task) {
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
      final data = await _api.get('/tasks');
      final rows = data['tasks'] as List<dynamic>? ?? [];
      _tasks = rows.map((item) {
        return Task.fromJson(item as Map<String, dynamic>);
      }).toList();
      _setLoading(false);
    } catch (e) {
      debugPrint('Load tasks error: $e');
      _setLoading(false);
    }
  }

  Future<String?> addTask(Task task) async {
    try {
      final data = await _api.post('/tasks', body: _taskPayload(task));
      final newTask = Task.fromJson(data['task'] as Map<String, dynamic>);
      _tasks.add(newTask);
      notifyListeners();
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<String?> updateTask(Task task) async {
    try {
      if (task.id.isEmpty) return 'Khong tim thay cong viec';

      final data = await _api.put(
        '/tasks/${task.id}',
        body: _taskPayload(task),
      );
      final updatedTask = Task.fromJson(data['task'] as Map<String, dynamic>);
      final index = _tasks.indexWhere((item) => item.id == task.id);

      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      notifyListeners();
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<String?> deleteTask(String taskId, String userId) async {
    try {
      if (taskId.isEmpty) return 'Khong tim thay cong viec';

      await _api.delete('/tasks/$taskId');
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<String?> toggleTaskCompletion(String taskId, String userId) async {
    try {
      final data = await _api.patch('/tasks/$taskId/toggle');
      final updatedTask = Task.fromJson(data['task'] as Map<String, dynamic>);
      final index = _tasks.indexWhere((task) => task.id == taskId);

      if (index != -1) {
        _tasks[index] = updatedTask;
      }

      notifyListeners();
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  List<Task> getTasksByGroupId(String groupId) {
    return _tasks.where((task) => task.groupId == groupId).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.deadline.compareTo(b.deadline);
      });
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
    return _tasks.where((task) => task.isOverdue).toList();
  }

  List<Task> getUpcomingTasks() {
    return _tasks.where((task) => task.isUpcoming).toList();
  }

  List<Task> getCompletedTasks() {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  List<Task> getPendingTasks() {
    return _tasks.where((task) => !task.isCompleted).toList();
  }

  void clearTasks() {
    _tasks.clear();
    _searchQuery = '';
    _filterPriority = null;
    _filterCompleted = null;
    _isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> _taskPayload(Task task) {
    return {
      'title': task.title.trim(),
      'description': task.description.trim(),
      'deadline': task.deadline.toIso8601String(),
      'priority': task.priority.value,
      'isCompleted': task.isCompleted,
      'groupId': task.groupId,
    };
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Co loi xay ra: $error';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
