class Group {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.empty() {
    return Group(
      id: '',
      name: '',
      description: '',
      creatorId: '',
      memberIds: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      creatorId: json['creatorId'] as String? ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

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
      memberIds: memberIds ?? List<String>.from(this.memberIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isCreator(String userId) {
    return creatorId == userId;
  }

  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  bool get isValid {
    return name.trim().isNotEmpty &&
        creatorId.trim().isNotEmpty &&
        memberIds.isNotEmpty;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  @override
  String toString() {
    return 'Group(id: $id, name: $name, creatorId: $creatorId, members: ${memberIds.length})';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
