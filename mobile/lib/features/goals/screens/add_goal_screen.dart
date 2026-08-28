import 'package:flutter/material.dart';

import '../models/goal_models.dart';
import '../services/goal_service.dart';

class AddGoalScreen extends StatefulWidget {
  final GoalResponse? goal;

  const AddGoalScreen({super.key, this.goal});

  bool get isEditing => goal != null;

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  late final GoalService _goalService;

  String _selectedType = 'Distance';

  final _targetController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;

  bool _isSaving = false;

  static const _goalTypes = ['Distance', 'Duration', 'Calories', 'Activities'];

  @override
  void initState() {
    super.initState();

    _goalService = GoalService();

    final goal = widget.goal;

    if (goal != null) {
      _selectedType = goal.type;
      _targetController.text = goal.target.toString().replaceFirst(
        RegExp(r'\.0$'),
        '',
      );

      _startDate = goal.startDate.toLocal();
      _endDate = goal.endDate.toLocal();
    } else {
      final now = DateTime.now();

      _startDate = DateTime(now.year, now.month, now.day);

      _endDate = _startDate.add(const Duration(days: 6));
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    _goalService.dispose();
    super.dispose();
  }

  String _targetLabel() {
    switch (_selectedType) {
      case 'Distance':
        return 'Target Distance (km)';

      case 'Duration':
        return 'Target Duration (seconds)';

      case 'Calories':
        return 'Target Calories (kcal)';

      case 'Activities':
        return 'Target Activities';

      default:
        return 'Target';
    }
  }

  String _hintText() {
    switch (_selectedType) {
      case 'Distance':
        return 'e.g. 50';

      case 'Duration':
        return 'e.g. 7200';

      case 'Calories':
        return 'e.g. 3000';

      case 'Activities':
        return 'e.g. 5';

      default:
        return '';
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = date;

      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = date;
    });
  }

  Future<void> _save() async {
    final targetText = _targetController.text.trim();

    if (targetText.isEmpty) {
      _showError('Target is required.');
      return;
    }

    final target = double.tryParse(targetText);

    if (target == null || target <= 0) {
      _showError('Target must be greater than zero.');
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      _showError('End date must be on or after the start date.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing) {
        final request = UpdateGoalRequest(
          type: _selectedType,
          target: target,
          startDate: _startDate,
          endDate: DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            23,
            59,
            59,
          ),
        );

        await _goalService.updateGoal(widget.goal!.id, request);
      } else {
        final request = CreateGoalRequest(
          type: _selectedType,
          target: target,
          startDate: _startDate,
          endDate: DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            23,
            59,
            59,
          ),
        );

        await _goalService.createGoal(request);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Goal' : 'Add Goal')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isEditing ? 'Update your goal' : 'Set a new goal',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Goal Type',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _goalTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedType = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _targetLabel(),
                  hintText: _hintText(),
                  prefixIcon: const Icon(Icons.track_changes),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              _DateField(
                label: 'Start Date',
                value: _formatDate(_startDate),
                onTap: _isSaving ? null : _selectStartDate,
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'End Date',
                value: _formatDate(_endDate),
                onTap: _isSaving ? null : _selectEndDate,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isEditing ? 'Save Changes' : 'Create Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
        ),
        child: Text(value),
      ),
    );
  }
}
