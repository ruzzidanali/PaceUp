import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/auth/services/auth_state.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/activities/screens/activities_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/goals/screens/goals_screen.dart';
import '../../features/challenges/screens/challenges_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/notifications/services/notification_service.dart';

class AppShell extends StatefulWidget {
  final AuthController authController;

  const AppShell({super.key, required this.authController});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final NotificationService _notificationService = NotificationService();

  int _unreadNotificationCount = 0;

  static const _icons = [
    Icons.home_outlined,
    Icons.dynamic_feed_outlined,
    Icons.directions_run_outlined,
    Icons.flag_outlined,
    Icons.emoji_events_outlined,
    Icons.person_outline,
  ];

  static const _selectedIcons = [
    Icons.home,
    Icons.dynamic_feed,
    Icons.directions_run,
    Icons.flag,
    Icons.emoji_events,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();

    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    _notificationService.dispose();

    super.dispose();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final notifications = await _notificationService.getNotifications();

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadNotificationCount = notifications
            .where((notification) => !notification.isRead)
            .length;
      });
    } catch (_) {
      // Notifications should not prevent the app shell from loading.
    }
  }

  void _onNavigationChanged(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));

    await _loadUnreadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pages = [
      HomeScreen(authController: widget.authController),
      const FeedScreen(),
      const ActivitiesScreen(),
      const GoalsScreen(),
      ChallengesScreen(authController: widget.authController),
      ProfileScreen(authController: widget.authController),
    ];

    return Scaffold(
      backgroundColor: PaceUpColors.darkBackground,
      appBar: AppBar(
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'pace',
                style: PaceUpTypography.heading(PaceUpColors.darkText).copyWith(
                  fontSize: 27,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'up',
                style: PaceUpTypography.heading(PaceUpColors.electricGreen)
                    .copyWith(
                      fontSize: 27,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _NotificationButton(
              unreadCount: _unreadNotificationCount,
              onPressed: _openNotifications,
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _PaceUpNavigationBar(
        currentIndex: _currentIndex,
        icons: _icons,
        selectedIcons: _selectedIcons,
        onDestinationSelected: _onNavigationChanged,
        theme: theme,
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onPressed;

  const _NotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return Material(
      color: PaceUpColors.darkPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: PaceUpColors.darkBorder),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 21,
                color: PaceUpColors.darkText,
              ),
              if (hasUnread)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                    padding: unreadCount > 9
                        ? const EdgeInsets.symmetric(horizontal: 4)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: PaceUpColors.electricGreen,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: PaceUpColors.darkPanel,
                        width: 2,
                      ),
                    ),
                    child: unreadCount > 9
                        ? Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: PaceUpTypography.label(PaceUpColors.greenInk)
                                .copyWith(fontSize: 7, letterSpacing: 0),
                            textAlign: TextAlign.center,
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaceUpNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<IconData> icons;
  final List<IconData> selectedIcons;
  final ValueChanged<int> onDestinationSelected;
  final ThemeData theme;

  const _PaceUpNavigationBar({
    required this.currentIndex,
    required this.icons,
    required this.selectedIcons,
    required this.onDestinationSelected,
    required this.theme,
  });

  static const _labels = [
    'Home',
    'Feed',
    'Activity',
    'Goals',
    'Challenges',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: PaceUpColors.darkPanel,
          border: Border(
            top: BorderSide(color: PaceUpColors.darkBorder, width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Row(
          children: List.generate(_labels.length, (index) {
            final selected = currentIndex == index;

            return Expanded(
              child: _NavigationItem(
                label: _labels[index],
                icon: selected ? selectedIcons[index] : icons[index],
                selected: selected,
                onTap: () => onDestinationSelected(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? PaceUpColors.electricGreen
        : PaceUpColors.darkMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? PaceUpColors.darkPanelSecondary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.05 : 1,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: Icon(icon, size: 20, color: foregroundColor),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: PaceUpTypography.label(foregroundColor)
                    .copyWith(fontSize: 8, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
