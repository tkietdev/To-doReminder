import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case TaskPriority.low:
        return Icons.arrow_downward;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.arrow_upward;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    final isUpcoming = task.isUpcoming;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue
              ? Colors.red.withOpacity(0.5)
              : isUpcoming
              ? Colors.orange.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Checkbox + Title + Priority
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => onToggle(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Title + Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getPriorityColor().withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPriorityIcon(),
                          size: 14,
                          color: _getPriorityColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.priority.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer: Deadline + Status
              Row(
                children: [
                  // Deadline
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isOverdue
                        ? Colors.red
                        : isUpcoming
                        ? Colors.orange
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(task.deadline),
                    style: TextStyle(
                      fontSize: 13,
                      color: isOverdue
                          ? Colors.red
                          : isUpcoming
                          ? Colors.orange
                          : Colors.grey[600],
                      fontWeight: isOverdue || isUpcoming
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),

                  const Spacer(),

                  // Status badge
                  if (isOverdue && !task.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Quá hạn',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isUpcoming && !task.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Sắp đến hạn',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (task.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Hoàn thành',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
