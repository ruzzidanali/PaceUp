import 'package:flutter/material.dart';

import '../../achievements/models/achievement_models.dart';
import '../../achievements/services/achievement_service.dart';
import '../models/activity_models.dart';
import '../services/activity_service.dart';

class AddActivityScreen extends StatefulWidget {
  final ActivityResponse? activity;

  const AddActivityScreen({super.key, this.activity});

  bool get isEditing => activity != null;

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  late final ActivityService _activityService;
  late final AchievementService _achievementService;

  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _caloriesController = TextEditingController();

  String _selectedType = 'Run';
  DateTime _startedAt = DateTime.now();
  bool _isSaving = false;

  static const _activityTypes = [
    'Run',
    'Ride',
    'Walk',
    'Hike',
    'Swim',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService();
    _achievementService = AchievementService();

    final activity = widget.activity;

    if (activity != null) {
      _selectedType = activity.type;
      _startedAt = activity.startedAt;

      _distanceController.text = activity.distance.toString();

      final hours = activity.durationSeconds ~/ 3600;
      final minutes = (activity.durationSeconds % 3600) ~/ 60;
      final seconds = activity.durationSeconds % 60;

      _hoursController.text = hours.toString();
      _minutesController.text = minutes.toString();
      _secondsController.text = seconds.toString();

      if (activity.calories != null) {
        _caloriesController.text = activity.calories.toString();
      }
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _caloriesController.dispose();
    _activityService.dispose();
    super.dispose();
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hours = int.parse(_hoursController.text);
    final minutes = int.parse(_minutesController.text);
    final seconds = int.parse(_secondsController.text);

    final durationSeconds = (hours * 3600) + (minutes * 60) + seconds;

    if (durationSeconds <= 0) {
      _showError('Duration must be greater than zero.');
      return;
    }

    final caloriesText = _caloriesController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      List<AchievementResponse> achievementsBefore = [];

      if (widget.activity == null) {
        achievementsBefore = await _achievementService.getAchievements();

        final request = CreateActivityRequest(
          type: _selectedType,
          distance: double.parse(_distanceController.text),
          durationSeconds: durationSeconds,
          calories: caloriesText.isEmpty ? null : int.parse(caloriesText),
          startedAt: _startedAt,
        );

        await _activityService.createActivity(request);

        final achievementsAfter = await _achievementService.getAchievements();

        final newlyUnlocked = _achievementService.findNewlyUnlocked(
          achievementsBefore,
          achievementsAfter,
        );

        if (!mounted) {
          return;
        }

        if (newlyUnlocked.isNotEmpty) {
          await _showAchievementUnlockedDialog(newlyUnlocked);
        }

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop(true);
      } else {
        final request = UpdateActivityRequest(
          type: _selectedType,
          distance: double.parse(_distanceController.text),
          durationSeconds: durationSeconds,
          calories: caloriesText.isEmpty ? null : int.parse(caloriesText),
          startedAt: _startedAt,
        );

        final updated = await _activityService.updateActivity(
          widget.activity!.id,
          request,
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop(updated);
      }
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

  Future<void> _showAchievementUnlockedDialog(
    List<AchievementResponse> achievements,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, size: 52),
                const SizedBox(height: 16),
                const Text(
                  'Achievement Unlocked!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ...achievements.map(
                  (achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              _getAchievementIcon(achievement.icon),
                              size: 42,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          achievement.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          achievement.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Awesome!'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getAchievementIcon(String icon) {
    switch (icon) {
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'straighten':
        return Icons.straighten_rounded;
      case 'timer':
        return Icons.timer_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
    );

    if (time == null) {
      return;
    }

    setState(() {
      _startedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final date = dateTime.toLocal();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String? _validateNumber(String? value, {bool allowZero = true}) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    final number = double.tryParse(value);

    if (number == null || !number.isFinite) {
      return 'Enter a valid number';
    }

    if (allowZero ? number < 0 : number <= 0) {
      return allowZero ? 'Cannot be negative' : 'Must be greater than zero';
    }

    return null;
  }

  String? _validateInteger(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Required' : null;
    }

    final number = int.tryParse(value);

    if (number == null || number < 0) {
      return 'Enter a valid number';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Activity' : 'Add Activity'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Activity Type',
                    prefixIcon: Icon(Icons.directions_run_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: _activityTypes
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
                TextFormField(
                  controller: _distanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Distance (km)',
                    prefixIcon: Icon(Icons.straighten_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateNumber(value),
                ),
                const SizedBox(height: 16),
                Text(
                  'Duration',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hoursController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hours',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _validateInteger(value, required: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _minutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minutes',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _validateInteger(value, required: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _secondsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Seconds',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _validateInteger(value, required: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories (optional)',
                    prefixIcon: Icon(Icons.local_fire_department_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _validateInteger(value, required: false),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Started At'),
                  subtitle: Text(_formatDateTime(_startedAt)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _isSaving ? null : _selectDateTime,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _saveActivity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.isEditing ? 'Save Changes' : 'Save Activity',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
