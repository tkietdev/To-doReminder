enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Thấp';
      case TaskPriority.medium:
        return 'Trung bình';
      case TaskPriority.high:
        return 'Cao';
      case TaskPriority.urgent:
        return 'Khẩn cấp';
    }
  }

  String get value => name;

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final TaskPriority priority;
  final bool isCompleted;

  final String userId;
  final String? groupId;
  final List<String> memberIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.isCompleted,
    required this.userId,
    this.groupId,
    this.memberIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.create({
    required String title,
    required String description,
    required DateTime deadline,
    required TaskPriority priority,
    required String userId,
    String? groupId,
    List<String> memberIds = const [],
  }) {
    final now = DateTime.now();

    return Task(
      id: '',
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      isCompleted: false,
      userId: userId,
      groupId: groupId,
      memberIds: memberIds,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      deadline: _parseDateTime(json['deadline']),
      priority: TaskPriority.fromString(
        json['priority'] as String? ?? 'medium',
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      userId: json['userId'] as String? ?? '',
      groupId: json['groupId'] as String?,
      memberIds: List<String>.from(json['memberIds'] ?? []),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'priority': priority.value,
      'isCompleted': isCompleted,
      'userId': userId,
      'groupId': groupId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    TaskPriority? priority,
    bool? isCompleted,
    String? userId,
    String? groupId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      memberIds: memberIds ?? List<String>.from(this.memberIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isGroupTask {
    return groupId != null && groupId!.isNotEmpty;
  }

  bool get isPersonalTask {
    return !isGroupTask;
  }

  bool get isOverdue {
    if (isCompleted) return false;
    return deadline.isBefore(DateTime.now());
  }

  bool get isUpcoming {
    if (isCompleted || isOverdue) return false;

    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;

    return diff <= 3 && diff >= 0;
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
    return 'Task(id: $id, title: $title, priority: ${priority.label}, groupId: $groupId, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
