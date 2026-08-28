import 'package:flutter/material.dart';

import '../../profile/models/profile_models.dart';
import '../../profile/services/profile_service.dart';
import '../services/social_service.dart';
import 'followers_screen.dart';
import 'following_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

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
      // Get the currently logged-in user first.
      final currentUser = await _profileService.getMe();

      final isOwnProfile = currentUser.id == widget.userId;

      // If this is our own profile, we already have the user data.
      // Otherwise, load the profile of the user we're viewing.
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
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
          content: Text(e.toString().replaceFirst('Exception: ', '')),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadUser,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('User unavailable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(user.displayName)),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            Center(
              child: CircleAvatar(
                radius: 54,
                backgroundImage:
                    user.profileImageUrl != null &&
                        user.profileImageUrl!.trim().isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child:
                    user.profileImageUrl == null ||
                        user.profileImageUrl!.trim().isEmpty
                    ? const Icon(Icons.person, size: 54)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                user.displayName,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '@${user.username}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.bio!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Follow / Unfollow
            if (!_isOwnProfile)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isFollowLoading ? null : _toggleFollow,
                  icon: _isFollowLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isFollowing
                              ? Icons.person_remove_outlined
                              : Icons.person_add_outlined,
                        ),
                  label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                ),
              ),

            const SizedBox(height: 24),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('Followers'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FollowersScreen(userId: user.id),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1_outlined),
                    title: const Text('Following'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FollowingScreen(userId: user.id),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Joined'),
                subtitle: Text(_formatDate(user.createdAt)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
