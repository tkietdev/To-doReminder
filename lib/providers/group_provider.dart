import 'package:flutter/material.dart';

import '../models/group_model.dart';
import '../services/api_client.dart';

class GroupProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  final List<Group> _groups = [];

  bool _isLoading = false;
  String? _error;

  List<Group> get groups => List.unmodifiable(_groups);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGroups(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      final data = await _api.get('/groups');
      final rows = data['groups'] as List<dynamic>? ?? [];

      _groups
        ..clear()
        ..addAll(
          rows.map((item) {
            return Group.fromJson(item as Map<String, dynamic>);
          }),
        );

      _setLoading(false);
    } catch (e) {
      _setError(_messageFromError(e));
    }
  }

  Stream<List<Group>> groupStream(String userId) {
    return Stream.value(List.unmodifiable(_groups));
  }

  Future<String?> addGroup(Group group) async {
    try {
      _error = null;

      if (!group.isValid) {
        return 'Thong tin nhom khong hop le';
      }

      final data = await _api.post(
        '/groups',
        body: {
          'name': group.name.trim(),
          'description': group.description.trim(),
          'memberIds': group.memberIds,
        },
      );

      final newGroup = Group.fromJson(data['group'] as Map<String, dynamic>);
      _groups.insert(0, newGroup);

      notifyListeners();
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<String?> updateGroup(Group group) async {
    try {
      _error = null;

      if (group.id.isEmpty) return 'Khong tim thay nhom';
      if (group.name.trim().isEmpty) return 'Ten nhom khong duoc de trong';

      final data = await _api.put(
        '/groups/${group.id}',
        body: {
          'name': group.name.trim(),
          'description': group.description.trim(),
        },
      );

      final updatedGroup = Group.fromJson(
        data['group'] as Map<String, dynamic>,
      );
      final index = _groups.indexWhere((item) => item.id == group.id);

      if (index != -1) {
        _groups[index] = updatedGroup;
      }

      notifyListeners();
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<String?> deleteGroup(String groupId) async {
    try {
      _error = null;

      if (groupId.isEmpty) return 'Khong tim thay nhom';

      await _api.delete('/groups/$groupId');
      _groups.removeWhere((group) => group.id == groupId);

      notifyListeners();
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<String?> addMemberByEmail({
    required String groupId,
    required String email,
  }) async {
    try {
      _error = null;

      final emailText = email.trim().toLowerCase();
      if (groupId.isEmpty) return 'Khong tim thay nhom';
      if (emailText.isEmpty) return 'Vui long nhap email';

      final data = await _api.post(
        '/groups/$groupId/members/email',
        body: {'email': emailText},
      );

      _replaceGroup(Group.fromJson(data['group'] as Map<String, dynamic>));
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<String?> addMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      _error = null;

      if (groupId.isEmpty || userId.isEmpty) {
        return 'Thong tin thanh vien khong hop le';
      }

      final data = await _api.post(
        '/groups/$groupId/members',
        body: {'userId': userId},
      );

      _replaceGroup(Group.fromJson(data['group'] as Map<String, dynamic>));
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<String?> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      _error = null;

      if (groupId.isEmpty || userId.isEmpty) {
        return 'Thong tin thanh vien khong hop le';
      }

      final data = await _api.delete('/groups/$groupId/members/$userId');
      _replaceGroup(Group.fromJson(data['group'] as Map<String, dynamic>));
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<Group?> getGroupById(String groupId) async {
    try {
      _error = null;
      if (groupId.isEmpty) return null;

      final data = await _api.get('/groups/$groupId');
      return Group.fromJson(data['group'] as Map<String, dynamic>);
    } catch (e) {
      _error = _messageFromError(e);
      notifyListeners();
      return null;
    }
  }

  Group? findGroupById(String groupId) {
    try {
      return _groups.firstWhere((group) => group.id == groupId);
    } catch (_) {
      return null;
    }
  }

  void clearGroups() {
    _groups.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _replaceGroup(Group group) {
    final index = _groups.indexWhere((item) => item.id == group.id);
    if (index == -1) {
      _groups.insert(0, group);
    } else {
      _groups[index] = group;
    }
    notifyListeners();
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

  void _setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }
}
