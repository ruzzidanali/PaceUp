import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';
import '../widgets/notification_tile.dart';
import '../../activities/screens/activity_details_screen.dart';
import '../../activities/services/activity_service.dart';
import '../../social/screens/user_profile_screen.dart';
import '../../achievements/screens/achievements_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService =
      NotificationService();

  final ActivityService _activityService = ActivityService();

  List<NotificationResponse> _notifications = [];

  bool _isLoading = true;
  bool _isMarkingAllRead = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications =
          await _notificationService.getNotifications();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_notifications.every(
      (notification) => notification.isRead,
    )) {
      return;
    }

    setState(() {
      _isMarkingAllRead = true;
    });

    try {
      await _notificationService.markAllAsRead();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = _notifications
            .map(
              (notification) =>
                  notification.copyWith(isRead: true),
            )
            .toList();

        _isMarkingAllRead = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isMarkingAllRead = false;
      });

      _showError(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  Future<void> _openNotification(
    NotificationResponse notification,
  ) async {
    if (!notification.isRead) {
      try {
        await _notificationService.markAsRead(
          notification.id,
        );

        if (!mounted) {
          return;
        }

        setState(() {
          final index = _notifications.indexWhere(
            (item) => item.id == notification.id,
          );

          if (index != -1) {
            _notifications[index] =
                _notifications[index].copyWith(
              isRead: true,
            );
          }
        });
      } catch (e) {
        if (!mounted) {
          return;
        }

        _showError(
          e.toString().replaceFirst(
                'Exception: ',
                '',
              ),
        );

        return;
      }
    }

    if (!mounted) {
      return;
    }

    switch (notification.type) {
      case 'ActivityKudos':
      case 'ActivityComment':
        await _openActivityNotification(
          notification,
        );
        break;

      case 'NewFollower':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(
              userId: notification.actorUserId.toString(),
            ),
          ),
        );
        break;

      case 'AchievementUnlocked':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AchievementsScreen(),
          ),
        );
        break;
    }
  }

  Future<void> _openActivityNotification(
    NotificationResponse notification,
  ) async {
    final targetId = notification.targetId;

    if (targetId == null || targetId.isEmpty) {
      if (!mounted) {
        return;
      }

      _showError(
        'This activity is no longer available.',
      );

      return;
    }

    try {
      final activity =
          await _activityService.getActivity(targetId);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActivityDetailsScreen(
            activity: activity,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
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

  @override
  void dispose() {
    _notificationService.dispose();
    _activityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((notification) => !notification.isRead)
        .length;

    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      appBar: AppBar(
        backgroundColor: PaceUpColors.darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Row(
          children: [
            Text(
              'NOTIFICATIONS',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.electricGreen,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 9),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: PaceUpColors.electricGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: TextButton(
                onPressed:
                    _isMarkingAllRead ? null : _markAllAsRead,
                style: TextButton.styleFrom(
                  foregroundColor:
                      PaceUpColors.electricGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                ),
                child: _isMarkingAllRead
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              PaceUpColors.electricGreen,
                        ),
                      )
                    : Text(
                        'READ ALL',
                        style: PaceUpTypography.label(
                          PaceUpColors.electricGreen,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: _buildBody(unreadCount),
    );
  }

  Widget _buildBody(int unreadCount) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_notifications.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: PaceUpColors.electricGreen,
      backgroundColor: PaceUpColors.darkPanel,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          4,
          20,
          32,
        ),
        children: [
          _buildStatus(unreadCount),
          const SizedBox(height: 26),
          _buildSectionLabel(),
          const SizedBox(height: 4),
          ..._notifications.asMap().entries.map(
                (entry) => _buildNotificationRow(
                  entry.value,
                  entry.key,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildStatus(int unreadCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unreadCount == 0
                    ? 'ALL CAUGHT UP'
                    : '$unreadCount NEW',
                style: PaceUpTypography.heading(
                  PaceUpColors.darkText,
                ).copyWith(
                  fontSize: 24,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unreadCount == 0
                    ? 'Nothing new for now.'
                    : 'Your latest activity and social updates.',
                style: PaceUpTypography.body(
                  PaceUpColors.darkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          _notifications.length.toString().padLeft(2, '0'),
          style: PaceUpTypography.heroMetric(
            PaceUpColors.darkBorder,
          ).copyWith(
            fontSize: 42,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel() {
    return Text(
      'LATEST',
      style: PaceUpTypography.label(
        PaceUpColors.darkMuted,
      ).copyWith(
        fontSize: 9,
        letterSpacing: 1.8,
      ),
    );
  }

  Widget _buildNotificationRow(
    NotificationResponse notification,
    int index,
  ) {
    final accent = _accentForType(notification.type);
    final isUnread = !notification.isRead;

    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0,
        end: 1,
      ),
      duration: Duration(
        milliseconds: 220 + (index * 35),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              10 * (1 - value),
              0,
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openNotification(
            notification,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 15,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: PaceUpColors.darkBorder
                      .withValues(alpha: 0.55),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(
                  notification,
                  accent,
                  isUnread,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _labelForType(
                              notification.type,
                            ),
                            style: PaceUpTypography.label(
                              accent,
                            ).copyWith(
                              fontSize: 8,
                              letterSpacing: 1.25,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _timeAgo(
                              notification.createdAt,
                            ),
                            style: PaceUpTypography.label(
                              PaceUpColors.darkMuted,
                            ).copyWith(
                              fontSize: 8,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      NotificationTile(
                        notification: notification,
                        onTap: () => _openNotification(
                          notification,
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
    );
  }

  Widget _buildNotificationIcon(
    NotificationResponse notification,
    Color accent,
    bool isUnread,
  ) {
    if (notification.type == 'AchievementUnlocked') {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: accent.withValues(
              alpha: isUnread ? 0.35 : 0.16,
            ),
          ),
        ),
        child: Icon(
          Icons.emoji_events_rounded,
          color: accent,
          size: 20,
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _iconForType(notification.type),
        color: accent.withValues(
          alpha: isUnread ? 1 : 0.65,
        ),
        size: 19,
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'ActivityKudos':
        return Icons.favorite_rounded;
      case 'ActivityComment':
        return Icons.chat_bubble_rounded;
      case 'NewFollower':
        return Icons.person_add_alt_1_rounded;
      case 'AchievementUnlocked':
        return Icons.emoji_events_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _accentForType(String type) {
    switch (type) {
      case 'ActivityKudos':
        return const Color(0xFFFF6B81);
      case 'ActivityComment':
        return PaceUpColors.electricCyan;
      case 'NewFollower':
        return PaceUpColors.electricGreen;
      case 'AchievementUnlocked':
        return const Color(0xFFFFC857);
      default:
        return PaceUpColors.electricGreen;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'ActivityKudos':
        return 'KUDOS';
      case 'ActivityComment':
        return 'COMMENT';
      case 'NewFollower':
        return 'NEW FOLLOWER';
      case 'AchievementUnlocked':
        return 'ACHIEVEMENT';
      default:
        return 'UPDATE';
    }
  }

  String _timeAgo(DateTime createdAt) {
    final difference =
        DateTime.now().difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'NOW';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}M';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}H';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}D';
    }

    return '${createdAt.day}/'
        '${createdAt.month}/'
        '${createdAt.year}';
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        32,
      ),
      children: [
        _buildLoadingBar(120, 30),
        const SizedBox(height: 30),
        ...List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              children: [
                _buildLoadingBar(42, 42),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildLoadingBar(90, 8),
                      const SizedBox(height: 8),
                      _buildLoadingBar(180, 11),
                      const SizedBox(height: 6),
                      _buildLoadingBar(110, 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingBar(
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanelSecondary,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              color: PaceUpColors.darkMuted,
              size: 34,
            ),
            const SizedBox(height: 16),
            Text(
              'NOTIFICATIONS UNAVAILABLE',
              style: PaceUpTypography.heading(
                PaceUpColors.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 7),
            Text(
              _error!,
              style: PaceUpTypography.body(
                PaceUpColors.darkMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _loadNotifications,
              style: TextButton.styleFrom(
                foregroundColor:
                    PaceUpColors.electricGreen,
              ),
              child: Text(
                'TRY AGAIN',
                style: PaceUpTypography.label(
                  PaceUpColors.electricGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: PaceUpColors.electricGreen,
      backgroundColor: PaceUpColors.darkPanel,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          28,
          100,
          28,
          32,
        ),
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: PaceUpColors.darkBorder,
            size: 52,
          ),
          const SizedBox(height: 20),
          Text(
            'NO UPDATES YET',
            textAlign: TextAlign.center,
            style: PaceUpTypography.heading(
              PaceUpColors.darkText,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Your activity, social and achievement '
            'updates will appear here.',
            textAlign: TextAlign.center,
            style: PaceUpTypography.body(
              PaceUpColors.darkMuted,
            ),
          ),
        ],
      ),
    );
  }
}