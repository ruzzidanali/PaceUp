import 'package:flutter/material.dart';
import '../models/comment_models.dart';
import '../services/comment_service.dart';

class CommentsSheet extends StatefulWidget {
  final String activityId;
  final String? currentUserId;
  const CommentsSheet({super.key, required this.activityId, this.currentUserId});
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late final CommentService _service;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<CommentResponse> _comments = [];
  bool _loading = true, _loadingMore = false, _posting = false;
  int _page = 1, _totalPages = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = CommentService();
    _scrollController.addListener(_onScroll);
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final response = await _service.getComments(widget.activityId);
      if (!mounted) return;
      setState(() {
        _comments..clear()..addAll(response.comments);
        _page = response.page;
        _totalPages = response.totalPages;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _page >= _totalPages) return;
    setState(() => _loadingMore = true);
    try {
      final response = await _service.getComments(widget.activityId, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _comments.addAll(response.comments);
        _page = response.page;
        _totalPages = response.totalPages;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) _loadMore();
  }

  Future<void> _postComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      final comment = await _service.createComment(widget.activityId, content);
      if (!mounted) return;
      setState(() { _comments.insert(0, comment); _controller.clear(); _posting = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _deleteComment(CommentResponse comment) async {
    try {
      await _service.deleteComment(widget.activityId, comment.id);
      if (mounted) setState(() => _comments.removeWhere((item) => item.id == comment.id));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to delete comment. Please try again.')));
    }
  }

  String _formatTime(DateTime date) {
    final d = DateTime.now().difference(date.toLocal());
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 14, 12, 10), child: Row(children: [
              Text('Comments', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ])),
            const Divider(height: 1),
            Expanded(child: _buildList()),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 10), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 4, textInputAction: TextInputAction.newline, decoration: const InputDecoration(hintText: 'Write a comment...', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _posting ? null : _postComment, icon: _posting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded)),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _comments.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 40), const SizedBox(height: 12), Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(_error!, textAlign: TextAlign.center)), const SizedBox(height: 12), FilledButton(onPressed: _loadComments, child: const Text('Retry'))]));
    if (_comments.isEmpty) return const Center(child: Text('No comments yet. Be the first!'));
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _comments.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _comments.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        final comment = _comments[index];
        final initial = comment.displayName.trim().isEmpty ? '?' : comment.displayName.trim()[0].toUpperCase();
        return ListTile(
          leading: CircleAvatar(backgroundImage: comment.profileImageUrl?.isNotEmpty == true ? NetworkImage(comment.profileImageUrl!) : null, child: comment.profileImageUrl?.isNotEmpty == true ? null : Text(initial)),
          title: Row(children: [Expanded(child: Text(comment.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))), Text(_formatTime(comment.createdAt), style: Theme.of(context).textTheme.bodySmall)]),
          subtitle: Padding(padding: const EdgeInsets.only(top: 3), child: Text(comment.content)),
          trailing: widget.currentUserId == comment.userId ? IconButton(icon: const Icon(Icons.more_vert), onPressed: () => showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete comment'), onTap: () { Navigator.pop(context); _deleteComment(comment); })))) : null,
        );
      },
    );
  }
}

Future<void> showCommentsSheet(BuildContext context, String activityId, {String? currentUserId}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => CommentsSheet(activityId: activityId, currentUserId: currentUserId),
);
