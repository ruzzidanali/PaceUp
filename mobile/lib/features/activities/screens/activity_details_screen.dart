import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/services/auth_service.dart';
import '../../comments/widgets/comments_sheet.dart';
import '../../kudos/models/kudos_models.dart';
import '../../kudos/services/kudos_service.dart';
import '../../tracking/models/route_models.dart';
import '../../tracking/services/route_service.dart';
import '../models/activity_models.dart';
import '../services/activity_service.dart';
import 'add_activity_screen.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final ActivityResponse activity;

  const ActivityDetailsScreen({super.key, required this.activity});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  late final ActivityService _activityService;
  late final KudosService _kudosService;
  late final RouteService _routeService;

  late ActivityResponse _activity;

  KudosResponse? _kudos;
  RouteResponse? _route;
  String? _currentUserId;

  bool _isDeleting = false;
  bool _isLoadingKudos = true;
  bool _isUpdatingKudos = false;
  bool _isOwnActivity = false;

  bool _isLoadingRoute = true;
  String? _routeError;

  @override
  void initState() {
    super.initState();

    _activity = widget.activity;

    _activityService = ActivityService();
    _kudosService = KudosService();
    _routeService = RouteService();

    _loadActivityState();
    _loadRoute();
  }

  @override
  void dispose() {
    _activityService.dispose();
    _kudosService.dispose();
    _routeService.dispose();
    super.dispose();
  }

  Future<void> _loadActivityState() async {
    try {
      final authService = AuthService();

      try {
        final currentUser = await authService.getCurrentUser();

        if (!mounted) {
          return;
        }

        setState(() {
          _currentUserId = currentUser.id;
          _isOwnActivity = currentUser.id == _activity.userId;
        });
      } finally {
        authService.dispose();
      }

      if (_isOwnActivity) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoadingKudos = false;
        });

        return;
      }

      final kudos = await _kudosService.getKudos(_activity.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _kudos = kudos;
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

  Future<void> _loadRoute() async {
    try {
      final route = await _routeService.getRoute(_activity.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _route = route;
        _isLoadingRoute = false;
        _routeError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingRoute = false;
        _routeError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _editActivity() async {
    final updated = await Navigator.of(context).push<ActivityResponse>(
      MaterialPageRoute(builder: (_) => AddActivityScreen(activity: _activity)),
    );

    if (updated != null && mounted) {
      setState(() {
        _activity = updated;
      });
    }
  }

  Future<void> _deleteActivity() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final secondaryColor = isDark
        ? PaceUpColors.darkPanelSecondary
        : PaceUpColors.lightPanelSecondary;

    final textColor = isDark ? PaceUpColors.darkText : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: PaceUpColors.danger.withValues(alpha: 0.28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: PaceUpColors.danger.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: PaceUpColors.danger.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: PaceUpColors.danger,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'DELETE ACTIVITY',
                        style: PaceUpTypography.heading(textColor)
                            .copyWith(fontSize: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Are you sure you want to delete this activity?',
                  style: PaceUpTypography.bodyMedium(textColor),
                ),
                const SizedBox(height: 7),
                Text(
                  'This action cannot be undone. Your activity '
                  'data and recorded route will be permanently removed.',
                  style: PaceUpTypography.body(mutedColor),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _activityIcon(_activity.type),
                        color: PaceUpColors.danger,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activity.type.toUpperCase(),
                              style: PaceUpTypography.label(textColor),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_activity.distance.toStringAsFixed(2)} km · '
                              '${_formatDuration(_activity.durationSeconds)}',
                              style: PaceUpTypography.body(mutedColor)
                                  .copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(
                              color: isDark
                                  ? PaceUpColors.darkBorder
                                  : PaceUpColors.lightBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: Text(
                            'CANCEL',
                            style: PaceUpTypography.label(textColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: PaceUpColors.danger,
                            foregroundColor: PaceUpColors.darkText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: Text(
                            'DELETE',
                            style: PaceUpTypography.label(
                              PaceUpColors.darkText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _activityService.deleteActivity(_activity.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleKudos() async {
    final kudos = _kudos;

    if (kudos == null || _isUpdatingKudos) {
      return;
    }

    setState(() {
      _isUpdatingKudos = true;
    });

    try {
      final updated = kudos.hasGivenKudos
          ? await _kudosService.removeKudos(_activity.id)
          : await _kudosService.giveKudos(_activity.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _kudos = updated;
        _isUpdatingKudos = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingKudos = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${seconds}s';
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} · '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatPace() {
    if (_activity.distance <= 0 || _activity.durationSeconds <= 0) {
      return '--';
    }

    final secondsPerKm = _activity.durationSeconds / _activity.distance;

    final totalSeconds = secondsPerKm.round();

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSpeed() {
    if (_activity.distance <= 0 || _activity.durationSeconds <= 0) {
      return '--';
    }

    final speed = _activity.distance * 3600 / _activity.durationSeconds;

    return speed.toStringAsFixed(1);
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
        return Icons.hiking_rounded;
      case 'Swim':
        return Icons.pool_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  Color _activityAccent() {
    switch (_activity.type) {
      case 'Ride':
      case 'Hike':
      case 'Swim':
        return PaceUpColors.electricCyan;
      default:
        return PaceUpColors.electricGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? PaceUpColors.darkBackground
        : PaceUpColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? PaceUpColors.darkText : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Row(
        children: [
          _HeaderButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pop(),
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVITY',
                  style: PaceUpTypography.sectionTitle(
                    PaceUpColors.electricGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _activity.type,
                  style: PaceUpTypography.heading(textColor)
                      .copyWith(fontSize: 22),
                ),
              ],
            ),
          ),
          if (_isOwnActivity) ...[
            _HeaderButton(
              icon: Icons.edit_outlined,
              onPressed: _isDeleting ? null : _editActivity,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(width: 8),
            _HeaderButton(
              icon: Icons.delete_outline_rounded,
              onPressed: _isDeleting ? null : _deleteActivity,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? PaceUpColors.darkText : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
      children: [
        _buildHeroCard(textColor: textColor, mutedColor: mutedColor),
        const SizedBox(height: 18),
        _buildPerformanceSection(textColor: textColor, mutedColor: mutedColor),
        const SizedBox(height: 28),
        _buildSectionTitle('ROUTE', mutedColor),
        const SizedBox(height: 12),
        _buildRouteMap(textColor: textColor, mutedColor: mutedColor),
        if (!_isOwnActivity) ...[
          const SizedBox(height: 28),
          _buildSocialSection(textColor: textColor, mutedColor: mutedColor),
        ],
        if (_isOwnActivity) ...[
          const SizedBox(height: 28),
          _buildOwnerActions(textColor: textColor, mutedColor: mutedColor),
        ],
      ],
    );
  }

  Widget _buildHeroCard({required Color textColor, required Color mutedColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    final accent = _activityAccent();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.30)),
                ),
                child: Icon(
                  _activityIcon(_activity.type),
                  color: accent,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activity.type.toUpperCase(),
                      style: PaceUpTypography.sectionTitle(accent),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatDateTime(_activity.startedAt),
                      style: PaceUpTypography.body(mutedColor)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('DISTANCE', style: PaceUpTypography.label(mutedColor)),
          const SizedBox(height: 3),
          Text(
            '${_activity.distance.toStringAsFixed(2)} km',
            style: PaceUpTypography.heroMetric(accent).copyWith(fontSize: 58),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 15, color: mutedColor),
              const SizedBox(width: 6),
              Text(
                _formatDuration(_activity.durationSeconds),
                style: PaceUpTypography.bodyMedium(mutedColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection({
    required Color textColor,
    required Color mutedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PERFORMANCE', mutedColor),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PerformanceMetric(
                      icon: Icons.speed_rounded,
                      value: _formatPace(),
                      unit: '/KM',
                      label: 'PACE',
                      accent: PaceUpColors.electricGreen,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                  ),
                  _VerticalDivider(color: borderColor),
                  Expanded(
                    child: _PerformanceMetric(
                      icon: Icons.bolt_rounded,
                      value: _formatSpeed(),
                      unit: 'KM/H',
                      label: 'SPEED',
                      accent: PaceUpColors.electricCyan,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                  ),
                ],
              ),
              Container(height: 1, color: borderColor),
              Row(
                children: [
                  Expanded(
                    child: _PerformanceMetric(
                      icon: Icons.timer_outlined,
                      value: _formatDuration(_activity.durationSeconds),
                      unit: '',
                      label: 'DURATION',
                      accent: PaceUpColors.electricCyan,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                  ),
                  _VerticalDivider(color: borderColor),
                  Expanded(
                    child: _PerformanceMetric(
                      icon: Icons.local_fire_department_rounded,
                      value: _activity.calories == null
                          ? '—'
                          : '${_activity.calories}',
                      unit: _activity.calories == null ? '' : 'KCAL',
                      label: 'CALORIES',
                      accent: PaceUpColors.electricGreen,
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color mutedColor) {
    return Text(
      title,
      style: PaceUpTypography.sectionTitle(PaceUpColors.electricGreen),
    );
  }

  Widget _buildRouteMap({required Color textColor, required Color mutedColor}) {
    if (_isLoadingRoute) {
      return _RoutePlaceholder(
        text: 'LOADING ROUTE',
        icon: Icons.route_rounded,
        mutedColor: mutedColor,
      );
    }

    if (_routeError != null) {
      return _RoutePlaceholder(
        text: 'UNABLE TO LOAD ROUTE',
        subtitle: _routeError,
        icon: Icons.map_outlined,
        mutedColor: mutedColor,
      );
    }

    final route = _route;

    if (route == null || route.points.isEmpty) {
      return _RoutePlaceholder(
        text: 'NO ROUTE RECORDED',
        subtitle: 'GPS route data is not available for this activity.',
        icon: Icons.route_outlined,
        mutedColor: mutedColor,
      );
    }

    final points = route.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    return Container(
      height: 340,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? PaceUpColors.darkBorder
              : PaceUpColors.lightBorder,
        ),
      ),
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(42),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mobile',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 5,
                color: PaceUpColors.electricGreen,
              ),
            ],
          ),
          RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('SOCIAL', mutedColor),
        const SizedBox(height: 12),
        _buildKudosCard(textColor: textColor, mutedColor: mutedColor),
        const SizedBox(height: 10),
        _buildCommentsButton(textColor: textColor, mutedColor: mutedColor),
      ],
    );
  }

  Widget _buildKudosCard({
    required Color textColor,
    required Color mutedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    if (_isLoadingKudos) {
      return Container(
        height: 76,
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: PaceUpColors.electricGreen,
            ),
          ),
        ),
      );
    }

    final kudos = _kudos;

    if (kudos == null) {
      return const SizedBox.shrink();
    }

    final given = kudos.hasGivenKudos;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: given
                  ? PaceUpColors.electricGreen.withValues(alpha: 0.12)
                  : (isDark
                        ? PaceUpColors.darkPanelSecondary
                        : PaceUpColors.lightPanelSecondary),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              given ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: given ? PaceUpColors.electricGreen : mutedColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${kudos.kudosCount} KUDOS',
                  style: PaceUpTypography.sectionTitle(textColor),
                ),
                const SizedBox(height: 3),
                Text(
                  given
                      ? 'You gave this activity kudos.'
                      : 'Show some support.',
                  style: PaceUpTypography.body(mutedColor)
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: _isUpdatingKudos ? null : _toggleKudos,
              style: FilledButton.styleFrom(
                backgroundColor: given
                    ? (isDark
                          ? PaceUpColors.darkPanelSecondary
                          : PaceUpColors.lightPanelSecondary)
                    : PaceUpColors.electricGreen,
                foregroundColor: given ? textColor : PaceUpColors.greenInk,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: _isUpdatingKudos
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      given ? 'GIVEN' : 'KUDOS',
                      style: PaceUpTypography.label(
                        given ? textColor : PaceUpColors.greenInk,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsButton({
    required Color textColor,
    required Color mutedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showCommentsSheet(
            context,
            _activity.id,
            currentUserId: _currentUserId,
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
        label: Text('VIEW COMMENTS', style: PaceUpTypography.label(mutedColor)),
      ),
    );
  }

  Widget _buildOwnerActions({
    required Color textColor,
    required Color mutedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('MANAGE ACTIVITY', mutedColor),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isDeleting ? null : _editActivity,
                  style: FilledButton.styleFrom(
                    backgroundColor: PaceUpColors.electricGreen,
                    foregroundColor: PaceUpColors.greenInk,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    'EDIT ACTIVITY',
                    style: PaceUpTypography.label(PaceUpColors.greenInk),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isDeleting ? null : _deleteActivity,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PaceUpColors.danger,
                    side: BorderSide(
                      color: PaceUpColors.danger.withValues(alpha: 0.5),
                    ),
                  ),
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    'DELETE ACTIVITY',
                    style: PaceUpTypography.label(PaceUpColors.danger),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color textColor;
  final Color mutedColor;

  const _HeaderButton({
    required this.icon,
    required this.onPressed,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: borderColor),
          ),
          child: Icon(
            icon,
            color: onPressed == null
                ? mutedColor.withValues(alpha: 0.4)
                : textColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color accent;
  final Color textColor;
  final Color mutedColor;

  const _PerformanceMetric({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.accent,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 17),
              const SizedBox(width: 7),
              Text(label, style: PaceUpTypography.label(mutedColor)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PaceUpTypography.largeMetric(accent)
                      .copyWith(fontSize: 27),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit, style: PaceUpTypography.label(mutedColor)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final Color color;

  const _VerticalDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 52, color: color);
  }
}

class _RoutePlaceholder extends StatelessWidget {
  final String text;
  final String? subtitle;
  final IconData icon;
  final Color mutedColor;

  const _RoutePlaceholder({
    required this.text,
    this.subtitle,
    required this.icon,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 38, color: mutedColor),
          const SizedBox(height: 12),
          Text(
            text,
            style: PaceUpTypography.sectionTitle(mutedColor),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: PaceUpTypography.body(mutedColor),
            ),
          ],
        ],
      ),
    );
  }
}
