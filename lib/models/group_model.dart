import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Chuyển từ Firestore Document sang Group
  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      creatorId: data['creatorId'] as String,
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Chuyển từ JSON sang Group
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      creatorId: json['creatorId'] as String,
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  // Chuyển Group sang Map để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Chuyển Group sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Kiểm tra user có phải là creator không
  bool isCreator(String userId) {
    return creatorId == userId;
  }

  // Kiểm tra user có phải là member không
  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  @override
  String toString() {
    return 'Group(id: $id, name: $name, members: ${memberIds.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}