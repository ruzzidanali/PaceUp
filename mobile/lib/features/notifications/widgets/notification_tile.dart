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

  String _notificationMessage() {
    switch (notification.type) {
      case 'ActivityKudos':
        return 'gave kudos to your activity';
      case 'NewFollower':
        return 'started following you';
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
              text: notification.actorDisplayName,
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