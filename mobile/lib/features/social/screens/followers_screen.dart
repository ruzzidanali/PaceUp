import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/social_models.dart';
import '../services/social_service.dart';
import 'user_profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final String title;

  const FollowersScreen({
    super.key,
    required this.userId,
    this.title = 'Followers',
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final SocialService _socialService = SocialService();

  FollowListResponse? _response;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _socialService.getFollowers(widget.userId);

      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _socialService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? PaceUpColors.darkBackground
        : PaceUpColors.lightBackground;

    final textColor = isDark ? PaceUpColors.darkText : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    if (_isLoading) {
      return const _SocialListLoadingState();
    }

    if (_errorMessage != null) {
      return _SocialListErrorState(
        backgroundColor: backgroundColor,
        textColor: textColor,
        mutedColor: mutedColor,
        message: _errorMessage!,
        onRetry: _loadFollowers,
      );
    }

    final users = _response?.users ?? [];

    if (users.isEmpty) {
      return _SocialListEmptyState(
        backgroundColor: backgroundColor,
        textColor: textColor,
        mutedColor: mutedColor,
        title: 'NO FOLLOWERS YET',
        message: 'When people follow this athlete, they will appear here.',
        onRefresh: _loadFollowers,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFollowers,
          color: PaceUpColors.electricGreen,
          backgroundColor: isDark
              ? PaceUpColors.darkPanel
              : PaceUpColors.lightPanel,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
            children: [
              _buildHeader(
                textColor: textColor,
                mutedColor: mutedColor,
                count: users.length,
              ),
              const SizedBox(height: 28),
              _buildList(
                users: users,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required Color textColor,
    required Color mutedColor,
    required int count,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_rounded, size: 20, color: textColor),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SOCIAL',
              style: PaceUpTypography.sectionTitle(PaceUpColors.electricGreen),
            ),
            const SizedBox(height: 3),
            Text(
              widget.title.toUpperCase(),
              style: PaceUpTypography.heading(textColor).copyWith(fontSize: 24),
            ),
          ],
        ),
        const Spacer(),
        Text(
          count.toString().padLeft(2, '0'),
          style: PaceUpTypography.largeMetric(mutedColor)
              .copyWith(fontSize: 24),
        ),
      ],
    );
  }

  Widget _buildList({
    required List<FollowUser> users,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: List.generate(users.length, (index) {
          final user = users[index];

          return Column(
            children: [
              _FollowUserRow(
                user: user,
                textColor: textColor,
                mutedColor: mutedColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: user.userId),
                    ),
                  );
                },
              ),
              if (index < users.length - 1)
                Divider(height: 1, color: borderColor),
            ],
          );
        }),
      ),
    );
  }
}

class _FollowUserRow extends StatelessWidget {
  final FollowUser user;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _FollowUserRow({
    required this.user,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.profileImageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
          child: Row(
            children: [
              _buildAvatar(imageUrl),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PaceUpTypography.bodyMedium(textColor),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PaceUpTypography.body(mutedColor)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return CircleAvatar(
        radius: 23,
        backgroundColor: PaceUpColors.electricGreen.withValues(alpha: 0.10),
        child: Text(
          _initials(user.displayName),
          style: const TextStyle(
            color: PaceUpColors.electricGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 23,
      backgroundColor: PaceUpColors.darkPanelSecondary,
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (_, _) {},
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _SocialListLoadingState extends StatelessWidget {
  const _SocialListLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _SocialSkeleton(),
        _SocialSkeleton(),
        _SocialSkeleton(),
        _SocialSkeleton(),
        _SocialSkeleton(),
        _SocialSkeleton(),
      ],
    );
  }
}

class _SocialSkeleton extends StatelessWidget {
  const _SocialSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 130,
                  height: 12,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 90,
                  height: 9,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 10,
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialListErrorState extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color mutedColor;
  final String message;
  final Future<void> Function() onRetry;

  const _SocialListErrorState({
    required this.backgroundColor,
    required this.textColor,
    required this.mutedColor,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: onRetry,
        color: PaceUpColors.electricGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 160, 24, 40),
          children: [
            Icon(Icons.cloud_off_outlined, size: 42, color: mutedColor),
            const SizedBox(height: 20),
            Text(
              'SOCIAL UNAVAILABLE',
              textAlign: TextAlign.center,
              style: PaceUpTypography.heading(textColor),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PaceUpTypography.body(mutedColor),
            ),
            const SizedBox(height: 22),
            Center(
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: PaceUpColors.electricGreen,
                  foregroundColor: PaceUpColors.greenInk,
                ),
                child: Text(
                  'TRY AGAIN',
                  style: PaceUpTypography.label(PaceUpColors.greenInk),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialListEmptyState extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color mutedColor;
  final String title;
  final String message;
  final Future<void> Function() onRefresh;

  const _SocialListEmptyState({
    required this.backgroundColor,
    required this.textColor,
    required this.mutedColor,
    required this.title,
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        color: PaceUpColors.electricGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 170, 24, 40),
          children: [
            Icon(Icons.people_outline_rounded, size: 42, color: mutedColor),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: PaceUpTypography.heading(textColor),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PaceUpTypography.body(mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}
