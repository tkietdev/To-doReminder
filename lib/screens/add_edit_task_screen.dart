import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/group_provider.dart';

import '../models/task_model.dart';
import '../models/group_model.dart';

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
  bool _isGroupTask = false;
  String? _selectedGroupId;

  bool get isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      final task = widget.task!;

      _titleController = TextEditingController(text: task.title);
      _descriptionController = TextEditingController(text: task.description);
      _selectedDeadline = task.deadline;
      _selectedTime = TimeOfDay.fromDateTime(task.deadline);
      _selectedPriority = task.priority;
      _isGroupTask = task.groupId != null && task.groupId!.isNotEmpty;
      _selectedGroupId = task.groupId;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedDeadline = DateTime.now().add(const Duration(days: 1));
      _selectedTime = const TimeOfDay(hour: 12, minute: 0);
      _selectedPriority = TaskPriority.medium;
      _isGroupTask = false;
      _selectedGroupId = null;
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

    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final groupProvider = context.read<GroupProvider>();

    final user = authProvider.currentUser;

    if (user == null) {
      _showSnackBar('Chưa đăng nhập', Colors.red);
      return;
    }

    Group? selectedGroup;

    if (_isGroupTask) {
      if (_selectedGroupId == null || _selectedGroupId!.isEmpty) {
        _showSnackBar('Vui lòng chọn nhóm', Colors.red);
        return;
      }

      selectedGroup = groupProvider.findGroupById(_selectedGroupId!);

      if (selectedGroup == null) {
        _showSnackBar('Không tìm thấy nhóm', Colors.red);
        return;
      }
    }

    setState(() => _isLoading = true);

    final task = Task(
      id: isEditMode ? widget.task!.id : '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: _selectedDeadline,
      priority: _selectedPriority,
      isCompleted: isEditMode ? widget.task!.isCompleted : false,
      userId: user.id,
      groupId: _isGroupTask ? selectedGroup!.id : null,
      memberIds: _isGroupTask ? selectedGroup!.memberIds : [],
      createdAt: isEditMode ? widget.task!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    String? error;

    if (isEditMode) {
      error = await taskProvider.updateTask(task);
    } else {
      error = await taskProvider.addTask(task);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.pop(context);

      _showSnackBar(
        isEditMode
            ? 'Cập nhật công việc thành công'
            : 'Thêm công việc thành công',
        Colors.green,
      );
    } else {
      _showSnackBar(error, Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupProvider>().groups;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Chỉnh sửa công việc' : 'Thêm công việc'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

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

            const Text(
              'Loại công việc',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.person),
                  label: Text('Cá nhân'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.group),
                  label: Text('Nhóm'),
                ),
              ],
              selected: {_isGroupTask},
              onSelectionChanged: (value) {
                setState(() {
                  _isGroupTask = value.first;

                  if (!_isGroupTask) {
                    _selectedGroupId = null;
                  }
                });
              },
            ),

            if (_isGroupTask) ...[
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedGroupId,
                decoration: InputDecoration(
                  labelText: 'Chọn nhóm *',
                  prefixIcon: const Icon(Icons.group),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: groups.map((group) {
                  return DropdownMenuItem<String>(
                    value: group.id,
                    child: Text(group.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGroupId = value;
                  });
                },
                validator: (value) {
                  if (_isGroupTask && (value == null || value.isEmpty)) {
                    return 'Vui lòng chọn nhóm';
                  }
                  return null;
                },
              ),

              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Bạn chưa có nhóm nào. Hãy tạo nhóm trước.',
                    style: TextStyle(color: Colors.red[600], fontSize: 13),
                  ),
                ),
            ],

            const SizedBox(height: 16),

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
                      setState(() {
                        _selectedPriority = priority;
                      });
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
