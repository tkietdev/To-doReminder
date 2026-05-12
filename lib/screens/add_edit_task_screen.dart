import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDeadline;
  late TimeOfDay _selectedTime;
  late TaskPriority _selectedPriority;
  bool _isLoading = false;

  bool get isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _titleController = TextEditingController(text: widget.task!.title);
      _descriptionController = TextEditingController(
        text: widget.task!.description,
      );
      _selectedDeadline = widget.task!.deadline;
      _selectedTime = TimeOfDay.fromDateTime(widget.task!.deadline);
      _selectedPriority = widget.task!.priority;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDeadline = DateTime.now().add(const Duration(days: 1));
      _selectedTime = const TimeOfDay(hour: 12, minute: 0);
      _selectedPriority = TaskPriority.medium;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDeadline = DateTime(
          _selectedDeadline.year,
          _selectedDeadline.month,
          _selectedDeadline.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();

    if (authProvider.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa đăng nhập'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final task = Task(
      id: isEditMode ? widget.task!.id : '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: _selectedDeadline,
      priority: _selectedPriority,
      isCompleted: isEditMode ? widget.task!.isCompleted : false,
      userId: authProvider.currentUser!.id,
      groupId: isEditMode ? widget.task!.groupId : null,
      createdAt: isEditMode ? widget.task!.createdAt : DateTime.now(),
    );

    String? error;
    if (isEditMode) {
      error = await taskProvider.updateTask(task);
    } else {
      error = await taskProvider.addTask(task);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (error == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Cập nhật công việc thành công'
                  : 'Thêm công việc thành công',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Chỉnh sửa công việc' : 'Thêm công việc'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu đề *',
                hintText: 'Nhập tiêu đề công việc',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Nhập mô tả chi tiết',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Deadline Date
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Ngày hết hạn *',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDeadline),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Deadline Time
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Giờ hết hạn *',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Priority
            const Text(
              'Độ ưu tiên *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskPriority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                final color = _getPriorityColor(priority);

                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 4),
                      Text(priority.label),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPriority = priority);
                    }
                  },
                  backgroundColor: color.withOpacity(0.1),
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide(color: color.withOpacity(0.5)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditMode ? 'Cập nhật' : 'Thêm công việc',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
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

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
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
}
