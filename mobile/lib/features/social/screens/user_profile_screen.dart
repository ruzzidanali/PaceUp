import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../profile/models/profile_models.dart';
import '../../profile/services/profile_service.dart';
import '../services/social_service.dart';
import 'followers_screen.dart';
import 'following_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final SocialService _socialService = SocialService();

  UserResponse? _user;

  bool _isLoading = true;
  bool _isOwnProfile = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = await _profileService.getMe();
      final isOwnProfile = currentUser.id == widget.userId;

      final user = isOwnProfile
          ? currentUser
          : await _profileService.getUser(widget.userId);

      bool isFollowing = false;

      if (!isOwnProfile) {
        isFollowing = await _socialService.isFollowing(widget.userId);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _isOwnProfile = isOwnProfile;
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) {
      return;
    }

    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (_isFollowing) {
        await _socialService.unfollow(widget.userId);
      } else {
        await _socialService.follow(widget.userId);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isFollowing = !_isFollowing;
        _isFollowLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isFollowLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _profileService.dispose();
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

    final textColor = isDark
        ? PaceUpColors.darkText
        : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    if (_isLoading) {
      return _UserProfileLoadingState(
        backgroundColor: backgroundColor,
      );
    }

    if (_errorMessage != null) {
      return _UserProfileErrorState(
        backgroundColor: backgroundColor,
        textColor: textColor,
        mutedColor: mutedColor,
        message: _errorMessage!,
        onRetry: _loadUser,
      );
    }

    final user = _user;

    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            'USER UNAVAILABLE',
            style: PaceUpTypography.heading(textColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUser,
          color: PaceUpColors.electricGreen,
          backgroundColor: isDark
              ? PaceUpColors.darkPanel
              : PaceUpColors.lightPanel,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
            children: [
              _buildTopBar(
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 30),
              _buildHero(
                user: user,
                isDark: isDark,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 28),
              if (!_isOwnProfile) ...[
                _buildFollowButton(
                  textColor: textColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 30),
              ],
              _buildSocialSection(
                user: user,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              const SizedBox(height: 30),
              _buildSectionLabel(
                'ABOUT',
                PaceUpColors.electricCyan,
              ),
              const SizedBox(height: 12),
              _buildJoinedRow(
                user: user,
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

  Widget _buildTopBar({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'ATHLETE',
          style: PaceUpTypography.sectionTitle(
            PaceUpColors.electricGreen,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.public_rounded,
          size: 18,
          color: mutedColor,
        ),
      ],
    );
  }

  Widget _buildHero({
    required UserResponse user,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
  }) {
    final imageUrl = user.profileImageUrl;

    return Column(
      children: [
        Container(
          width: 116,
          height: 116,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: PaceUpColors.electricCyan,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: PaceUpColors.electricCyan.withValues(
                  alpha: 0.12,
                ),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: isDark
                ? PaceUpColors.darkPanelSecondary
                : PaceUpColors.lightPanelSecondary,
            backgroundImage:
                imageUrl != null && imageUrl.trim().isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
            child: imageUrl == null || imageUrl.trim().isEmpty
                ? Icon(
                    Icons.person_outline_rounded,
                    size: 54,
                    color: mutedColor,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          user.displayName,
          textAlign: TextAlign.center,
          style: PaceUpTypography.heading(textColor).copyWith(
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '@${user.username}',
          textAlign: TextAlign.center,
          style: PaceUpTypography.bodyMedium(
            PaceUpColors.electricCyan,
          ),
        ),
        if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: PaceUpTypography.body(mutedColor),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFollowButton({
    required Color textColor,
    required bool isDark,
  }) {
    final isFollowing = _isFollowing;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: _isFollowLoading ? null : _toggleFollow,
        style: FilledButton.styleFrom(
          backgroundColor: isFollowing
              ? (isDark
                  ? PaceUpColors.darkPanelSecondary
                  : PaceUpColors.lightPanelSecondary)
              : PaceUpColors.electricGreen,
          foregroundColor: isFollowing
              ? textColor
              : PaceUpColors.greenInk,
          disabledBackgroundColor: isFollowing
              ? PaceUpColors.darkPanelSecondary
              : PaceUpColors.electricGreen,
          disabledForegroundColor: isFollowing
              ? textColor
              : PaceUpColors.greenInk,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isFollowing
                ? BorderSide(
                    color: isDark
                        ? PaceUpColors.darkBorder
                        : PaceUpColors.lightBorder,
                  )
                : BorderSide.none,
          ),
        ),
        child: _isFollowLoading
            ? SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isFollowing
                      ? PaceUpColors.electricGreen
                      : PaceUpColors.greenInk,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFollowing
                        ? Icons.person_remove_outlined
                        : Icons.person_add_outlined,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFollowing ? 'FOLLOWING' : 'FOLLOW',
                    style: PaceUpTypography.label(
                      isFollowing
                          ? textColor
                          : PaceUpColors.greenInk,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSocialSection({
    required UserResponse user,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOCIAL',
          style: PaceUpTypography.sectionTitle(
            PaceUpColors.electricGreen,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor),
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Column(
            children: [
              _SocialAction(
                icon: Icons.people_outline,
                accent: PaceUpColors.electricGreen,
                title: 'Followers',
                subtitle: 'View this athlete\'s followers',
                textColor: textColor,
                mutedColor: mutedColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FollowersScreen(
                        userId: user.id,
                      ),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                color: borderColor,
              ),
              _SocialAction(
                icon: Icons.person_add_alt_1_outlined,
                accent: PaceUpColors.electricCyan,
                title: 'Following',
                subtitle: 'View athletes they follow',
                textColor: textColor,
                mutedColor: mutedColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FollowingScreen(
                        userId: user.id,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(
    String title,
    Color accent,
  ) {
    return Text(
      title,
      style: PaceUpTypography.sectionTitle(accent),
    );
  }

  Widget _buildJoinedRow({
    required UserResponse user,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: PaceUpColors.electricCyan.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: PaceUpColors.electricCyan,
              size: 18,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Joined PaceUp',
                  style: PaceUpTypography.bodyMedium(textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(user.createdAt),
                  style: PaceUpTypography.body(mutedColor).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _SocialAction extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _SocialAction({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 15,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PaceUpTypography.bodyMedium(textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: PaceUpTypography.body(mutedColor).copyWith(
                        fontSize: 11,
                      ),
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
}

class _UserProfileLoadingState extends StatelessWidget {
  final Color backgroundColor;

  const _UserProfileLoadingState({
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
          child: Column(
            children: [
              Row(
                children: [
                  const _ProfileSkeleton(
                    width: 42,
                    height: 42,
                    radius: 21,
                  ),
                  const SizedBox(width: 14),
                  const _ProfileSkeleton(
                    width: 70,
                    height: 12,
                  ),
                  const Spacer(),
                  const _ProfileSkeleton(
                    width: 18,
                    height: 18,
                    radius: 9,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const _ProfileSkeleton(
                width: 116,
                height: 116,
                radius: 58,
              ),
              const SizedBox(height: 20),
              const _ProfileSkeleton(
                width: 170,
                height: 28,
              ),
              const SizedBox(height: 10),
              const _ProfileSkeleton(
                width: 100,
                height: 14,
              ),
              const SizedBox(height: 18),
              const _ProfileSkeleton(
                width: 240,
                height: 13,
              ),
              const SizedBox(height: 30),
              const _ProfileSkeleton(
                width: double.infinity,
                height: 50,
                radius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ProfileSkeleton({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? PaceUpColors.darkPanelSecondary
            : PaceUpColors.lightPanelSecondary,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _UserProfileErrorState extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color mutedColor;
  final String message;
  final Future<void> Function() onRetry;

  const _UserProfileErrorState({
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
            Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: mutedColor,
            ),
            const SizedBox(height: 20),
            Text(
              'PROFILE UNAVAILABLE',
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
                  style: PaceUpTypography.label(
                    PaceUpColors.greenInk,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}