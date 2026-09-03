import 'package:flutter/material.dart';

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

  const AppShell({
    super.key,
    required this.authController,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final NotificationService _notificationService = NotificationService();

  int _unreadNotificationCount = 0;

  final _titles = const [
    'Home',
    'Feed',
    'Activities',
    'Goals',
    'Challenges',
    'Profile',
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
      final notifications =
          await _notificationService.getNotifications();

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
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );

    await _loadUnreadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        authController: widget.authController,
      ),
      const FeedScreen(),
      const ActivitiesScreen(),
      const GoalsScreen(),
      const ChallengesScreen(),
      ProfileScreen(authController: widget.authController),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            onPressed: _openNotifications,
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: _unreadNotificationCount > 0,
              label: Text(
                _unreadNotificationCount > 99
                    ? '99+'
                    : _unreadNotificationCount.toString(),
              ),
              child: const Icon(
                Icons.notifications_outlined,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavigationChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Activities',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Challenges',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}