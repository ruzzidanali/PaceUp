import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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

        final achievementsAfter =
            await _achievementService.getAchievements();

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
          backgroundColor: PaceUpColors.darkPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: PaceUpColors.electricGreen.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: PaceUpColors.electricGreen.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          PaceUpColors.electricGreen.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: PaceUpColors.electricGreen,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'ACHIEVEMENT UNLOCKED',
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.sectionTitle(
                    PaceUpColors.electricGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You just earned a new badge.',
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.body(
                    PaceUpColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 22),
                ...achievements.map(
                  (achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PaceUpColors.darkPanelSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: PaceUpColors.darkBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: PaceUpColors.electricGreen
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getAchievementIcon(achievement.icon),
                              color: PaceUpColors.electricGreen,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  achievement.name,
                                  style: PaceUpTypography.bodyMedium(
                                    PaceUpColors.darkText,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  achievement.description,
                                  style: PaceUpTypography.body(
                                    PaceUpColors.darkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: PaceUpColors.electricGreen,
                      foregroundColor: PaceUpColors.greenInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'KEEP MOVING',
                      style: PaceUpTypography.label(
                        PaceUpColors.greenInk,
                      ),
                    ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: PaceUpColors.electricGreen,
              onPrimary: PaceUpColors.greenInk,
              surface: PaceUpColors.darkPanel,
              onSurface: PaceUpColors.darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: PaceUpColors.electricGreen,
              onPrimary: PaceUpColors.greenInk,
              surface: PaceUpColors.darkPanel,
              onSurface: PaceUpColors.darkText,
            ),
          ),
          child: child!,
        );
      },
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
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
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

  String? _validateNumber(
    String? value, {
    bool allowZero = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    final number = double.tryParse(value);

    if (number == null || !number.isFinite) {
      return 'Enter a valid number';
    }

    if (allowZero ? number < 0 : number <= 0) {
      return allowZero
          ? 'Cannot be negative'
          : 'Must be greater than zero';
    }

    return null;
  }

  String? _validateInteger(
    String? value, {
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Required' : null;
    }

    final number = int.tryParse(value);

    if (number == null || number < 0) {
      return 'Enter a valid number';
    }

    return null;
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'Run':
        return Icons.directions_run_rounded;
      case 'Ride':
        return Icons.directions_bike_rounded;
      case 'Walk':
        return Icons.directions_walk_rounded;
      case 'Hike':
        return Icons.terrain_rounded;
      case 'Swim':
        return Icons.pool_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  String _activityLabel(String type) {
    switch (type) {
      case 'Run':
        return 'RUN';
      case 'Ride':
        return 'RIDE';
      case 'Walk':
        return 'WALK';
      case 'Hike':
        return 'HIKE';
      case 'Swim':
        return 'SWIM';
      default:
        return 'OTHER';
    }
  }

  Widget _buildActivityTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVITY TYPE',
          style: PaceUpTypography.sectionTitle(
            PaceUpColors.darkMuted,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _activityTypes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = _activityTypes[index];
              final selected = _selectedType == type;

              return GestureDetector(
                onTap: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _selectedType = type;
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 82,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? PaceUpColors.electricGreen
                        : PaceUpColors.darkPanel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? PaceUpColors.electricGreen
                          : PaceUpColors.darkBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _activityIcon(type),
                        size: 25,
                        color: selected
                            ? PaceUpColors.greenInk
                            : PaceUpColors.darkMuted,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _activityLabel(type),
                        textAlign: TextAlign.center,
                        style: PaceUpTypography.label(
                          selected
                              ? PaceUpColors.greenInk
                              : PaceUpColors.darkMuted,
                        ).copyWith(
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? suffix,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              size: 19,
              color: PaceUpColors.darkMuted,
            ),
      filled: true,
      fillColor: PaceUpColors.darkPanel,
      labelStyle: PaceUpTypography.body(
        PaceUpColors.darkMuted,
      ),
      suffixStyle: PaceUpTypography.bodyMedium(
        PaceUpColors.darkMuted,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: PaceUpColors.darkBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: PaceUpColors.electricGreen,
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: PaceUpColors.danger,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: PaceUpColors.danger,
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: PaceUpColors.electricGreen,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: PaceUpTypography.label(
                  PaceUpColors.darkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDurationFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _hoursController,
            keyboardType: TextInputType.number,
            style: PaceUpTypography.bodyMedium(
              PaceUpColors.darkText,
            ),
            decoration: _inputDecoration(
              label: 'Hours',
              suffix: 'H',
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
            style: PaceUpTypography.bodyMedium(
              PaceUpColors.darkText,
            ),
            decoration: _inputDecoration(
              label: 'Minutes',
              suffix: 'M',
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
            style: PaceUpTypography.bodyMedium(
              PaceUpColors.darkText,
            ),
            decoration: _inputDecoration(
              label: 'Seconds',
              suffix: 'S',
            ),
            validator: (value) =>
                _validateInteger(value, required: true),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      appBar: AppBar(
        backgroundColor: PaceUpColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'EDIT ACTIVITY' : 'ADD ACTIVITY',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.darkMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isEditing ? 'Update your session' : 'Log your session',
              style: PaceUpTypography.heading(
                PaceUpColors.darkText,
              ).copyWith(
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActivityTypeSelector(),
                const SizedBox(height: 28),
                Text(
                  'DISTANCE',
                  style: PaceUpTypography.sectionTitle(
                    PaceUpColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 10),
                _buildMetricCard(
                  label: 'TOTAL DISTANCE',
                  icon: Icons.straighten_rounded,
                  child: TextFormField(
                    controller: _distanceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: PaceUpTypography.largeMetric(
                      PaceUpColors.darkText,
                    ),
                    decoration: _inputDecoration(
                      label: 'Distance',
                      suffix: 'KM',
                    ),
                    validator: (value) =>
                        _validateNumber(value),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'DURATION',
                  style: PaceUpTypography.sectionTitle(
                    PaceUpColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 10),
                _buildMetricCard(
                  label: 'TOTAL TIME',
                  icon: Icons.timer_outlined,
                  child: _buildDurationFields(),
                ),
                const SizedBox(height: 22),
                Text(
                  'OPTIONAL DATA',
                  style: PaceUpTypography.sectionTitle(
                    PaceUpColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 10),
                _buildMetricCard(
                  label: 'ENERGY',
                  icon: Icons.local_fire_department_outlined,
                  child: TextFormField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    style: PaceUpTypography.largeMetric(
                      PaceUpColors.darkText,
                    ).copyWith(
                      fontSize: 36,
                    ),
                    decoration: _inputDecoration(
                      label: 'Calories',
                      suffix: 'KCAL',
                    ),
                    validator: (value) =>
                        _validateInteger(
                      value,
                      required: false,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'SESSION DATE',
                  style: PaceUpTypography.sectionTitle(
                    PaceUpColors.darkMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: PaceUpColors.darkPanel,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _isSaving ? null : _selectDateTime,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: PaceUpColors.darkBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: PaceUpColors.electricCyan
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: PaceUpColors.electricCyan,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STARTED AT',
                                  style: PaceUpTypography.label(
                                    PaceUpColors.darkMuted,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _formatDateTime(_startedAt),
                                  style: PaceUpTypography.bodyMedium(
                                    PaceUpColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: PaceUpColors.darkMuted,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveActivity,
                    style: FilledButton.styleFrom(
                      backgroundColor: PaceUpColors.electricGreen,
                      foregroundColor: PaceUpColors.greenInk,
                      disabledBackgroundColor:
                          PaceUpColors.darkPanelSecondary,
                      disabledForegroundColor:
                          PaceUpColors.darkMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _isSaving
                          ? const SizedBox(
                              key: ValueKey('saving'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: PaceUpColors.greenInk,
                              ),
                            )
                          : Row(
                              key: const ValueKey('idle'),
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isEditing
                                      ? Icons.check_rounded
                                      : Icons.add_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEditing
                                      ? 'SAVE CHANGES'
                                      : 'SAVE ACTIVITY',
                                  style: PaceUpTypography.label(
                                    PaceUpColors.greenInk,
                                  ).copyWith(
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
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