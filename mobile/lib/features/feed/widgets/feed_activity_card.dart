import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../kudos/services/kudos_service.dart';
import '../models/feed_models.dart';

class FeedActivityCard extends StatefulWidget {
  final FeedActivityResponse activity;
  final String? currentUserId;
  final VoidCallback? onTap;

  const FeedActivityCard({
    super.key,
    required this.activity,
    this.currentUserId,
    this.onTap,
  });

  @override
  State<FeedActivityCard> createState() => _FeedActivityCardState();
}

class _FeedActivityCardState extends State<FeedActivityCard> {
  final KudosService _kudosService = KudosService();

  int _kudosCount = 0;
  bool _hasGivenKudos = false;
  bool _isLoadingKudos = true;
  bool _isUpdatingKudos = false;

  @override
  void initState() {
    super.initState();
    _loadKudos();
  }

  Future<void> _loadKudos() async {
    try {
      final response = await _kudosService.getKudos(
        widget.activity.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _kudosCount = response.kudosCount;
        _hasGivenKudos = response.hasGivenKudos;
        _isLoadingKudos = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingKudos = false;
      });
    }
  }

  Future<void> _toggleKudos() async {
    if (_isUpdatingKudos || _isLoadingKudos) {
      return;
    }

    final previousCount = _kudosCount;
    final previousState = _hasGivenKudos;

    setState(() {
      _isUpdatingKudos = true;

      if (_hasGivenKudos) {
        _kudosCount--;
        _hasGivenKudos = false;
      } else {
        _kudosCount++;
        _hasGivenKudos = true;
      }
    });

    try {
      final response = previousState
          ? await _kudosService.removeKudos(
              widget.activity.id,
            )
          : await _kudosService.giveKudos(
              widget.activity.id,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _kudosCount = response.kudosCount;
        _hasGivenKudos = response.hasGivenKudos;
        _isUpdatingKudos = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _kudosCount = previousCount;
        _hasGivenKudos = previousState;
        _isUpdatingKudos = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update kudos. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData _activityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'run':
      case 'running':
        return Icons.directions_run_rounded;

      case 'walk':
      case 'walking':
        return Icons.directions_walk_rounded;

      case 'cycle':
      case 'cycling':
      case 'bike':
      case 'biking':
        return Icons.directions_bike_rounded;

      case 'hike':
      case 'hiking':
        return Icons.hiking_rounded;

      case 'swim':
      case 'swimming':
        return Icons.pool_rounded;

      default:
        return Icons.fitness_center_rounded;
    }
  }

  String _formatActivityType(String type) {
    if (type.isEmpty) {
      return 'Activity';
    }

    return type[0].toUpperCase() +
        type.substring(1).toLowerCase();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  String _formatTime(DateTime date) {
    final difference = DateTime.now().difference(
      date.toLocal(),
    );

    if (difference.inMinutes < 1) {
      return 'JUST NOW';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}M AGO';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}H AGO';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}D AGO';
    }

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  @override
  void dispose() {
    _kudosService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark
        ? PaceUpColors.darkText
        : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(2),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildUserHeader(
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 18),
              _buildActivityHeader(
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 18),
              _buildMetrics(
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 17),
              Container(
                height: 1,
                color: borderColor.withValues(
                  alpha: 0.65,
                ),
              ),
              _buildKudosButton(
                textColor: textColor,
                mutedColor: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Row(
      children: [
        _ProfileAvatar(
          displayName: widget.activity.displayName,
          imageUrl: widget.activity.profileImageUrl,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                widget.activity.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PaceUpTypography.bodyMedium(
                  textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${widget.activity.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PaceUpTypography.body(
                  mutedColor,
                ).copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Text(
          _formatTime(widget.activity.createdAt),
          style: PaceUpTypography.label(
            mutedColor,
          ).copyWith(
            fontSize: 8,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityHeader({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: PaceUpColors.electricGreen
                .withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _activityIcon(widget.activity.type),
            color: PaceUpColors.electricGreen,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVITY',
                style: PaceUpTypography.label(
                  mutedColor,
                ).copyWith(
                  fontSize: 8,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatActivityType(
                  widget.activity.type,
                ).toUpperCase(),
                style: PaceUpTypography.heading(
                  textColor,
                ).copyWith(
                  fontSize: 23,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: mutedColor.withValues(alpha: 0.55),
          size: 13,
        ),
      ],
    );
  }

  Widget _buildMetrics({
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    final metrics = <_FeedMetricData>[
      _FeedMetricData(
        label: 'DISTANCE',
        value:
            widget.activity.distance.toStringAsFixed(1),
        unit: 'KM',
        accent: PaceUpColors.electricGreen,
      ),
      _FeedMetricData(
        label: 'DURATION',
        value: _formatDuration(
          widget.activity.durationSeconds,
        ),
        unit: '',
        accent: PaceUpColors.electricCyan,
      ),
    ];

    if (widget.activity.calories != null) {
      metrics.add(
        _FeedMetricData(
          label: 'CALORIES',
          value: '${widget.activity.calories}',
          unit: 'KCAL',
          accent: PaceUpColors.electricGreen,
        ),
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          Expanded(
            child: _Metric(
              data: metrics[i],
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          ),
          if (i < metrics.length - 1)
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              color: borderColor.withValues(
                alpha: 0.7,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildKudosButton({
    required Color textColor,
    required Color mutedColor,
  }) {
    final isOwnActivity =
        widget.currentUserId != null &&
        widget.activity.userId == widget.currentUserId;

    if (isOwnActivity) {
      return const SizedBox(height: 40);
    }

    final accent = _hasGivenKudos
        ? PaceUpColors.electricGreen
        : mutedColor;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          AnimatedScale(
            scale: _hasGivenKudos ? 1.08 : 1.0,
            duration: const Duration(
              milliseconds: 150,
            ),
            child: IconButton(
              onPressed:
                  _isLoadingKudos ? null : _toggleKudos,
              splashRadius: 20,
              padding: EdgeInsets.zero,
              icon: Icon(
                _hasGivenKudos
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: accent,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$_kudosCount',
            style: PaceUpTypography.bodyMedium(
              textColor,
            ).copyWith(
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'KUDOS',
            style: PaceUpTypography.label(
              mutedColor,
            ).copyWith(
              fontSize: 8,
              letterSpacing: 1.1,
            ),
          ),
          if (_isUpdatingKudos) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: PaceUpColors.electricGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String displayName;
  final String? imageUrl;

  const _ProfileAvatar({
    required this.displayName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim()[0].toUpperCase();

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final accent = PaceUpColors.electricGreen;

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: accent.withValues(alpha: 0.28),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: PaceUpTypography.bodyMedium(
            accent,
          ),
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return Container(
              color: isDark
                  ? PaceUpColors.darkPanelSecondary
                  : PaceUpColors.lightPanelSecondary,
              alignment: Alignment.center,
              child: Text(
                initial,
                style: PaceUpTypography.bodyMedium(
                  accent,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeedMetricData {
  final String label;
  final String value;
  final String unit;
  final Color accent;

  const _FeedMetricData({
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
  });
}

class _Metric extends StatelessWidget {
  final _FeedMetricData data;
  final Color textColor;
  final Color mutedColor;

  const _Metric({
    required this.data,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: data.value,
                style: PaceUpTypography.bodyMedium(
                  data.accent,
                ).copyWith(
                  fontSize: 16,
                ),
              ),
              if (data.unit.isNotEmpty)
                TextSpan(
                  text: ' ${data.unit}',
                  style: PaceUpTypography.label(
                    mutedColor,
                  ).copyWith(
                    fontSize: 7,
                    letterSpacing: 0.8,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.label,
          style: PaceUpTypography.label(
            mutedColor,
          ).copyWith(
            fontSize: 8,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}