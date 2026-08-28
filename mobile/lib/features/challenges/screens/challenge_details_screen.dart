import 'package:flutter/material.dart';

import '../models/challenge_models.dart';
import '../services/challenge_service.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final ChallengeResponse challenge;
  final ChallengeService challengeService;

  const ChallengeDetailsScreen({
    super.key,
    required this.challenge,
    required this.challengeService,
  });

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  ChallengeProgressResponse? _progress;
  ChallengeLeaderboardResponse? _leaderboard;

  bool _isLoading = true;
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final progress = await widget.challengeService.getProgress(
        widget.challenge.id,
      );

      final leaderboard = await widget.challengeService.getLeaderboard(
        widget.challenge.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _progress = progress;
        _leaderboard = leaderboard;
        _isLoading = false;
      });
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

  Future<void> _join() async {
    setState(() {
      _isJoining = true;
    });

    try {
      await widget.challengeService.joinChallenge(widget.challenge.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Joined challenge successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadDetails();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Challenge?'),
          content: const Text('Are you sure you want to leave this challenge?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await widget.challengeService.leaveChallenge(widget.challenge.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Left challenge.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadDetails();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _formatValue(String type, double value) {
    switch (type) {
      case 'Distance':
        return '${value.toStringAsFixed(1)} km';

      case 'Duration':
        final minutes = (value / 60).floor();
        final seconds = value.round() % 60;

        return '${minutes}m ${seconds}s';

      case 'Activities':
        return value.toStringAsFixed(0);

      default:
        return value.toStringAsFixed(1);
    }
  }

  IconData _challengeIcon(String type) {
    switch (type) {
      case 'Distance':
        return Icons.route_rounded;
      case 'Duration':
        return Icons.timer_outlined;
      case 'Activities':
        return Icons.directions_run_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: RefreshIndicator(
        onRefresh: _loadDetails,
        child: _buildBody(challenge),
      ),
    );
  }

  Widget _buildBody(ChallengeResponse challenge) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 300),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.info_outline_rounded, size: 56),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadDetails,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final progress = _progress;
    final leaderboard = _leaderboard;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Icon(_challengeIcon(challenge.type)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        challenge.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (challenge.description != null &&
                    challenge.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(challenge.description!),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(challenge.type)),
                    Chip(
                      avatar: const Icon(Icons.people_outline, size: 18),
                      label: Text('${challenge.participantCount} participants'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_formatDate(challenge.startDate)}'
                  ' → '
                  '${_formatDate(challenge.endDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (progress != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress.progressPercentage / 100,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatValue(progress.type, progress.currentValue),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(_formatValue(progress.type, progress.targetValue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress.isCompleted
                        ? 'Challenge completed! 🎉'
                        : '${progress.progressPercentage.toStringAsFixed(1)}% complete',
                  ),
                  if (!progress.isCompleted) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_formatValue(progress.type, progress.remainingValue)} remaining',
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _isJoining
              ? const Center(child: CircularProgressIndicator())
              : _progress == null
              ? FilledButton.icon(
                  onPressed: _join,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Join Challenge'),
                )
              : OutlinedButton.icon(
                  onPressed: _leave,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Leave Challenge'),
                ),
        ),
        const SizedBox(height: 24),
        if (leaderboard != null) ...[
          Text(
            'Leaderboard',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (leaderboard.participants.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No participants yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: leaderboard.participants
                    .map(
                      (participant) => ListTile(
                        leading: CircleAvatar(
                          child: Text('${participant.rank}'),
                        ),
                        title: Text(participant.displayName),
                        subtitle: Text('@${participant.username}'),
                        trailing: Text(
                          _formatValue(
                            challenge.type,
                            participant.currentValue,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ],
    );
  }
}
