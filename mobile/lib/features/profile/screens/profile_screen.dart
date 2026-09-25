import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/profile_models.dart';
import '../services/profile_service.dart';
import '../../social/screens/followers_screen.dart';
import '../../social/screens/following_screen.dart';
import '../../social/screens/user_search_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_state.dart';
import '../../achievements/screens/achievements_screen.dart';
import '../../leaderboards/screens/leaderboard_screen.dart';
import '../../personal_records/screens/personal_records_screen.dart';
import '../../social/services/social_service.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileService? profileService;
  final AuthController? authController;

  const ProfileScreen({super.key, this.profileService, this.authController});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profileService;
  late final SocialService _socialService;

  UserResponse? _user;
  int _followerCount = 0;
  int _followingCount = 0;

  bool _isLoading = true;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _profileService = widget.profileService ?? ProfileService();
    _socialService = SocialService();

    _loadProfile();
  }

  @override
  void dispose() {
    if (widget.profileService == null) {
      _profileService.dispose();
    }

    _socialService.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _profileService.getMe();

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _isLoading = false;
      });

      _loadSocialCounts(user.id);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSocialCounts(String userId) async {
    try {
      final results = await Future.wait([
        _socialService.getFollowers(userId),
        _socialService.getFollowing(userId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _followerCount = results[0].users.length;
        _followingCount = results[1].users.length;
      });
    } catch (_) {
      // Keep the profile usable if social counts fail.
    }
  }

  Future<void> _editProfile() async {
    final user = _user;

    if (user == null) {
      return;
    }

    final updatedUser = await showDialog<UserResponse>(
      context: context,
      builder: (_) =>
          _EditProfileDialog(user: user, profileService: _profileService),
    );

    if (!mounted || updatedUser == null) {
      return;
    }

    setState(() {
      _user = updatedUser;
    });

    _showMessage('Profile updated.');
  }

  Future<void> _editProfileImage() async {
    final picker = ImagePicker();

    final image = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;

        final panelColor = isDark
            ? PaceUpColors.darkPanel
            : PaceUpColors.lightPanel;

        final textColor = isDark
            ? PaceUpColors.darkText
            : PaceUpColors.lightText;

        final mutedColor = isDark
            ? PaceUpColors.darkMuted
            : PaceUpColors.lightMuted;

        return Container(
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: mutedColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text(
                        'PROFILE PHOTO',
                        style: PaceUpTypography.sectionTitle(
                          PaceUpColors.electricGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ImagePickerOption(
                    icon: Icons.photo_library_outlined,
                    title: 'Choose from Gallery',
                    subtitle: 'Select an existing photo',
                    textColor: textColor,
                    mutedColor: mutedColor,
                    onTap: () async {
                      final selected = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1200,
                        maxHeight: 1200,
                      );

                      if (!sheetContext.mounted) {
                        return;
                      }

                      Navigator.of(sheetContext).pop(selected);
                    },
                  ),
                  const SizedBox(height: 8),
                  _ImagePickerOption(
                    icon: Icons.camera_alt_outlined,
                    title: 'Take a Photo',
                    subtitle: 'Use your camera',
                    textColor: textColor,
                    mutedColor: mutedColor,
                    onTap: () async {
                      final selected = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                        maxWidth: 1200,
                        maxHeight: 1200,
                      );

                      if (!sheetContext.mounted) {
                        return;
                      }

                      Navigator.of(sheetContext).pop(selected);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || image == null) {
      return;
    }

    try {
      final updated = await _profileService.updateProfileImage(image);

      if (!mounted) {
        return;
      }

      setState(() {
        _user = updated;
      });

      _showMessage('Profile image updated.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: PaceUpColors.electricGreen.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: PaceUpColors.electricGreen.withValues(alpha: 0.08),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: PaceUpColors.electricGreen.withValues(
                          alpha: 0.10,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PaceUpColors.electricGreen.withValues(
                            alpha: 0.30,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: PaceUpColors.electricGreen,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'LOG OUT',
                        style: PaceUpTypography.heading(PaceUpColors.darkText)
                            .copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  'Are you sure you want to log out of PaceUp?',
                  style: PaceUpTypography.body(PaceUpColors.darkText)
                      .copyWith(fontSize: 15, height: 1.45),
                ),

                const SizedBox(height: 12),

                Text(
                  'You can sign back in anytime using your account credentials.',
                  style: PaceUpTypography.body(PaceUpColors.darkMuted)
                      .copyWith(fontSize: 13, height: 1.45),
                ),

                const SizedBox(height: 18),

                // Information box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PaceUpColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: PaceUpColors.electricGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your PaceUp data will remain safe and available when you sign in again.',
                          style: PaceUpTypography.body(PaceUpColors.darkMuted)
                              .copyWith(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PaceUpColors.darkText,
                          side: const BorderSide(
                            color: PaceUpColors.darkBorder,
                          ),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: PaceUpTypography.label(PaceUpColors.darkText),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: PaceUpColors.electricGreen,
                          foregroundColor: PaceUpColors.greenInk,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'LOG OUT',
                          style: PaceUpTypography.label(PaceUpColors.greenInk),
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

    final authController = widget.authController;

    if (authController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout is currently unavailable.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await authController.logout();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(authController: authController),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: PaceUpColors.darkPanel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: PaceUpColors.danger.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: PaceUpColors.danger.withValues(alpha: 0.10),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: PaceUpColors.danger.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PaceUpColors.danger.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: PaceUpColors.danger,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'DELETE ACCOUNT',
                        style: PaceUpTypography.heading(PaceUpColors.darkText)
                            .copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Are you sure you want to permanently delete your account?',
                  style: PaceUpTypography.body(PaceUpColors.darkText)
                      .copyWith(fontSize: 15, height: 1.45),
                ),
                const SizedBox(height: 12),
                Text(
                  'This action cannot be undone. Your profile, activities, goals, challenges, achievements and other account data will be permanently deleted.',
                  style: PaceUpTypography.body(PaceUpColors.darkMuted)
                      .copyWith(fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PaceUpColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: PaceUpColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You will be signed out after your account is deleted.',
                          style: PaceUpTypography.body(PaceUpColors.darkMuted)
                              .copyWith(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PaceUpColors.darkText,
                          side: const BorderSide(
                            color: PaceUpColors.darkBorder,
                          ),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: PaceUpTypography.label(PaceUpColors.darkText),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: PaceUpColors.danger,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'DELETE',
                          style: PaceUpTypography.label(Colors.white),
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
      await _profileService.deleteAccount();

      if (!mounted) {
        return;
      }

      final authController = widget.authController;

      if (authController == null) {
        Navigator.of(context).pop();
        return;
      }

      await authController.logout();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(authController: authController),
        ),
        (route) => false,
      );
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

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? PaceUpColors.danger
            : PaceUpColors.darkPanelSecondary,
      ),
    );
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
      return _ProfileLoadingState(backgroundColor: backgroundColor);
    }

    if (_errorMessage != null) {
      return _ProfileErrorState(
        backgroundColor: backgroundColor,
        textColor: textColor,
        mutedColor: mutedColor,
        message: _errorMessage!,
        onRetry: _loadProfile,
      );
    }

    final user = _user;

    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            'PROFILE UNAVAILABLE',
            style: PaceUpTypography.heading(textColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: PaceUpColors.electricGreen,
          backgroundColor: isDark
              ? PaceUpColors.darkPanel
              : PaceUpColors.lightPanel,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
            children: [
              _buildHeader(textColor: textColor, mutedColor: mutedColor),
              const SizedBox(height: 28),
              _buildHero(
                user: user,
                isDark: isDark,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 30),
              _buildSocialStats(
                user: user,
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              const SizedBox(height: 32),
              _buildSectionLabel('PERFORMANCE', PaceUpColors.electricGreen),
              const SizedBox(height: 12),
              _buildPerformanceList(
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              const SizedBox(height: 32),
              _buildSectionLabel('ACCOUNT', PaceUpColors.electricCyan),
              const SizedBox(height: 12),
              _buildAccountList(
                textColor: textColor,
                mutedColor: mutedColor,
                isDark: isDark,
              ),
              const SizedBox(height: 32),
              _buildSectionLabel('DANGER ZONE', PaceUpColors.danger),
              const SizedBox(height: 12),
              _buildDangerList(
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

  Widget _buildHeader({required Color textColor, required Color mutedColor}) {
    return Row(
      children: [
        const Spacer(),
        _HeaderButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit profile',
          onTap: _editProfile,
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
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 116,
              height: 116,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: PaceUpColors.electricGreen, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: PaceUpColors.electricGreen.withValues(alpha: 0.14),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: isDark
                    ? PaceUpColors.darkPanelSecondary
                    : PaceUpColors.lightPanelSecondary,
                backgroundImage: imageUrl != null && imageUrl.trim().isNotEmpty
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
            Positioned(
              right: -4,
              bottom: 2,
              child: GestureDetector(
                onTap: _editProfileImage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: PaceUpColors.electricGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? PaceUpColors.darkBackground
                          : PaceUpColors.lightBackground,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 17,
                    color: PaceUpColors.greenInk,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          user.displayName,
          textAlign: TextAlign.center,
          style: PaceUpTypography.heading(textColor).copyWith(fontSize: 32),
        ),
        const SizedBox(height: 3),
        Text(
          '@${user.username}',
          textAlign: TextAlign.center,
          style: PaceUpTypography.bodyMedium(PaceUpColors.electricCyan),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            user.bio?.isNotEmpty == true ? user.bio! : 'No bio yet.',
            textAlign: TextAlign.center,
            style: PaceUpTypography.body(mutedColor),
          ),
        ),
        const SizedBox(height: 11),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 12, color: mutedColor),
            const SizedBox(width: 6),
            Text(
              'MEMBER SINCE ${_formatDate(user.createdAt)}',
              style: PaceUpTypography.label(mutedColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialStats({
    required UserResponse user,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SocialStat(
              value: _followerCount.toString(),
              label: 'FOLLOWERS',
              textColor: textColor,
              mutedColor: mutedColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FollowersScreen(userId: user.id),
                  ),
                );
              },
            ),
          ),
          Container(width: 1, height: 36, color: borderColor),
          Expanded(
            child: _SocialStat(
              value: _followingCount.toString(),
              label: 'FOLLOWING',
              textColor: textColor,
              mutedColor: mutedColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FollowingScreen(userId: user.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, Color accent) {
    return Text(title, style: PaceUpTypography.sectionTitle(accent));
  }

  Widget _buildPerformanceList({
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return _ActionList(
      isDark: isDark,
      children: [
        _ProfileAction(
          icon: Icons.emoji_events_outlined,
          accent: PaceUpColors.electricGreen,
          title: 'Achievements',
          subtitle: 'Track your unlocked milestones',
          textColor: textColor,
          mutedColor: mutedColor,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            );
          },
        ),
        _ProfileAction(
          icon: Icons.leaderboard_outlined,
          accent: PaceUpColors.electricCyan,
          title: 'Leaderboard',
          subtitle: 'See how you rank this week',
          textColor: textColor,
          mutedColor: mutedColor,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            );
          },
        ),
        _ProfileAction(
          icon: Icons.speed_outlined,
          accent: const Color(0xFFFFC857),
          title: 'Personal Records',
          subtitle: 'View your best performances',
          textColor: textColor,
          mutedColor: mutedColor,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PersonalRecordsScreen()),
            );
          },
        ),
        _ProfileAction(
          icon: Icons.person_search_outlined,
          accent: PaceUpColors.electricCyan,
          title: 'Find Users',
          subtitle: 'Discover athletes in PaceUp',
          textColor: textColor,
          mutedColor: mutedColor,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const UserSearchScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildAccountList({
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return _ActionList(
      isDark: isDark,
      children: [
        _ProfileAction(
          icon: Icons.edit_outlined,
          accent: PaceUpColors.electricGreen,
          title: 'Edit Profile',
          subtitle: 'Update your name and bio',
          textColor: textColor,
          mutedColor: mutedColor,
          onTap: _editProfile,
        ),
        _ProfileAction(
          icon: Icons.logout_outlined,
          accent: mutedColor,
          title: 'Logout',
          subtitle: 'Sign out of your PaceUp account',
          textColor: textColor,
          mutedColor: mutedColor,
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildDangerList({
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return _ActionList(
      isDark: isDark,
      children: [
        _ProfileAction(
          icon: Icons.delete_outline_rounded,
          accent: PaceUpColors.danger,
          title: _isDeleting ? 'Deleting Account...' : 'Delete Account',
          subtitle: _isDeleting
              ? 'Please wait while your account is deleted'
              : 'Permanently delete your account',
          textColor: textColor,
          mutedColor: mutedColor,
          onTap: _isDeleting ? () {} : _deleteAccount,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: isDark
            ? PaceUpColors.darkPanelSecondary
            : PaceUpColors.lightPanelSecondary,
        foregroundColor: isDark
            ? PaceUpColors.darkText
            : PaceUpColors.lightText,
        minimumSize: const Size(42, 42),
      ),
      icon: Icon(icon, size: 19),
    );
  }
}

class _SocialStat extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _SocialStat({
    required this.value,
    required this.label,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: PaceUpTypography.largeMetric(textColor)),
          const SizedBox(height: 3),
          Text(label, style: PaceUpTypography.label(mutedColor)),
        ],
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _ActionList({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: List.generate(
          children.length,
          (index) => Column(
            children: [
              children[index],
              if (index < children.length - 1)
                Divider(height: 1, color: borderColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _ProfileAction({
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
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 19),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: PaceUpTypography.bodyMedium(textColor)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
}

class _ImagePickerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _ImagePickerOption({
    required this.icon,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PaceUpColors.electricGreen.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: PaceUpColors.electricGreen, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: PaceUpTypography.bodyMedium(textColor)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
}

class _ProfileLoadingState extends StatelessWidget {
  final Color backgroundColor;

  const _ProfileLoadingState({required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          child: Column(
            children: [
              Row(
                children: [
                  const _Skeleton(width: 74, height: 12),
                  const Spacer(),
                  _Skeleton(width: 42, height: 42, radius: 21),
                ],
              ),
              const SizedBox(height: 38),
              const _Skeleton(width: 116, height: 116, radius: 58),
              const SizedBox(height: 20),
              const _Skeleton(width: 170, height: 28),
              const SizedBox(height: 10),
              const _Skeleton(width: 100, height: 14),
              const SizedBox(height: 18),
              const _Skeleton(width: 250, height: 13),
              const SizedBox(height: 36),
              const _Skeleton(width: double.infinity, height: 76, radius: 0),
              const SizedBox(height: 34),
              const _Skeleton(width: 90, height: 12),
              const SizedBox(height: 14),
              const _Skeleton(width: double.infinity, height: 210, radius: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color mutedColor;
  final String message;
  final Future<void> Function() onRetry;

  const _ProfileErrorState({
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

class _Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Skeleton({required this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

class _EditProfileDialog extends StatefulWidget {
  final UserResponse user;
  final ProfileService profileService;

  const _EditProfileDialog({required this.user, required this.profileService});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController(
      text: widget.user.displayName,
    );

    _bioController = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final displayName = _displayNameController.text.trim();

    if (displayName.isEmpty) {
      setState(() {
        _errorMessage = 'Display name is required.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await widget.profileService.updateProfile(
        UpdateProfileRequest(
          displayName: displayName,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: PaceUpColors.darkPanel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: PaceUpColors.electricGreen.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: PaceUpColors.electricGreen.withValues(alpha: 0.08),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: PaceUpColors.electricGreen.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: PaceUpColors.electricGreen.withValues(
                          alpha: 0.30,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: PaceUpColors.electricGreen,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'EDIT PROFILE',
                      style: PaceUpTypography.heading(PaceUpColors.darkText)
                          .copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Display Name
              Text(
                'DISPLAY NAME',
                style: PaceUpTypography.label(PaceUpColors.darkMuted)
                    .copyWith(fontSize: 10, letterSpacing: 1.2),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _displayNameController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                style: PaceUpTypography.body(PaceUpColors.darkText)
                    .copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter your display name',
                  hintStyle: PaceUpTypography.body(PaceUpColors.darkMuted)
                      .copyWith(fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: PaceUpColors.electricGreen,
                    size: 21,
                  ),
                  filled: true,
                  fillColor: PaceUpColors.darkPanelSecondary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: PaceUpColors.darkBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: PaceUpColors.darkBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: PaceUpColors.electricGreen,
                      width: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Bio
              Text(
                'BIO',
                style: PaceUpTypography.label(PaceUpColors.darkMuted)
                    .copyWith(fontSize: 10, letterSpacing: 1.2),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _bioController,
                enabled: !_isSaving,
                maxLines: 4,
                maxLength: 180,
                textInputAction: TextInputAction.newline,
                style: PaceUpTypography.body(PaceUpColors.darkText)
                    .copyWith(fontSize: 14, height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Tell people a little about yourself',
                  hintStyle: PaceUpTypography.body(PaceUpColors.darkMuted)
                      .copyWith(fontSize: 14),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(
                      Icons.description_outlined,
                      color: PaceUpColors.electricGreen,
                      size: 21,
                    ),
                  ),
                  filled: true,
                  fillColor: PaceUpColors.darkPanelSecondary,
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: PaceUpColors.darkBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: PaceUpColors.darkBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: PaceUpColors.electricGreen,
                      width: 1.2,
                    ),
                  ),
                  counterStyle: PaceUpTypography.body(PaceUpColors.darkMuted)
                      .copyWith(fontSize: 10),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: PaceUpColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: PaceUpColors.danger.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: PaceUpColors.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: PaceUpTypography.body(PaceUpColors.danger)
                              .copyWith(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PaceUpColors.darkText,
                        disabledForegroundColor: PaceUpColors.darkMuted,
                        side: const BorderSide(color: PaceUpColors.darkBorder),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: PaceUpTypography.label(PaceUpColors.darkText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: PaceUpColors.electricGreen,
                        foregroundColor: PaceUpColors.greenInk,
                        disabledBackgroundColor: PaceUpColors.electricGreen
                            .withValues(alpha: 0.35),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: PaceUpColors.greenInk,
                              ),
                            )
                          : Text(
                              'SAVE',
                              style: PaceUpTypography.label(
                                PaceUpColors.greenInk,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
