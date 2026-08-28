import 'package:flutter/material.dart';

import '../models/challenge_models.dart';
import '../services/challenge_service.dart';
import 'add_challenge_screen.dart';
import 'challenge_details_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late final ChallengeService _challengeService;

  bool _isLoading = true;
  String? _errorMessage;
  List<ChallengeResponse> _challenges = [];

  @override
  void initState() {
    super.initState();
    _challengeService = ChallengeService();
    _loadChallenges();
  }

  @override
  void dispose() {
    _challengeService.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final challenges = await _challengeService.getChallenges();

      if (!mounted) {
        return;
      }

      setState(() {
        _challenges = challenges;
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

  Future<void> _openCreateChallenge() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddChallengeScreen(challengeService: _challengeService),
      ),
    );

    if (created == true && mounted) {
      await _loadChallenges();
    }
  }

  Future<void> _openChallenge(ChallengeResponse challenge) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeDetailsScreen(
          challenge: challenge,
          challengeService: _challengeService,
        ),
      ),
    );

    if (mounted) {
      await _loadChallenges();
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _formatTarget(ChallengeResponse challenge) {
    switch (challenge.type) {
      case 'Distance':
        return '${challenge.targetValue.toStringAsFixed(1)} km';

      case 'Duration':
        final minutes = (challenge.targetValue / 60).round();
        return '$minutes min';

      case 'Activities':
        return '${challenge.targetValue.toStringAsFixed(0)} activities';

      default:
        return challenge.targetValue.toString();
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
    return Scaffold(
      body: RefreshIndicator(onRefresh: _loadChallenges, child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateChallenge,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 56),
                  const SizedBox(height: 16),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadChallenges,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_challenges.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No challenges yet',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a challenge and start competing with your friends.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _openCreateChallenge,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Challenge'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _challenges.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final challenge = _challenges[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openChallenge(challenge),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    child: Icon(_challengeIcon(challenge.type)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (challenge.description != null &&
                            challenge.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            challenge.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: Icon(
                                _challengeIcon(challenge.type),
                                size: 18,
                              ),
                              label: Text(challenge.type),
                            ),
                            Chip(label: Text(_formatTarget(challenge))),
                            Chip(
                              avatar: const Icon(
                                Icons.people_outline,
                                size: 18,
                              ),
                              label: Text('${challenge.participantCount}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatDate(challenge.startDate)}'
                          ' → '
                          '${_formatDate(challenge.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
