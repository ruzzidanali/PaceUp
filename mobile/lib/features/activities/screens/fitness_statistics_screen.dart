import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/activity_models.dart';
import '../services/activity_service.dart';

class FitnessStatisticsScreen extends StatefulWidget {
  const FitnessStatisticsScreen({super.key});

  @override
  State<FitnessStatisticsScreen> createState() =>
      _FitnessStatisticsScreenState();
}

class _FitnessStatisticsScreenState extends State<FitnessStatisticsScreen> {
  late final ActivityService _activityService;

  ActivityStatsResponse? _stats;
  ActivityTrendResponse? _trends;

  int _selectedRange = 30;

  bool _isLoading = true;
  bool _isLoadingTrends = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _activityService = ActivityService();

    _loadStats();
  }

  @override
  void dispose() {
    _activityService.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _isLoadingTrends = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final from = now.subtract(Duration(days: _selectedRange));

      final results = await Future.wait([
        _activityService.getStats(from: from, to: now),
        _activityService.getTrends(from: from, to: now, groupBy: 'day'),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _stats = results[0] as ActivityStatsResponse;
        _trends = results[1] as ActivityTrendResponse;
        _isLoading = false;
        _isLoadingTrends = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _isLoadingTrends = false;
      });
    }
  }

  String _rangeLabel() {
    switch (_selectedRange) {
      case 7:
        return 'LAST 7 DAYS';
      case 30:
        return 'LAST 30 DAYS';
      case 365:
        return 'LAST YEAR';
      default:
        return 'LAST $_selectedRange DAYS';
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  String _formatPace(double? secondsPerKm) {
    if (secondsPerKm == null || secondsPerKm <= 0) {
      return '--';
    }

    final totalSeconds = secondsPerKm.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPaceWithUnit(double? secondsPerKm) {
    final pace = _formatPace(secondsPerKm);

    if (pace == '--') {
      return '--';
    }

    return '$pace /KM';
  }

  String _formatPaceAxis(double secondsPerKm) {
    if (secondsPerKm <= 0) {
      return '--';
    }

    final totalSeconds = secondsPerKm.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSpeed(double? speedKmh) {
    if (speedKmh == null || speedKmh <= 0) {
      return '--';
    }

    return speedKmh.toStringAsFixed(1);
  }

  void _changeRange(int days) {
    if (_selectedRange == days) {
      return;
    }

    setState(() {
      _selectedRange = days;
    });

    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.dark
        ? _ThemeValues.dark
        : _ThemeValues.light;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(colors),
      body: RefreshIndicator(
        color: PaceUpColors.electricGreen,
        backgroundColor: colors.panel,
        onRefresh: _loadStats,
        child: _isLoading
            ? _buildLoadingState(colors)
            : _errorMessage != null
            ? _buildErrorState(colors)
            : _buildContent(colors),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(_ThemeValues colors) {
    return AppBar(
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERFORMANCE',
            style: PaceUpTypography.label(PaceUpColors.electricGreen),
          ),
          const SizedBox(height: 3),
          Text(
            'Fitness Statistics',
            style: PaceUpTypography.heading(colors.text).copyWith(fontSize: 25),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: PaceUpColors.electricGreen,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(_ThemeValues colors) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _SkeletonBox(height: 56, borderRadius: 12, color: colors.panel),
        const SizedBox(height: 20),
        _SkeletonBox(height: 210, borderRadius: 14, color: colors.panel),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SkeletonBox(
                height: 120,
                borderRadius: 12,
                color: colors.panel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SkeletonBox(
                height: 120,
                borderRadius: 12,
                color: colors.panel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SkeletonBox(
                height: 120,
                borderRadius: 12,
                color: colors.panel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SkeletonBox(
                height: 120,
                borderRadius: 12,
                color: colors.panel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SkeletonBox(height: 300, borderRadius: 14, color: colors.panel),
      ],
    );
  }

  Widget _buildContent(_ThemeValues colors) {
    final stats = _stats;

    if (stats == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        _buildRangeSelector(colors),
        const SizedBox(height: 22),
        _buildHero(stats, colors),
        const SizedBox(height: 28),
        _buildSectionHeader(
          eyebrow: 'OVERVIEW',
          title: 'Your numbers',
          colors: colors,
        ),
        const SizedBox(height: 12),
        _buildSummaryGrid(stats, colors),
        const SizedBox(height: 30),
        _buildSectionHeader(
          eyebrow: 'PERFORMANCE',
          title: 'How you move',
          colors: colors,
        ),
        const SizedBox(height: 12),
        _buildPerformanceSection(stats, colors),
        const SizedBox(height: 30),
        _buildInsightsSection(stats, colors),
        const SizedBox(height: 30),
        _buildSectionHeader(
          eyebrow: 'TRENDS',
          title: 'Your progress',
          colors: colors,
        ),
        const SizedBox(height: 12),
        _buildDistanceTrend(colors),
        const SizedBox(height: 12),
        _buildPaceTrend(colors),
        const SizedBox(height: 12),
        _buildSpeedTrend(colors),
        const SizedBox(height: 30),
        _buildSectionHeader(
          eyebrow: 'ACTIVITY',
          title: 'What you do',
          colors: colors,
        ),
        const SizedBox(height: 12),
        _buildActivityBreakdown(stats, colors),
      ],
    );
  }

  Widget _buildRangeSelector(_ThemeValues colors) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _RangeButton(
            label: '7D',
            selected: _selectedRange == 7,
            onTap: () => _changeRange(7),
            colors: colors,
          ),
          _RangeButton(
            label: '30D',
            selected: _selectedRange == 30,
            onTap: () => _changeRange(30),
            colors: colors,
          ),
          _RangeButton(
            label: '1Y',
            selected: _selectedRange == 365,
            onTap: () => _changeRange(365),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ActivityStatsResponse stats, _ThemeValues colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -35,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PaceUpColors.electricGreen.withValues(alpha: 0.08),
                  width: 20,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: PaceUpColors.electricGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: PaceUpColors.electricGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _rangeLabel(),
                    style: PaceUpTypography.label(colors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                stats.totalDistance.toStringAsFixed(1),
                style: PaceUpTypography.heroMetric(colors.text)
                    .copyWith(fontSize: 68),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      'KM',
                      style: PaceUpTypography.sectionTitle(
                        PaceUpColors.electricGreen,
                      ).copyWith(fontSize: 14, letterSpacing: 1.8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      'TOTAL DISTANCE',
                      style: PaceUpTypography.label(colors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: colors.border),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeroMiniMetric(
                      value: stats.totalActivities.toString(),
                      label: 'ACTIVITIES',
                      colors: colors,
                    ),
                  ),
                  Container(width: 1, height: 34, color: colors.border),
                  Expanded(
                    child: _HeroMiniMetric(
                      value: _formatDuration(stats.totalDurationSeconds),
                      label: 'TIME ACTIVE',
                      colors: colors,
                    ),
                  ),
                  Container(width: 1, height: 34, color: colors.border),
                  Expanded(
                    child: _HeroMiniMetric(
                      value: '${stats.totalCalories}',
                      label: 'KCAL',
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String eyebrow,
    required String title,
    required _ThemeValues colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: PaceUpTypography.label(PaceUpColors.electricGreen),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: PaceUpTypography.heading(colors.text).copyWith(fontSize: 24),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(ActivityStatsResponse stats, _ThemeValues colors) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      mainAxisExtent: 122,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricCard(
          icon: Icons.directions_run_rounded,
          value: stats.totalActivities.toString(),
          label: 'ACTIVITIES',
          accent: PaceUpColors.electricGreen,
          colors: colors,
        ),
        _MetricCard(
          icon: Icons.route_rounded,
          value: stats.totalDistance.toStringAsFixed(1),
          suffix: 'KM',
          label: 'DISTANCE',
          accent: PaceUpColors.electricCyan,
          colors: colors,
        ),
        _MetricCard(
          icon: Icons.timer_outlined,
          value: _formatDuration(stats.totalDurationSeconds),
          label: 'DURATION',
          accent: PaceUpColors.electricGreen,
          colors: colors,
        ),
        _MetricCard(
          icon: Icons.local_fire_department_rounded,
          value: stats.totalCalories.toString(),
          suffix: 'KCAL',
          label: 'CALORIES',
          accent: PaceUpColors.electricCyan,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(
    ActivityStatsResponse stats,
    _ThemeValues colors,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _PerformanceRow(
            icon: Icons.speed_rounded,
            title: 'Average pace',
            value: _formatPaceWithUnit(stats.averagePaceSecondsPerKm),
            accent: PaceUpColors.electricGreen,
            colors: colors,
          ),
          Divider(height: 1, color: colors.border),
          _PerformanceRow(
            icon: Icons.bolt_rounded,
            title: 'Average speed',
            value: _formatSpeedWithUnit(stats.averageSpeedKmh),
            accent: PaceUpColors.electricCyan,
            colors: colors,
          ),
          Divider(height: 1, color: colors.border),
          _PerformanceRow(
            icon: Icons.workspace_premium_rounded,
            title: 'Best pace',
            value: _formatPaceWithUnit(stats.bestPaceSecondsPerKm),
            accent: PaceUpColors.electricGreen,
            colors: colors,
          ),
          Divider(height: 1, color: colors.border),
          _PerformanceRow(
            icon: Icons.flash_on_rounded,
            title: 'Best speed',
            value: _formatSpeedWithUnit(stats.bestSpeedKmh),
            accent: PaceUpColors.electricCyan,
            colors: colors,
          ),
        ],
      ),
    );
  }

  String _formatSpeedWithUnit(double? speed) {
    final formatted = _formatSpeed(speed);

    if (formatted == '--') {
      return '--';
    }

    return '$formatted KM/H';
  }

  Widget _buildInsightsSection(
    ActivityStatsResponse stats,
    _ThemeValues colors,
  ) {
    final distance = stats.totalDistance;
    final activities = stats.totalActivities;

    final String activityMessage;

    if (activities == 0) {
      activityMessage = 'No activities recorded in this period.';
    } else if (activities == 1) {
      activityMessage = 'You completed 1 activity in this period.';
    } else {
      activityMessage =
          'You completed $activities activities covering '
          '${distance.toStringAsFixed(1)} km.';
    }

    final String performanceMessage;

    if (stats.averagePaceSecondsPerKm != null) {
      performanceMessage =
          'Your average pace is '
          '${_formatPaceWithUnit(stats.averagePaceSecondsPerKm)}.';
    } else if (stats.averageSpeedKmh != null) {
      performanceMessage =
          'Your average speed is '
          '${_formatSpeedWithUnit(stats.averageSpeedKmh)}.';
    } else {
      performanceMessage =
          'Complete more activities to unlock performance insights.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PaceUpColors.electricGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: PaceUpColors.electricGreen.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: PaceUpColors.electricGreen.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: PaceUpColors.electricGreen,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'QUICK INSIGHT',
                style: PaceUpTypography.sectionTitle(
                  PaceUpColors.electricGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InsightRow(
            icon: Icons.route_rounded,
            text: activityMessage,
            colors: colors,
          ),
          const SizedBox(height: 12),
          _InsightRow(
            icon: Icons.speed_rounded,
            text: performanceMessage,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceTrend(_ThemeValues colors) {
    if (_isLoadingTrends) {
      return _buildChartLoading(colors);
    }

    final trends = _trends;

    if (trends == null || trends.items.isEmpty) {
      return _buildEmptyChart(
        title: 'Distance',
        subtitle: 'Daily distance',
        message: 'No distance data for this period.',
        colors: colors,
      );
    }

    final spots = trends.items.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalDistance);
    }).toList();

    final maxDistance = trends.items
        .map((item) => item.totalDistance)
        .reduce((a, b) => a > b ? a : b);

    final chartMaxY = maxDistance <= 0 ? 1.0 : maxDistance * 1.2;

    return _ChartCard(
      title: 'Distance',
      subtitle: 'DAILY DISTANCE • KM',
      colors: colors,
      child: SizedBox(
        height: 235,
        child: LineChart(
          _distanceChartData(spots, chartMaxY, trends, colors),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  LineChartData _distanceChartData(
    List<FlSpot> spots,
    double chartMaxY,
    ActivityTrendResponse trends,
    _ThemeValues colors,
  ) {
    return LineChartData(
      minY: 0,
      maxY: chartMaxY,
      minX: 0,
      maxX: math.max(0, (spots.length - 1).toDouble()),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: chartMaxY / 4,
        getDrawingHorizontalLine: (_) {
          return FlLine(
            color: colors.border.withValues(alpha: 0.55),
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(value >= 10 ? 0 : 1),
                style: PaceUpTypography.label(colors.muted)
                    .copyWith(fontSize: 8, letterSpacing: 0.3),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: _bottomTitleInterval(spots.length),
            getTitlesWidget: (value, meta) {
              final index = value.round();

              if (index < 0 || index >= trends.items.length) {
                return const SizedBox.shrink();
              }

              final date = trends.items[index].date.toLocal();

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${date.day}/${date.month}',
                  style: PaceUpTypography.label(colors.muted)
                      .copyWith(fontSize: 8, letterSpacing: 0),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => colors.tooltip,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.round();

              if (index < 0 || index >= trends.items.length) {
                return null;
              }

              final item = trends.items[index];

              return LineTooltipItem(
                '${item.totalDistance.toStringAsFixed(2)} KM',
                PaceUpTypography.bodyMedium(colors.text).copyWith(fontSize: 11),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          barWidth: 3,
          color: PaceUpColors.electricGreen,
          dotData: FlDotData(
            show: spots.length <= 14,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: PaceUpColors.electricGreen,
                strokeWidth: 2,
                strokeColor: colors.panel,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: PaceUpColors.electricGreen.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }

  Widget _buildPaceTrend(_ThemeValues colors) {
    if (_isLoadingTrends) {
      return _buildChartLoading(colors);
    }

    final trends = _trends;

    if (trends == null || trends.items.isEmpty) {
      return _buildEmptyChart(
        title: 'Pace',
        subtitle: 'AVERAGE PACE • /KM',
        message: 'No pace data for this period.',
        colors: colors,
      );
    }

    final paceItems = trends.items
        .where(
          (item) =>
              item.averagePaceSecondsPerKm != null &&
              item.averagePaceSecondsPerKm! > 0,
        )
        .toList();

    if (paceItems.isEmpty) {
      return _buildEmptyChart(
        title: 'Pace',
        subtitle: 'AVERAGE PACE • /KM',
        message: 'No pace data for this period.',
        colors: colors,
      );
    }

    final spots = paceItems.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.averagePaceSecondsPerKm!);
    }).toList();

    final minPace = paceItems
        .map((item) => item.averagePaceSecondsPerKm!)
        .reduce((a, b) => a < b ? a : b);

    final maxPace = paceItems
        .map((item) => item.averagePaceSecondsPerKm!)
        .reduce((a, b) => a > b ? a : b);

    final chartMinY = minPace > 60
        ? math.max(0, (minPace / 30).floor() * 30.0 - 30)
        : 0.0;

    final chartMaxY = math.max(
      chartMinY + 60,
      (maxPace / 30).ceil() * 30.0 + 30,
    );

    return _ChartCard(
      title: 'Pace',
      subtitle: 'AVERAGE PACE • /KM',
      colors: colors,
      child: SizedBox(
        height: 235,
        child: LineChart(
          LineChartData(
            minY: chartMinY.toDouble(),
            maxY: chartMaxY.toDouble(),
            minX: 0,
            maxX: math.max(0, (spots.length - 1).toDouble()),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 30,
              getDrawingHorizontalLine: (_) {
                return FlLine(
                  color: colors.border.withValues(alpha: 0.55),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: 30,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _formatPaceAxis(value),
                      style: PaceUpTypography.label(colors.muted)
                          .copyWith(fontSize: 8, letterSpacing: 0),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: _bottomTitleInterval(spots.length),
                  getTitlesWidget: (value, meta) {
                    final index = value.round();

                    if (index < 0 || index >= paceItems.length) {
                      return const SizedBox.shrink();
                    }

                    final date = paceItems[index].date.toLocal();

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: PaceUpTypography.label(colors.muted)
                            .copyWith(fontSize: 8, letterSpacing: 0),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => colors.tooltip,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.round();

                    if (index < 0 || index >= paceItems.length) {
                      return null;
                    }

                    final item = paceItems[index];

                    return LineTooltipItem(
                      _formatPaceWithUnit(item.averagePaceSecondsPerKm),
                      PaceUpTypography.bodyMedium(colors.text)
                          .copyWith(fontSize: 11),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.25,
                barWidth: 3,
                color: PaceUpColors.electricCyan,
                dotData: FlDotData(
                  show: spots.length <= 14,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: PaceUpColors.electricCyan,
                      strokeWidth: 2,
                      strokeColor: colors.panel,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: PaceUpColors.electricCyan.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  Widget _buildSpeedTrend(_ThemeValues colors) {
    if (_isLoadingTrends) {
      return _buildChartLoading(colors);
    }

    final trends = _trends;

    if (trends == null || trends.items.isEmpty) {
      return _buildEmptyChart(
        title: 'Speed',
        subtitle: 'AVERAGE SPEED • KM/H',
        message: 'No speed data for this period.',
        colors: colors,
      );
    }

    final speedItems = trends.items
        .where(
          (item) => item.averageSpeedKmh != null && item.averageSpeedKmh! > 0,
        )
        .toList();

    if (speedItems.isEmpty) {
      return _buildEmptyChart(
        title: 'Speed',
        subtitle: 'AVERAGE SPEED • KM/H',
        message: 'No speed data for this period.',
        colors: colors,
      );
    }

    final spots = speedItems.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.averageSpeedKmh!);
    }).toList();

    final maxSpeed = speedItems
        .map((item) => item.averageSpeedKmh!)
        .reduce((a, b) => a > b ? a : b);

    final chartMaxY = maxSpeed <= 0
        ? 5.0
        : math.max(5.0, (maxSpeed / 5).ceil() * 5.0 + 5);

    return _ChartCard(
      title: 'Speed',
      subtitle: 'AVERAGE SPEED • KM/H',
      colors: colors,
      child: SizedBox(
        height: 235,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: chartMaxY,
            minX: 0,
            maxX: math.max(0, (spots.length - 1).toDouble()),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (_) {
                return FlLine(
                  color: colors.border.withValues(alpha: 0.55),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: PaceUpTypography.label(colors.muted)
                          .copyWith(fontSize: 8, letterSpacing: 0),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: _bottomTitleInterval(spots.length),
                  getTitlesWidget: (value, meta) {
                    final index = value.round();

                    if (index < 0 || index >= speedItems.length) {
                      return const SizedBox.shrink();
                    }

                    final date = speedItems[index].date.toLocal();

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: PaceUpTypography.label(colors.muted)
                            .copyWith(fontSize: 8, letterSpacing: 0),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => colors.tooltip,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.round();

                    if (index < 0 || index >= speedItems.length) {
                      return null;
                    }

                    final item = speedItems[index];

                    return LineTooltipItem(
                      _formatSpeedWithUnit(item.averageSpeedKmh),
                      PaceUpTypography.bodyMedium(colors.text)
                          .copyWith(fontSize: 11),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.25,
                barWidth: 3,
                color: PaceUpColors.electricGreen,
                dotData: FlDotData(
                  show: spots.length <= 14,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: PaceUpColors.electricGreen,
                      strokeWidth: 2,
                      strokeColor: colors.panel,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: PaceUpColors.electricGreen.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  Widget _buildChartLoading(_ThemeValues colors) {
    return _SkeletonBox(height: 310, borderRadius: 14, color: colors.panel);
  }

  Widget _buildEmptyChart({
    required String title,
    required String subtitle,
    required String message,
    required _ThemeValues colors,
  }) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: PaceUpTypography.sectionTitle(colors.text),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: PaceUpTypography.label(colors.muted).copyWith(fontSize: 8),
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Icon(Icons.query_stats_rounded, color: colors.muted, size: 32),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: PaceUpTypography.body(colors.muted),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildActivityBreakdown(
    ActivityStatsResponse stats,
    _ThemeValues colors,
  ) {
    final entries = stats.activitiesByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.fitness_center_outlined, color: colors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No activities in this period.',
                style: PaceUpTypography.body(colors.muted),
              ),
            ),
          ],
        ),
      );
    }

    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == entries.length - 1 ? 0 : 18,
              ),
              child: _ActivityBreakdownRow(
                type: entries[i].key,
                count: entries[i].value,
                total: total,
                icon: _activityIcon(entries[i].key),
                colors: colors,
              ),
            ),
        ],
      ),
    );
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

  Widget _buildErrorState(_ThemeValues colors) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 520,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: PaceUpColors.danger.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: PaceUpColors.danger,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'STATISTICS UNAVAILABLE',
                    style: PaceUpTypography.sectionTitle(colors.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage ?? 'Unable to load statistics.',
                    style: PaceUpTypography.body(colors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _loadStats,
                      style: FilledButton.styleFrom(
                        backgroundColor: PaceUpColors.electricGreen,
                        foregroundColor: PaceUpColors.greenInk,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        'TRY AGAIN',
                        style: PaceUpTypography.label(PaceUpColors.greenInk),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _bottomTitleInterval(int count) {
    if (count <= 7) {
      return 1;
    }

    if (count <= 14) {
      return 2;
    }

    if (count <= 31) {
      return 5;
    }

    return 7;
  }
}

class _ThemeValues {
  final Color background;
  final Color panel;
  final Color text;
  final Color muted;
  final Color border;
  final Color tooltip;

  const _ThemeValues({
    required this.background,
    required this.panel,
    required this.text,
    required this.muted,
    required this.border,
    required this.tooltip,
  });

  static const dark = _ThemeValues(
    background: PaceUpColors.darkBackground,
    panel: PaceUpColors.darkPanel,
    text: PaceUpColors.darkText,
    muted: PaceUpColors.darkMuted,
    border: PaceUpColors.darkBorder,
    tooltip: PaceUpColors.darkPanelSecondary,
  );

  static const light = _ThemeValues(
    background: PaceUpColors.lightBackground,
    panel: PaceUpColors.lightPanel,
    text: PaceUpColors.lightText,
    muted: PaceUpColors.lightMuted,
    border: PaceUpColors.lightBorder,
    tooltip: PaceUpColors.lightPanelSecondary,
  );
}

class _RangeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final _ThemeValues colors;

  const _RangeButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? PaceUpColors.electricGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              label,
              style: PaceUpTypography.label(
                selected ? PaceUpColors.greenInk : colors.muted,
              ).copyWith(fontSize: 10, letterSpacing: 1.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroMiniMetric extends StatelessWidget {
  final String value;
  final String label;
  final _ThemeValues colors;

  const _HeroMiniMetric({
    required this.value,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PaceUpTypography.bodyMedium(colors.text)
                .copyWith(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: PaceUpTypography.label(colors.muted)
                .copyWith(fontSize: 7, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? suffix;
  final String label;
  final Color accent;
  final _ThemeValues colors;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.colors,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PaceUpTypography.largeMetric(colors.text)
                      .copyWith(fontSize: 28),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    suffix!,
                    style: PaceUpTypography.label(accent)
                        .copyWith(fontSize: 7, letterSpacing: 0.8),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: PaceUpTypography.label(colors.muted)
                .copyWith(fontSize: 7, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accent;
  final _ThemeValues colors;

  const _PerformanceRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: PaceUpTypography.bodyMedium(colors.text)),
          ),
          Text(
            value,
            style: PaceUpTypography.bodyMedium(accent)
                .copyWith(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final _ThemeValues colors;

  const _InsightRow({
    required this.icon,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: PaceUpColors.electricGreen, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: PaceUpTypography.body(colors.text))),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final _ThemeValues colors;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: PaceUpTypography.sectionTitle(colors.text),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: PaceUpTypography.label(colors.muted)
                .copyWith(fontSize: 8, letterSpacing: 1),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActivityBreakdownRow extends StatelessWidget {
  final String type;
  final int count;
  final int total;
  final IconData icon;
  final _ThemeValues colors;

  const _ActivityBreakdownRow({
    required this.type,
    required this.count,
    required this.total,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total <= 0 ? 0.0 : count / total;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: PaceUpColors.electricGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: PaceUpColors.electricGreen, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                type.toUpperCase(),
                style: PaceUpTypography.bodyMedium(colors.text)
                    .copyWith(fontSize: 11),
              ),
            ),
            Text(
              '$count',
              style: PaceUpTypography.bodyMedium(colors.text)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                color: colors.border,
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: PaceUpColors.electricGreen,
                    borderRadius: BorderRadius.circular(3),
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

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double borderRadius;
  final Color color;

  const _SkeletonBox({
    required this.height,
    required this.borderRadius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: PaceUpColors.darkBorder.withValues(alpha: 0.45),
        ),
      ),
      child: Center(
        child: Container(
          width: 28,
          height: 3,
          decoration: BoxDecoration(
            color: PaceUpColors.electricGreen.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
