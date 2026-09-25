import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/social_models.dart';
import '../services/social_service.dart';
import 'user_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final SocialService _socialService = SocialService();
  final TextEditingController _searchController =
      TextEditingController();

  Timer? _debounce;

  List<UserSearchResult> _users = [];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _socialService.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    setState(() {});

    if (query.isEmpty) {
      setState(() {
        _users = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () {
        _searchUsers(query);
      },
    );
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _socialService.searchUsers(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();

    setState(() {
      _users = [];
      _isLoading = false;
      _errorMessage = null;
    });
  }

  void _openUserProfile(UserSearchResult user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: user.id,
        ),
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

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final secondaryPanelColor = isDark
        ? PaceUpColors.darkPanelSecondary
        : PaceUpColors.lightPanelSecondary;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    final textColor = isDark
        ? PaceUpColors.darkText
        : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textColor,
          ),
        ),
        titleSpacing: 4,
        title: Text(
          'FIND ATHLETES',
          style: PaceUpTypography.heading(textColor).copyWith(
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              child: _buildSearchField(
                secondaryPanelColor: secondaryPanelColor,
                borderColor: borderColor,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor:
                        PaceUpColors.darkPanelSecondary,
                    color: PaceUpColors.electricCyan,
                  ),
                ),
              ),
            Expanded(
              child: _buildResults(
                panelColor: panelColor,
                borderColor: borderColor,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required Color secondaryPanelColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      style: PaceUpTypography.body(textColor),
      cursorColor: PaceUpColors.electricCyan,
      decoration: InputDecoration(
        hintText: 'Search username or name',
        hintStyle: PaceUpTypography.body(mutedColor),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: PaceUpColors.electricCyan,
          size: 21,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: _clearSearch,
                icon: Icon(
                  Icons.close_rounded,
                  color: mutedColor,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: secondaryPanelColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: PaceUpColors.electricCyan,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildResults({
    required Color panelColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    if (_errorMessage != null) {
      return _buildErrorState(
        textColor: textColor,
        mutedColor: mutedColor,
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return _buildInitialState(
        textColor: textColor,
        mutedColor: mutedColor,
      );
    }

    if (!_isLoading && _users.isEmpty) {
      return _buildNoResultsState(
        textColor: textColor,
        mutedColor: mutedColor,
      );
    }

    if (_isLoading && _users.isEmpty) {
      return const _SearchLoadingState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
      itemCount: _users.length,
      separatorBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(left: 58),
        child: Divider(
          height: 1,
          color: borderColor,
        ),
      ),
      itemBuilder: (context, index) {
        final user = _users[index];

        return _UserSearchRow(
          user: user,
          textColor: textColor,
          mutedColor: mutedColor,
          onTap: () => _openUserProfile(user),
        );
      },
    );
  }

  Widget _buildInitialState({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                border: Border.all(
                  color: PaceUpColors.electricCyan
                      .withValues(alpha: 0.35),
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: PaceUpColors.electricCyan,
                size: 32,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'FIND YOUR PEOPLE',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.electricCyan,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by username or display name to discover '
              'athletes on PaceUp.',
              textAlign: TextAlign.center,
              style: PaceUpTypography.body(mutedColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 46,
              color: mutedColor,
            ),
            const SizedBox(height: 18),
            Text(
              'NO ATHLETES FOUND',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.electricCyan,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different username or display name.',
              textAlign: TextAlign.center,
              style: PaceUpTypography.body(mutedColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: mutedColor,
            ),
            const SizedBox(height: 18),
            Text(
              'SEARCH UNAVAILABLE',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.electricCyan,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: PaceUpTypography.body(mutedColor),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                final query =
                    _searchController.text.trim();

                if (query.isNotEmpty) {
                  _searchUsers(query);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: PaceUpColors.electricCyan,
                foregroundColor: PaceUpColors.darkBackground,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'TRY AGAIN',
                style: PaceUpTypography.label(
                  PaceUpColors.darkBackground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSearchRow extends StatelessWidget {
  final UserSearchResult user;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _UserSearchRow({
    required this.user,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        user.profileImageUrl != null &&
        user.profileImageUrl!.trim().isNotEmpty;

    final initial = user.displayName.trim().isEmpty
        ? '?'
        : user.displayName.trim()[0].toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 13,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PaceUpColors.electricCyan
                    .withValues(alpha: 0.08),
                border: Border.all(
                  color: PaceUpColors.electricCyan
                      .withValues(alpha: 0.30),
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: hasImage
                    ? Image.network(
                        user.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return _buildInitial(initial);
                        },
                      )
                    : _buildInitial(initial),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PaceUpTypography.bodyMedium(
                      textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PaceUpTypography.body(
                      mutedColor,
                    ).copyWith(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: PaceUpColors.electricCyan,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: PaceUpTypography.bodyMedium(
          PaceUpColors.electricCyan,
        ),
      ),
    );
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
      children: const [
        _SearchSkeleton(),
        _SearchSkeleton(),
        _SearchSkeleton(),
        _SearchSkeleton(),
      ],
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
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
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 135,
                  height: 11,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 90,
                  height: 8,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}