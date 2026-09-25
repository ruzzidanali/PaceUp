import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/challenge_models.dart';
import '../services/challenge_service.dart';

class AddChallengeScreen extends StatefulWidget {
  final ChallengeService challengeService;

  const AddChallengeScreen({
    super.key,
    required this.challengeService,
  });

  @override
  State<AddChallengeScreen> createState() => _AddChallengeScreenState();
}

class _AddChallengeScreenState extends State<AddChallengeScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();

  String _type = 'Distance';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
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

    setState(() {
      _startDate = DateTime(
        date.year,
        date.month,
        date.day,
      );

      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate.add(
          const Duration(days: 7),
        );
      }
    });
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate)
          ? _startDate
          : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
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

    setState(() {
      _endDate = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
      );
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final target = double.tryParse(
      _targetController.text.trim(),
    );

    if (name.isEmpty) {
      _showError('Challenge name is required.');
      return;
    }

    if (target == null || target <= 0) {
      _showError('Target must be greater than zero.');
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      _showError('End date must be after the start date.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.challengeService.createChallenge(
        CreateChallengeRequest(
          name: name,
          description: description.isEmpty
              ? null
              : description,
          type: _type,
          targetValue: target,
          startDate: _startDate,
          endDate: _endDate,
        ),
      );

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
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: PaceUpColors.danger,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _targetHint() {
    switch (_type) {
      case 'Distance':
        return 'Set the total distance participants need to reach';

      case 'Duration':
        return 'Set the total active duration in seconds';

      case 'Activities':
        return 'Set the number of activities participants need to complete';

      default:
        return 'Set the challenge target';
    }
  }

  String _targetUnit() {
    switch (_type) {
      case 'Distance':
        return 'KM';

      case 'Duration':
        return 'SECONDS';

      case 'Activities':
        return 'ACTIVITIES';

      default:
        return 'VALUE';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Distance':
        return Icons.route_rounded;

      case 'Duration':
        return Icons.timer_outlined;

      case 'Activities':
        return Icons.directions_run_rounded;

      default:
        return Icons.emoji_events_rounded;
    }
  }

  String _typeTitle(String type) {
    switch (type) {
      case 'Distance':
        return 'DISTANCE';

      case 'Duration':
        return 'DURATION';

      case 'Activities':
        return 'ACTIVITIES';

      default:
        return type.toUpperCase();
    }
  }

  String _typeSubtitle(String type) {
    switch (type) {
      case 'Distance':
        return 'Compete by total kilometres';

      case 'Duration':
        return 'Compete by total active time';

      case 'Activities':
        return 'Compete by completed activities';

      default:
        return 'Set your own target';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      appBar: AppBar(
        backgroundColor: PaceUpColors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        title: Text(
          'CREATE CHALLENGE',
          style: PaceUpTypography.sectionTitle(
            PaceUpColors.electricGreen,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroIntro(),
              const SizedBox(height: 30),

              _buildSectionLabel('CHALLENGE DETAILS'),
              const SizedBox(height: 12),
              _buildNameField(),
              const SizedBox(height: 12),
              _buildDescriptionField(),

              const SizedBox(height: 30),
              _buildSectionLabel('CHALLENGE TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(),

              const SizedBox(height: 30),
              _buildSectionLabel('TARGET'),
              const SizedBox(height: 12),
              _buildTargetCard(),

              const SizedBox(height: 30),
              _buildSectionLabel('CHALLENGE PERIOD'),
              const SizedBox(height: 12),
              _buildDateCard(),

              const SizedBox(height: 30),
              _buildPreview(),

              const SizedBox(height: 28),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PaceUpColors.electricGreen.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: PaceUpColors.electricGreen.withValues(alpha: 0.035),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: PaceUpColors.electricGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PaceUpColors.electricGreen.withValues(alpha: 0.24),
              ),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: PaceUpColors.electricGreen,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUILD THE CHALLENGE',
                  style: PaceUpTypography.label(
                    PaceUpColors.electricGreen,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Set the target.',
                  style: PaceUpTypography.heading(
                    PaceUpColors.darkText,
                  ).copyWith(
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a challenge and push your friends to beat it.',
                  style: PaceUpTypography.body(
                    PaceUpColors.darkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: PaceUpTypography.sectionTitle(
        PaceUpColors.electricGreen,
      ),
    );
  }

  Widget _buildNameField() {
    return _PremiumTextField(
      controller: _nameController,
      label: 'CHALLENGE NAME',
      hint: 'e.g. Weekend Warrior',
      icon: Icons.emoji_events_outlined,
      enabled: !_isLoading,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildDescriptionField() {
    return _PremiumTextField(
      controller: _descriptionController,
      label: 'DESCRIPTION',
      hint: 'What is the challenge about?',
      icon: Icons.notes_rounded,
      enabled: !_isLoading,
      textInputAction: TextInputAction.next,
      maxLines: 3,
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: [
        for (final type in const [
          'Distance',
          'Duration',
          'Activities',
        ]) ...[
          _ChallengeTypeOption(
            title: _typeTitle(type),
            subtitle: _typeSubtitle(type),
            icon: _typeIcon(type),
            selected: _type == type,
            enabled: !_isLoading,
            onTap: () {
              setState(() {
                _type = type;
              });
            },
          ),
          if (type != 'Activities')
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildTargetCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PaceUpColors.electricGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag_outlined,
                  color: PaceUpColors.electricGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'TARGET VALUE',
                  style: PaceUpTypography.label(
                    PaceUpColors.darkMuted,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _targetUnit(),
                  key: ValueKey(_targetUnit()),
                  style: PaceUpTypography.label(
                    PaceUpColors.electricGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _targetController,
            enabled: !_isLoading,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              setState(() {});
            },
            style: PaceUpTypography.largeMetric(
              PaceUpColors.darkText,
            ).copyWith(
              fontSize: 42,
            ),
            cursorColor: PaceUpColors.electricGreen,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: PaceUpTypography.largeMetric(
                PaceUpColors.darkMuted,
              ).copyWith(
                fontSize: 42,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _targetHint(),
            style: PaceUpTypography.body(
              PaceUpColors.darkMuted,
            ).copyWith(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        children: [
          _DateRow(
            icon: Icons.calendar_today_outlined,
            label: 'START DATE',
            value: _formatDate(_startDate),
            enabled: !_isLoading,
            onTap: _selectStartDate,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 58),
            child: Divider(
              height: 1,
              color: PaceUpColors.darkBorder,
            ),
          ),
          _DateRow(
            icon: Icons.event_outlined,
            label: 'END DATE',
            value: _formatDate(_endDate),
            enabled: !_isLoading,
            onTap: _selectEndDate,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final target = double.tryParse(
      _targetController.text.trim(),
    );

    final targetText = target == null || target <= 0
        ? 'SET TARGET'
        : '${target.toStringAsFixed(
            _type == 'Activities' ? 0 : 1,
          )} ${_targetUnit()}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanelSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PaceUpColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                color: PaceUpColors.electricCyan,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                'CHALLENGE PREVIEW',
                style: PaceUpTypography.sectionTitle(
                  PaceUpColors.electricCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _nameController.text.trim().isEmpty
                ? 'YOUR CHALLENGE'
                : _nameController.text.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PaceUpTypography.heading(
              PaceUpColors.darkText,
            ).copyWith(
              fontSize: 23,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _descriptionController.text.trim().isEmpty
                ? 'Ready to challenge your friends.'
                : _descriptionController.text.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PaceUpTypography.body(
              PaceUpColors.darkMuted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PreviewMetric(
                  label: 'TARGET',
                  value: targetText,
                  accent: PaceUpColors.electricGreen,
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: PaceUpColors.darkBorder,
              ),
              Expanded(
                child: _PreviewMetric(
                  label: 'PERIOD',
                  value:
                      '${_formatDate(_startDate)} → ${_formatDate(_endDate)}',
                  accent: PaceUpColors.electricCyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isLoading ? null : _create,
        style: FilledButton.styleFrom(
          backgroundColor: PaceUpColors.electricGreen,
          foregroundColor: PaceUpColors.greenInk,
          disabledBackgroundColor:
              PaceUpColors.electricGreen.withValues(alpha: 0.35),
          disabledForegroundColor:
              PaceUpColors.greenInk.withValues(alpha: 0.60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PaceUpColors.greenInk,
                ),
              )
            : const Icon(Icons.bolt_rounded),
        label: Text(
          _isLoading ? 'CREATING...' : 'CREATE CHALLENGE',
          style: PaceUpTypography.label(
            PaceUpColors.greenInk,
          ),
        ),
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final TextInputAction textInputAction;
  final int maxLines;

  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.textInputAction,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      textInputAction: textInputAction,
      style: PaceUpTypography.body(
        PaceUpColors.darkText,
      ),
      cursorColor: PaceUpColors.electricGreen,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: PaceUpTypography.label(
          PaceUpColors.darkMuted,
        ),
        hintText: hint,
        hintStyle: PaceUpTypography.body(
          PaceUpColors.darkMuted,
        ),
        prefixIcon: Icon(
          icon,
          color: PaceUpColors.darkMuted,
          size: 21,
        ),
        filled: true,
        fillColor: PaceUpColors.darkPanel,
        alignLabelWithHint: maxLines > 1,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: PaceUpColors.darkBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: PaceUpColors.electricGreen,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: PaceUpColors.darkBorder,
          ),
        ),
      ),
    );
  }
}

class _ChallengeTypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ChallengeTypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaceUpColors.electricGreen;

    return Material(
      color: PaceUpColors.darkPanel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.55)
                  : PaceUpColors.darkBorder,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.05),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.12)
                      : PaceUpColors.darkMuted.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? accent
                      : PaceUpColors.darkMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PaceUpTypography.label(
                        selected
                            ? accent
                            : PaceUpColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: PaceUpTypography.body(
                        PaceUpColors.darkMuted,
                      ).copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('selected'),
                        color: PaceUpColors.electricGreen,
                        size: 21,
                      )
                    : const Icon(
                        Icons.circle_outlined,
                        key: ValueKey('unselected'),
                        color: PaceUpColors.darkMuted,
                        size: 21,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 16,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: PaceUpColors.electricCyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: PaceUpColors.electricCyan,
                size: 20,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: PaceUpTypography.label(
                      PaceUpColors.darkMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: PaceUpTypography.bodyMedium(
                      PaceUpColors.darkText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: PaceUpColors.darkMuted,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _PreviewMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: PaceUpTypography.label(
              PaceUpColors.darkMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PaceUpTypography.bodyMedium(
              accent,
            ).copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}