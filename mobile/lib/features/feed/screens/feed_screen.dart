import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../comments/widgets/comments_sheet.dart';
import '../../profile/services/profile_service.dart';
import '../models/feed_models.dart';
import '../services/feed_service.dart';
import '../widgets/feed_activity_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedService _feedService = FeedService();
  final ScrollController _scrollController = ScrollController();
  final ProfileService _profileService = ProfileService();

  final List<FeedActivityResponse> _activities = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;

  String? _errorMessage;
  String? _currentUserId;

  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser =
          await _profileService.getMe();

      final response = await _feedService.getFeed(
        page: 1,
        pageSize: 20,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUserId = currentUser.id;

        _activities
          ..clear()
          ..addAll(response.activities);

        _currentPage = response.page;
        _totalPages = response.totalPages;

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _refreshFeed() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      final response = await _feedService.getFeed(
        page: 1,
        pageSize: 20,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activities
          ..clear()
          ..addAll(response.activities);

        _currentPage = response.page;
        _totalPages = response.totalPages;
        _errorMessage = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore ||
        _isLoading ||
        _currentPage >= _totalPages) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _feedService.getFeed(
        page: _currentPage + 1,
        pageSize: 20,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activities.addAll(response.activities);
        _currentPage = response.page;
        _totalPages = response.totalPages;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load more activities: $error',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    _feedService.dispose();
    _profileService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

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
      return _LoadingState(
        backgroundColor: backgroundColor,
      );
    }

    if (_errorMessage != null &&
        _activities.isEmpty) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _loadFeed,
        backgroundColor: backgroundColor,
        textColor: textColor,
        mutedColor: mutedColor,
      );
    }

    if (_activities.isEmpty) {
      return _EmptyState(
        onRefresh: _refreshFeed,
        backgroundColor: backgroundColor,
        textColor: textColor,
        mutedColor: mutedColor,
      );
    }

    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        onRefresh: _refreshFeed,
        color: PaceUpColors.electricGreen,
        backgroundColor: isDark
            ? PaceUpColors.darkPanel
            : PaceUpColors.lightPanel,
        child: CustomScrollView(
          controller: _scrollController,
          physics:
              const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(
                textColor: textColor,
                mutedColor: mutedColor,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                4,
                20,
                110,
              ),
              sliver: SliverList.builder(
                itemCount: _activities.length +
                    (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _activities.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 24,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            color:
                                PaceUpColors.electricGreen,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  }

                  final activity =
                      _activities[index];

                  return Column(
                    children: [
                      if (index == 0)
                        _buildLatestLabel(
                          mutedColor,
                        ),
                      FeedActivityCard(
                        activity: activity,
                        currentUserId:
                            _currentUserId,
                      ),
                      _buildCommentsAction(
                        activity,
                        mutedColor,
                      ),
                      if (index <
                          _activities.length - 1)
                        _buildFeedDivider(
                          isDark,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        16,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  'Your community.',
                  style: PaceUpTypography.heading(
                    textColor,
                  ).copyWith(
                    fontSize: 29,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'See what everyone is moving today.',
                  style: PaceUpTypography.body(
                    mutedColor,
                  ).copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration:
                const Duration(milliseconds: 180),
            child: _isRefreshing
                ? const SizedBox(
                    key: ValueKey('refreshing'),
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          PaceUpColors.electricGreen,
                    ),
                  )
                : Container(
                    key: const ValueKey('idle'),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: PaceUpColors.darkBorder,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.dynamic_feed_rounded,
                      size: 16,
                      color: mutedColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestLabel(Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 2,
      ),
      child: Row(
        children: [
          Text(
            'LATEST',
            style: PaceUpTypography.label(
              mutedColor,
            ).copyWith(
              fontSize: 8,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              height: 1,
              color: PaceUpColors.darkBorder
                  .withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedDivider(bool isDark) {
    return Container(
      height: 1,
      color: (isDark
              ? PaceUpColors.darkBorder
              : PaceUpColors.lightBorder)
          .withValues(alpha: 0.65),
    );
  }

  Widget _buildCommentsAction(
    FeedActivityResponse activity,
    Color mutedColor,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          showCommentsSheet(
            context,
            activity.id,
            currentUserId: _currentUserId,
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: mutedColor,
          padding: const EdgeInsets.only(
            left: 2,
            right: 8,
            top: 3,
            bottom: 7,
          ),
          minimumSize: Size.zero,
          tapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 15,
        ),
        label: Text(
          'COMMENTS',
          style: PaceUpTypography.label(
            mutedColor,
          ).copyWith(
            fontSize: 8,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final Color backgroundColor;

  const _LoadingState({
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        32,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _SkeletonBar(
            width: 62,
            height: 9,
          ),
          const SizedBox(height: 10),
          _SkeletonBar(
            width: 190,
            height: 30,
          ),
          const SizedBox(height: 8),
          _SkeletonBar(
            width: 220,
            height: 11,
          ),
          const SizedBox(height: 34),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (_, index) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 24,
                  ),
                  child: _FeedSkeleton(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBar({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: PaceUpColors.darkPanelSecondary,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color:
                    PaceUpColors.darkPanelSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _SkeletonBar(
                  width: 100,
                  height: 9,
                ),
                SizedBox(height: 7),
                _SkeletonBar(
                  width: 72,
                  height: 7,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    PaceUpColors.electricGreen,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _SkeletonBar(
                  width: 55,
                  height: 7,
                ),
                SizedBox(height: 6),
                _SkeletonBar(
                  width: 85,
                  height: 20,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(
              child: _SkeletonBar(
                width: double.infinity,
                height: 28,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _SkeletonBar(
                width: double.infinity,
                height: 28,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Color backgroundColor;
  final Color textColor;
  final Color mutedColor;

  const _EmptyState({
    required this.onRefresh,
    required this.backgroundColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: PaceUpColors.electricGreen,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            28,
            150,
            28,
            32,
          ),
          children: [
            Icon(
              Icons.dynamic_feed_outlined,
              size: 48,
              color: mutedColor,
            ),
            const SizedBox(height: 20),
            Text(
              'YOUR FEED IS QUIET',
              textAlign: TextAlign.center,
              style:
                  PaceUpTypography.sectionTitle(
                PaceUpColors.electricGreen,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Follow other athletes to see their '
              'activities here.',
              textAlign: TextAlign.center,
              style: PaceUpTypography.body(
                mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color backgroundColor;
  final Color textColor;
  final Color mutedColor;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.backgroundColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: mutedColor,
            ),
            const SizedBox(height: 18),
            Text(
              'FEED UNAVAILABLE',
              style:
                  PaceUpTypography.sectionTitle(
                PaceUpColors.electricGreen,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PaceUpTypography.body(
                mutedColor,
              ),
            ),
            const SizedBox(height: 22),
            TextButton(
              onPressed: onRetry,
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
}