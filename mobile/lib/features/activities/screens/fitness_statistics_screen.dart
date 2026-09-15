import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
        return 'Last 7 days';
      case 30:
        return 'Last 30 days';
      case 365:
        return 'Last year';
      default:
        return 'Last $_selectedRange days';
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

    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
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

    return '${speedKmh.toStringAsFixed(1)} km/h';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness Statistics')),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : _errorMessage != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final stats = _stats;

    if (stats == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildRangeSelector(),
        const SizedBox(height: 16),
        Text(
          _rangeLabel(),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildSummaryGrid(stats),
        const SizedBox(height: 24),
        _buildPerformanceSection(stats),
        const SizedBox(height: 24),
        _buildInsightsSection(stats),
        const SizedBox(height: 24),
        _buildDistanceTrend(),
        const SizedBox(height: 24),
        _buildPaceTrend(),
        const SizedBox(height: 24),
        _buildSpeedTrend(),
        const SizedBox(height: 24),
        _buildActivityBreakdown(stats),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment<int>(value: 7, label: Text('7 Days')),
        ButtonSegment<int>(value: 30, label: Text('30 Days')),
        ButtonSegment<int>(value: 365, label: Text('1 Year')),
      ],
      selected: {_selectedRange},
      onSelectionChanged: (selection) {
        _changeRange(selection.first);
      },
    );
  }

  Widget _buildSummaryGrid(ActivityStatsResponse stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      mainAxisExtent: 120,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          icon: Icons.fitness_center_rounded,
          value: stats.totalActivities.toString(),
          label: 'Activities',
        ),
        _StatCard(
          icon: Icons.straighten_rounded,
          value: '${stats.totalDistance.toStringAsFixed(1)} km',
          label: 'Distance',
        ),
        _StatCard(
          icon: Icons.timer_outlined,
          value: _formatDuration(stats.totalDurationSeconds),
          label: 'Duration',
        ),
        _StatCard(
          icon: Icons.local_fire_department_outlined,
          value: '${stats.totalCalories} kcal',
          label: 'Calories',
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(ActivityStatsResponse stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 120,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatCard(
                  icon: Icons.speed_rounded,
                  value: _formatPace(stats.averagePaceSecondsPerKm),
                  label: 'Average Pace',
                ),
                _StatCard(
                  icon: Icons.speed_rounded,
                  value: _formatSpeed(stats.averageSpeedKmh),
                  label: 'Average Speed',
                ),
                _StatCard(
                  icon: Icons.bolt_rounded,
                  value: _formatPace(stats.bestPaceSecondsPerKm),
                  label: 'Best Pace',
                ),
                _StatCard(
                  icon: Icons.flash_on_rounded,
                  value: _formatSpeed(stats.bestSpeedKmh),
                  label: 'Best Speed',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(ActivityStatsResponse stats) {
    final distance = stats.totalDistance;
    final activities = stats.totalActivities;

    String activityMessage;

    if (activities == 0) {
      activityMessage = 'No activities recorded in this period.';
    } else if (activities == 1) {
      activityMessage = 'You completed 1 activity in this period.';
    } else {
      activityMessage =
          'You completed $activities activities covering '
          '${distance.toStringAsFixed(1)} km.';
    }

    String performanceMessage;

    if (stats.averagePaceSecondsPerKm != null) {
      performanceMessage =
          'Your average pace is '
          '${_formatPace(stats.averagePaceSecondsPerKm)}.';
    } else if (stats.averageSpeedKmh != null) {
      performanceMessage =
          'Your average speed is '
          '${_formatSpeed(stats.averageSpeedKmh)}.';
    } else {
      performanceMessage =
          'Complete more activities to see performance insights.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.insights_rounded),
                const SizedBox(width: 12),
                Expanded(child: Text(activityMessage)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.speed_rounded),
                const SizedBox(width: 12),
                Expanded(child: Text(performanceMessage)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceTrend() {
    if (_isLoadingTrends) {
      return const Card(
        child: SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final trends = _trends;

    if (trends == null || trends.items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distance Trend',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Center(child: Text('No distance data for this period.')),
              ),
            ],
          ),
        ),
      );
    }

    final spots = trends.items.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalDistance);
    }).toList();

    final maxDistance = trends.items
        .map((item) => item.totalDistance)
        .reduce((a, b) => a > b ? a : b);

    final chartMaxY = maxDistance <= 0 ? 1.0 : maxDistance * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distance Trend',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Daily distance',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: chartMaxY,
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  gridData: const FlGridData(show: true),
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
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(value >= 10 ? 0 : 1),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
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
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.round();

                          if (index < 0 || index >= trends.items.length) {
                            return null;
                          }

                          final item = trends.items[index];

                          return LineTooltipItem(
                            '${item.totalDistance.toStringAsFixed(2)} km',
                            const TextStyle(fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaceTrend() {
    if (_isLoadingTrends) {
      return const Card(
        child: SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final trends = _trends;

    if (trends == null || trends.items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pace Trend', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Center(child: Text('No pace data for this period.')),
              ),
            ],
          ),
        ),
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pace Trend', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Center(child: Text('No pace data for this period.')),
              ),
            ],
          ),
        ),
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

    final chartMinY = minPace > 60 ? (minPace / 30).floor() * 30.0 : 0.0;

    final chartMaxY = (maxPace / 30).ceil() * 30.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pace Trend',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Average pace per day',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: chartMinY,
                  maxY: chartMaxY,
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  gridData: const FlGridData(show: true),
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
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
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
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.round();

                          if (index < 0 || index >= paceItems.length) {
                            return null;
                          }

                          final item = paceItems[index];

                          return LineTooltipItem(
                            _formatPace(item.averagePaceSecondsPerKm),
                            const TextStyle(fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedTrend() {
    if (_isLoadingTrends) {
      return const Card(
        child: SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final trends = _trends;

    if (trends == null || trends.items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speed Trend',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Center(child: Text('No speed data for this period.')),
              ),
            ],
          ),
        ),
      );
    }

    final speedItems = trends.items
        .where(
          (item) => item.averageSpeedKmh != null && item.averageSpeedKmh! > 0,
        )
        .toList();

    if (speedItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speed Trend',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Center(child: Text('No speed data for this period.')),
              ),
            ],
          ),
        ),
      );
    }

    final spots = speedItems.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.averageSpeedKmh!);
    }).toList();

    final maxSpeed = speedItems
        .map((item) => item.averageSpeedKmh!)
        .reduce((a, b) => a > b ? a : b);

    final chartMaxY = maxSpeed <= 0 ? 5.0 : (maxSpeed / 5).ceil() * 5.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Speed Trend',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Average speed per day',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: chartMaxY,
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  gridData: const FlGridData(show: true),
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
                        reservedSize: 40,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
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
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.round();

                          if (index < 0 || index >= speedItems.length) {
                            return null;
                          }

                          final item = speedItems[index];

                          return LineTooltipItem(
                            _formatSpeed(item.averageSpeedKmh),
                            const TextStyle(fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildActivityBreakdown(ActivityStatsResponse stats) {
    final entries = stats.activitiesByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activities by Type',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const Text('No activities in this period.')
            else
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(_activityIcon(entry.key)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 400,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loadStats,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'Run':
        return Icons.directions_run;
      case 'Ride':
        return Icons.directions_bike;
      case 'Walk':
        return Icons.directions_walk;
      case 'Hike':
        return Icons.terrain;
      case 'Swim':
        return Icons.pool;
      default:
        return Icons.fitness_center;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
