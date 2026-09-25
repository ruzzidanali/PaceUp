import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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

  static const _goalTypes = [
    'Distance',
    'Duration',
    'Calories',
    'Activities',
  ];

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

      _startDate = DateTime(
        now.year,
        now.month,
        now.day,
      );

      _endDate = _startDate.add(
        const Duration(days: 6),
      );
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
        return 'TARGET DISTANCE';

      case 'Duration':
        return 'TARGET DURATION';

      case 'Calories':
        return 'TARGET CALORIES';

      case 'Activities':
        return 'TARGET ACTIVITIES';

      default:
        return 'TARGET';
    }
  }

  String _targetUnit() {
    switch (_selectedType) {
      case 'Distance':
        return 'KM';

      case 'Duration':
        return 'SECONDS';

      case 'Calories':
        return 'KCAL';

      case 'Activities':
        return 'SESSIONS';

      default:
        return '';
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

  String _goalDescription() {
    switch (_selectedType) {
      case 'Distance':
        return 'Set a distance target to build your weekly mileage.';

      case 'Duration':
        return 'Set a total training time target for your period.';

      case 'Calories':
        return 'Set an energy expenditure target to stay active.';

      case 'Activities':
        return 'Set how many activities you want to complete.';

      default:
        return 'Set a target and keep moving.';
    }
  }

  IconData _goalIcon(String type) {
    switch (type) {
      case 'Distance':
        return Icons.straighten_rounded;

      case 'Duration':
        return Icons.timer_outlined;

      case 'Calories':
        return Icons.local_fire_department_outlined;

      case 'Activities':
        return Icons.directions_run_rounded;

      default:
        return Icons.flag_outlined;
    }
  }

  Color _goalAccent(String type) {
    switch (type) {
      case 'Distance':
        return PaceUpColors.electricGreen;

      case 'Duration':
        return PaceUpColors.electricCyan;

      case 'Calories':
        return PaceUpColors.danger;

      case 'Activities':
        return PaceUpColors.electricGreen;

      default:
        return PaceUpColors.electricCyan;
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return _datePickerTheme(child);
      },
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
      initialDate:
          _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return _datePickerTheme(child);
      },
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = date;
    });
  }

  Widget _datePickerTheme(Widget? child) {
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

        await _goalService.updateGoal(
          widget.goal!.id,
          request,
        );
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

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
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
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  Widget _buildGoalTypeSelector() {
    final accent = _goalAccent(_selectedType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GOAL TYPE',
          style: PaceUpTypography.sectionTitle(
            PaceUpColors.darkMuted,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _goalTypes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = _goalTypes[index];
              final selected = _selectedType == type;
              final typeAccent = _goalAccent(type);

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
                  width: 92,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? typeAccent
                        : PaceUpColors.darkPanel,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: selected
                          ? typeAccent
                          : PaceUpColors.darkBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _goalIcon(type),
                        size: 25,
                        color: selected
                            ? (typeAccent == PaceUpColors.danger
                                ? Colors.white
                                : PaceUpColors.greenInk)
                            : typeAccent,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        type.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: PaceUpTypography.label(
                          selected
                              ? (typeAccent == PaceUpColors.danger
                                  ? Colors.white
                                  : PaceUpColors.greenInk)
                              : PaceUpColors.darkMuted,
                        ).copyWith(
                          fontSize: 8,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _goalDescription(),
          style: PaceUpTypography.body(
            PaceUpColors.darkMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _goalIcon(_selectedType),
              size: 14,
              color: accent,
            ),
            const SizedBox(width: 6),
            Text(
              'TRACKING IN ${_targetUnit()}',
              style: PaceUpTypography.label(
                accent,
              ).copyWith(
                fontSize: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetField() {
    final accent = _goalAccent(_selectedType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _targetLabel(),
            style: PaceUpTypography.sectionTitle(
              PaceUpColors.darkMuted,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _targetController,
            enabled: !_isSaving,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) {
              setState(() {});
            },
            style: PaceUpTypography.heroMetric(
              PaceUpColors.darkText,
            ).copyWith(
              fontSize: 52,
            ),
            cursorColor: accent,
            decoration: InputDecoration(
              hintText: _hintText(),
              hintStyle: PaceUpTypography.heroMetric(
                PaceUpColors.darkMuted.withValues(alpha: 0.30),
              ).copyWith(
                fontSize: 52,
              ),
              suffixText: _targetUnit(),
              suffixStyle: PaceUpTypography.label(
                accent,
              ).copyWith(
                fontSize: 10,
                letterSpacing: 1.1,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required DateTime date,
    required VoidCallback? onTap,
    required IconData icon,
    required Color accent,
  }) {
    return Expanded(
      child: Material(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: PaceUpColors.darkBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: accent,
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: PaceUpTypography.label(
                    PaceUpColors.darkMuted,
                  ).copyWith(
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDate(date),
                  style: PaceUpTypography.bodyMedium(
                    PaceUpColors.darkText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GOAL PERIOD',
          style: PaceUpTypography.sectionTitle(
            PaceUpColors.darkMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildDateCard(
              label: 'START DATE',
              date: _startDate,
              onTap: _isSaving ? null : _selectStartDate,
              icon: Icons.play_circle_outline_rounded,
              accent: PaceUpColors.electricGreen,
            ),
            const SizedBox(width: 10),
            _buildDateCard(
              label: 'END DATE',
              date: _endDate,
              onTap: _isSaving ? null : _selectEndDate,
              icon: Icons.flag_outlined,
              accent: PaceUpColors.electricCyan,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final accent = _goalAccent(_selectedType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _goalIcon(_selectedType),
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TARGET PREVIEW',
                  style: PaceUpTypography.label(
                    accent,
                  ).copyWith(
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _targetController.text.trim().isEmpty
                      ? 'Enter your target'
                      : '${_targetController.text.trim()} ${_targetUnit()}',
                  style: PaceUpTypography.bodyMedium(
                    PaceUpColors.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              isEditing ? 'EDIT GOAL' : 'NEW GOAL',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.darkMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isEditing ? 'Update your target' : 'Set your target',
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoalTypeSelector(),
              const SizedBox(height: 28),
              _buildTargetField(),
              const SizedBox(height: 22),
              _buildPreview(),
              const SizedBox(height: 26),
              _buildDateRange(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
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
                                    : Icons.flag_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEditing
                                    ? 'SAVE CHANGES'
                                    : 'CREATE GOAL',
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
    );
  }
}