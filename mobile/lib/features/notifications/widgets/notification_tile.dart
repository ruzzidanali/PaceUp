import 'package:flutter/material.dart';

import '../models/notification_models.dart';

class NotificationTile extends StatelessWidget {
  final NotificationResponse notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  bool get _isAchievementNotification =>
      notification.type == 'AchievementUnlocked';

  String _notificationMessage() {
    switch (notification.type) {
      case 'ActivityKudos':
        return 'gave kudos to your activity';
      case 'ActivityComment':
        return 'commented on your activity';
      case 'NewFollower':
        return 'started following you';
      case 'AchievementUnlocked':
        return 'You unlocked an achievement!';
      default:
        return 'sent you a notification';
    }
  }

  String _timeAgo() {
    final difference =
        DateTime.now().difference(notification.createdAt);

    if (difference.inSeconds < 60) {
      return 'just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${notification.createdAt.day}/'
        '${notification.createdAt.month}/'
        '${notification.createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isAchievementNotification) {
      return ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          child: Icon(
            Icons.emoji_events,
            color: theme.colorScheme.primary,
          ),
        ),
        title: const Text(
          'Achievement unlocked!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_timeAgo()),
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
        tileColor: notification.isRead
            ? null
            : theme.colorScheme.primary.withValues(alpha: 0.06),
      );
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: notification.actorProfileImageUrl != null
            ? NetworkImage(notification.actorProfileImageUrl!)
            : null,
        child: notification.actorProfileImageUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: notification.actorDisplayName ?? 'Someone',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: ' ${_notificationMessage()}',
            ),
          ],
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(_timeAgo()),
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      tileColor: notification.isRead
          ? null
          : theme.colorScheme.primary.withValues(alpha: 0.06),
    );
  }
}