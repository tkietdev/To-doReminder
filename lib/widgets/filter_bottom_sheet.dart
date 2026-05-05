import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  TaskPriority? _selectedPriority;
  bool? _selectedCompleted;

  @override
  void initState() {
    super.initState();
    final taskProvider = context.read<TaskProvider>();
    _selectedPriority = taskProvider.filterPriority;
    _selectedCompleted = taskProvider.filterCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lọc công việc',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedPriority = null;
                    _selectedCompleted = null;
                  });
                },
                child: const Text('Xóa bộ lọc'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Priority Filter
          const Text(
            'Độ ưu tiên',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPriorityChip(null, 'Tất cả', Colors.grey),
              ...TaskPriority.values.map((priority) {
                return _buildPriorityChip(
                  priority,
                  priority.label,
                  _getPriorityColor(priority),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          // Status Filter
          const Text(
            'Trạng thái',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildStatusChip(null, 'Tất cả'),
              _buildStatusChip(false, 'Chưa hoàn thành'),
              _buildStatusChip(true, 'Đã hoàn thành'),
            ],
          ),
          const SizedBox(height: 24),

          // Apply Button
          ElevatedButton(
            onPressed: () {
              final taskProvider = context.read<TaskProvider>();
              taskProvider.setFilterPriority(_selectedPriority);
              taskProvider.setFilterCompleted(_selectedCompleted);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Áp dụng',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority? priority, String label, Color color) {
    final isSelected = _selectedPriority == priority;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPriority = selected ? priority : null;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: color.withOpacity(0.5),
      ),
    );
  }

  Widget _buildStatusChip(bool? completed, String label) {
    final isSelected = _selectedCompleted == completed;
    Color color;
    if (completed == null) {
      color = Colors.grey;
    } else if (completed) {
      color = Colors.green;
    } else {
      color = Colors.orange;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCompleted = selected ? completed : null;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: color.withOpacity(0.5),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
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
}