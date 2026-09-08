import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../comments/models/comment_models.dart';
import '../../comments/services/comment_service.dart';
import '../../kudos/models/kudos_models.dart';
import '../../kudos/services/kudos_service.dart';
import '../models/activity_models.dart';
import '../services/activity_service.dart';
import 'add_activity_screen.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final ActivityResponse activity;
  const ActivityDetailsScreen({super.key, required this.activity});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  late final ActivityService _activityService;
  late final KudosService _kudosService;
  late final CommentService _commentService;
  late ActivityResponse _activity;
  KudosResponse? _kudos;
  List<CommentResponse> _comments = [];
  final _commentController = TextEditingController();
  String? _currentUserId;
  String? _commentsError;
  bool _isOwnActivity = false;
  bool _isDeleting = false;
  bool _isLoadingKudos = true;
  bool _isUpdatingKudos = false;
  bool _isLoadingComments = true;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
    _activityService = ActivityService();
    _kudosService = KudosService();
    _commentService = CommentService();
    _loadActivityState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _activityService.dispose();
    _kudosService.dispose();
    _commentService.dispose();
    super.dispose();
  }

  Future<void> _loadActivityState() async {
    try {
      final auth = AuthService();
      try {
        final user = await auth.getCurrentUser();
        if (!mounted) return;
        setState(() {
          _currentUserId = user.id;
          _isOwnActivity = user.id == _activity.userId;
        });
      } finally {
        auth.dispose();
      }
      if (_isOwnActivity) {
        if (mounted) setState(() => _isLoadingKudos = false);
        return;
      }
      final kudos = await _kudosService.getKudos(_activity.id);
      if (mounted) setState(() {
        _kudos = kudos;
        _isLoadingKudos = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingKudos = false);
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _commentService.getComments(_activity.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _commentsError = null;
        _isLoadingComments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _commentsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isPostingComment) return;
    FocusScope.of(context).unfocus();
    setState(() => _isPostingComment = true);
    try {
      final comment = await _commentService.createComment(_activity.id, content);
      if (!mounted) return;
      setState(() {
        _comments.add(comment);
        _commentController.clear();
        _isPostingComment = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPostingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _deleteComment(CommentResponse comment) async {
    try {
      await _commentService.deleteComment(_activity.id, comment.id);
      if (mounted) setState(() => _comments.removeWhere((x) => x.id == comment.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _toggleKudos() async {
    final kudos = _kudos;
    if (kudos == null || _isUpdatingKudos) return;
    setState(() => _isUpdatingKudos = true);
    try {
      final updated = kudos.hasGivenKudos
          ? await _kudosService.removeKudos(_activity.id)
          : await _kudosService.giveKudos(_activity.id);
      if (mounted) setState(() {
        _kudos = updated;
        _isUpdatingKudos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingKudos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _editActivity() async {
    final updated = await Navigator.of(context).push<ActivityResponse>(
      MaterialPageRoute(builder: (_) => AddActivityScreen(activity: _activity)),
    );
    if (updated != null && mounted) setState(() => _activity = updated);
  }

  Future<void> _deleteActivity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: const Text('This activity will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      await _activityService.deleteActivity(_activity.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return h.toString() + 'h ' + m.toString() + 'm ' + s.toString() + 's';
    return m.toString() + 'm ' + s.toString() + 's';
  }

  String _formatDateTime(DateTime date) {
    final d = date.toLocal();
    return d.day.toString().padLeft(2, '0') + '/' +
        d.month.toString().padLeft(2, '0') + '/' +
        d.year.toString() + ' ' +
        d.hour.toString().padLeft(2, '0') + ':' +
        d.minute.toString().padLeft(2, '0');
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return diff.inMinutes.toString() + 'm ago';
    if (diff.inHours < 24) return diff.inHours.toString() + 'h ago';
    if (diff.inDays < 7) return diff.inDays.toString() + 'd ago';
    return _formatDateTime(date);
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'Run': return Icons.directions_run;
      case 'Ride': return Icons.directions_bike;
      case 'Walk': return Icons.directions_walk;
      case 'Hike': return Icons.terrain;
      case 'Swim': return Icons.pool;
      default: return Icons.fitness_center;
    }
  }

  Widget _buildKudosCard() {
    if (_isLoadingKudos) {
      return const Card(child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ));
    }
    final kudos = _kudos;
    if (kudos == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: Text(
            kudos.kudosCount.toString() + ' Kudos',
            style: const TextStyle(fontWeight: FontWeight.bold),
          )),
          FilledButton.icon(
            onPressed: _isUpdatingKudos ? null : _toggleKudos,
            icon: _isUpdatingKudos
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(kudos.hasGivenKudos ? Icons.favorite : Icons.favorite_border),
            label: Text(kudos.hasGivenKudos ? 'Kudos Given' : 'Give Kudos'),
          ),
        ]),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.chat_bubble_outline_rounded),
            const SizedBox(width: 8),
            Text(
              'Comments (' + _comments.length.toString() + ')',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ]),
          const SizedBox(height: 12),
          if (_isLoadingComments)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_commentsError != null)
            Row(children: [
              Expanded(child: Text(_commentsError!)),
              IconButton(onPressed: _loadComments, icon: const Icon(Icons.refresh)),
            ])
          else if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No comments yet. Be the first to say something!'),
            )
          else
            ..._comments.map(_buildComment),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 1,
            maxLines: 4,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Write a comment...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: _isPostingComment ? null : _postComment,
                icon: _isPostingComment
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
            onSubmitted: (_) => _postComment(),
          ),
        ]),
      ),
    );
  }

  Widget _buildComment(CommentResponse comment) {
    final hasImage = comment.profileImageUrl != null && comment.profileImageUrl!.isNotEmpty;
    final initial = comment.displayName.trim().isEmpty ? '?' : comment.displayName.trim()[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: hasImage ? NetworkImage(comment.profileImageUrl!) : null,
          onBackgroundImageError: (_, _) {},
          child: hasImage ? null : Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(comment.displayName, style: const TextStyle(fontWeight: FontWeight.bold))),
              if (_currentUserId == comment.userId)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'delete') _deleteComment(comment);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  icon: const Icon(Icons.more_horiz, size: 20),
                ),
            ]),
            Text('@' + comment.username, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 5),
            Text(comment.content),
            const SizedBox(height: 4),
            Text(_formatTime(comment.createdAt), style: Theme.of(context).textTheme.bodySmall),
          ]),
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Details'),
        actions: [
          if (_isOwnActivity) ...[
            IconButton(onPressed: _isDeleting ? null : _editActivity, icon: const Icon(Icons.edit_outlined)),
            IconButton(
              onPressed: _isDeleting ? null : _deleteActivity,
              icon: _isDeleting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              CircleAvatar(radius: 36, child: Icon(_activityIcon(activity.type), size: 36)),
              const SizedBox(height: 16),
              Text(activity.type, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_formatDateTime(activity.startedAt)),
            ]),
          )),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _MetricCard(icon: Icons.straighten_rounded, value: activity.distance.toStringAsFixed(2) + ' km', label: 'Distance')),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(icon: Icons.timer_outlined, value: _formatDuration(activity.durationSeconds), label: 'Duration')),
          ]),
          const SizedBox(height: 12),
          _MetricCard(icon: Icons.local_fire_department_outlined, value: activity.calories == null ? '—' : activity.calories.toString() + ' kcal', label: 'Calories'),
          const SizedBox(height: 24),
          if (!_isOwnActivity) ...[_buildKudosCard(), const SizedBox(height: 12)],
          _buildCommentsSection(),
          if (_isOwnActivity) ...[
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _isDeleting ? null : _editActivity, icon: const Icon(Icons.edit_outlined), label: const Text('Edit Activity')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _isDeleting ? null : _deleteActivity, icon: const Icon(Icons.delete_outline), label: const Text('Delete Activity')),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _MetricCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Icon(icon),
        const SizedBox(height: 10),
        Text(value, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label),
      ]),
    ));
  }
}