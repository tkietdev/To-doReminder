import 'package:cloud_firestore/cloud_firestore.dart';

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
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.isCompleted,
    required this.userId,
    this.groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Chuyển từ Firestore Document sang Task
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      priority: TaskPriority.fromString(
        data['priority'] as String? ?? 'medium',
      ),
      isCompleted: data['isCompleted'] as bool? ?? false,
      userId: data['userId'] as String,
      groupId: data['groupId'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Chuyển từ JSON sang Task
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      priority: TaskPriority.fromString(json['priority'] as String),
      isCompleted: json['isCompleted'] as bool,
      userId: json['userId'] as String,
      groupId: json['groupId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  // Chuyển Task sang Map để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'priority': priority.value,
      'isCompleted': isCompleted,
      'userId': userId,
      'groupId': groupId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Chuyển Task sang JSON
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    TaskPriority? priority,
    bool? isCompleted,
    String? userId,
    String? groupId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Kiểm tra task có quá hạn không
  bool get isOverdue {
    if (isCompleted) return false;
    return deadline.isBefore(DateTime.now());
  }

  // Kiểm tra task sắp đến hạn (trong 3 ngày)
  bool get isUpcoming {
    if (isCompleted || isOverdue) return false;
    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;
    return diff <= 3 && diff >= 0;
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, priority: ${priority.label}, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
