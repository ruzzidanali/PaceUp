import 'package:flutter/material.dart';

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

  final List<FeedActivityResponse> _activities = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _feedService.getFeed(page: 1, pageSize: 20);

      if (!mounted) return;

      setState(() {
        _activities
          ..clear()
          ..addAll(response.activities);

        _currentPage = response.page;
        _totalPages = response.totalPages;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _refreshFeed() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final response = await _feedService.getFeed(page: 1, pageSize: 20);

      if (!mounted) return;

      setState(() {
        _activities
          ..clear()
          ..addAll(response.activities);

        _currentPage = response.page;
        _totalPages = response.totalPages;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
      });
    }

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isLoading || _currentPage >= _totalPages) {
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

      if (!mounted) return;

      setState(() {
        _activities.addAll(response.activities);
        _currentPage = response.page;
        _totalPages = response.totalPages;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more activities: $error')),
      );
    }

    if (!mounted) return;

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _feedService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _activities.isEmpty) {
      return _ErrorState(message: _errorMessage!, onRetry: _loadFeed);
    }

    if (_activities.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshFeed,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: Text('No activities in your feed yet.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _activities.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _activities.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final activity = _activities[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FeedActivityCard(activity: activity),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Unable to load your feed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
