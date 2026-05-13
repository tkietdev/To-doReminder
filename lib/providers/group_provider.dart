import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/group_model.dart';

class GroupProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Group> _groups = [];

  bool _isLoading = false;
  String? _error;

  List<Group> get groups => List.unmodifiable(_groups);
  bool get isLoading => _isLoading;
  String? get error => _error;

  CollectionReference get _groupCollection {
    return _firestore.collection('groups');
  }

  CollectionReference get _userCollection {
    return _firestore.collection('users');
  }

  Future<void> loadGroups(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      final snapshot = await _groupCollection
          .where('memberIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      _groups
        ..clear()
        ..addAll(
          snapshot.docs.map((doc) {
            return Group.fromFirestore(doc);
          }).toList(),
        );

      _setLoading(false);
    } catch (e) {
      _setError('Không thể tải danh sách nhóm: $e');
    }
  }

  Stream<List<Group>> groupStream(String userId) {
    return _groupCollection
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Group.fromFirestore(doc);
          }).toList();
        });
  }

  Future<String?> addGroup(Group group) async {
    try {
      _error = null;

      if (!group.isValid) {
        return 'Thông tin nhóm không hợp lệ';
      }

      final now = DateTime.now();

      final newGroup = group.copyWith(createdAt: now, updatedAt: now);

      final docRef = await _groupCollection.add(newGroup.toCreateFirestore());

      _groups.insert(0, newGroup.copyWith(id: docRef.id));

      notifyListeners();
      return null;
    } catch (e) {
      return 'Không thể tạo nhóm: $e';
    }
  }

  Future<String?> updateGroup(Group group) async {
    try {
      _error = null;

      if (group.id.isEmpty) {
        return 'Không tìm thấy nhóm';
      }

      if (group.name.trim().isEmpty) {
        return 'Tên nhóm không được để trống';
      }

      final updatedGroup = group.copyWith(updatedAt: DateTime.now());

      await _groupCollection
          .doc(group.id)
          .update(updatedGroup.toUpdateFirestore());

      final index = _groups.indexWhere((item) {
        return item.id == group.id;
      });

      if (index != -1) {
        _groups[index] = updatedGroup;
      }

      notifyListeners();
      return null;
    } catch (e) {
      return 'Không thể cập nhật nhóm: $e';
    }
  }

  Future<String?> deleteGroup(String groupId) async {
    try {
      _error = null;

      if (groupId.isEmpty) {
        return 'Không tìm thấy nhóm';
      }

      await _groupCollection.doc(groupId).delete();

      _groups.removeWhere((group) {
        return group.id == groupId;
      });

      notifyListeners();
      return null;
    } catch (e) {
      return 'Không thể xóa nhóm: $e';
    }
  }

  Future<String?> addMemberByEmail({
    required String groupId,
    required String email,
  }) async {
    try {
      _error = null;

      final emailText = email.trim().toLowerCase();

      if (groupId.isEmpty) {
        return 'Không tìm thấy nhóm';
      }

      if (emailText.isEmpty) {
        return 'Vui lòng nhập email';
      }

      final groupIndex = _groups.indexWhere((group) {
        return group.id == groupId;
      });

      if (groupIndex == -1) {
        return 'Không tìm thấy nhóm';
      }

      final userSnapshot = await _userCollection
          .where('email', isEqualTo: emailText)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        return 'Không tìm thấy người dùng với email này';
      }

      final userId = userSnapshot.docs.first.id;
      final group = _groups[groupIndex];

      if (group.memberIds.contains(userId)) {
        return 'Người dùng đã có trong nhóm';
      }

      await _groupCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final newMembers = List<String>.from(group.memberIds)..add(userId);

      _groups[groupIndex] = group.copyWith(
        memberIds: newMembers,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
      return null;
    } catch (e) {
      return 'Không thể thêm thành viên: $e';
    }
  }

  Future<String?> addMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      _error = null;

      if (groupId.isEmpty || userId.isEmpty) {
        return 'Thông tin thành viên không hợp lệ';
      }

      final index = _groups.indexWhere((group) {
        return group.id == groupId;
      });

      if (index == -1) {
        return 'Không tìm thấy nhóm';
      }

      final group = _groups[index];

      if (group.memberIds.contains(userId)) {
        return 'Người dùng đã có trong nhóm';
      }

      await _groupCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final newMembers = List<String>.from(group.memberIds)..add(userId);

      _groups[index] = group.copyWith(
        memberIds: newMembers,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
      return null;
    } catch (e) {
      return 'Không thể thêm thành viên: $e';
    }
  }

  Future<String?> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      _error = null;

      if (groupId.isEmpty || userId.isEmpty) {
        return 'Thông tin thành viên không hợp lệ';
      }

      final index = _groups.indexWhere((group) {
        return group.id == groupId;
      });

      if (index == -1) {
        return 'Không tìm thấy nhóm';
      }

      final group = _groups[index];

      if (group.creatorId == userId) {
        return 'Không thể xóa chủ nhóm khỏi nhóm';
      }

      await _groupCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final newMembers = List<String>.from(group.memberIds)..remove(userId);

      _groups[index] = group.copyWith(
        memberIds: newMembers,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
      return null;
    } catch (e) {
      return 'Không thể xóa thành viên: $e';
    }
  }

  Future<Group?> getGroupById(String groupId) async {
    try {
      _error = null;

      if (groupId.isEmpty) {
        return null;
      }

      final doc = await _groupCollection.doc(groupId).get();

      if (!doc.exists) {
        return null;
      }

      return Group.fromFirestore(doc);
    } catch (e) {
      _error = 'Không thể lấy thông tin nhóm: $e';
      notifyListeners();
      return null;
    }
  }

  Group? findGroupById(String groupId) {
    try {
      return _groups.firstWhere((group) {
        return group.id == groupId;
      });
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
