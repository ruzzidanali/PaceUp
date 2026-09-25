import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/comment_models.dart';
import '../services/comment_service.dart';

class CommentsSheet extends StatefulWidget {
  final String activityId;
  final String? currentUserId;

  const CommentsSheet({
    super.key,
    required this.activityId,
    this.currentUserId,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late final CommentService _service;

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<CommentResponse> _comments = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _posting = false;

  int _page = 1;
  int _totalPages = 0;

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

      if (!mounted) {
        return;
      }

      setState(() {
        _comments
          ..clear()
          ..addAll(response.comments);

        _page = response.page;
        _totalPages = response.totalPages;

        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _page >= _totalPages) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      final response = await _service.getComments(
        widget.activityId,
        page: _page + 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments.addAll(response.comments);

        _page = response.page;
        _totalPages = response.totalPages;

        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _postComment() async {
    final content = _controller.text.trim();

    if (content.isEmpty || _posting) {
      return;
    }

    setState(() {
      _posting = true;
    });

    try {
      final comment = await _service.createComment(
        widget.activityId,
        content,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments.insert(0, comment);
        _controller.clear();
        _posting = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _posting = false;
      });

      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _deleteComment(CommentResponse comment) async {
    try {
      await _service.deleteComment(
        widget.activityId,
        comment.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _comments.removeWhere(
          (item) => item.id == comment.id,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to delete comment. Please try again.',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? PaceUpColors.darkBackground
        : PaceUpColors.lightBackground;

    final panelColor = isDark
        ? PaceUpColors.darkPanel
        : PaceUpColors.lightPanel;

    final borderColor = isDark
        ? PaceUpColors.darkBorder
        : PaceUpColors.lightBorder;

    final textColor = isDark
        ? PaceUpColors.darkText
        : PaceUpColors.lightText;

    final mutedColor = isDark
        ? PaceUpColors.darkMuted
        : PaceUpColors.lightMuted;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.78,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              _buildGrabber(mutedColor),
              _buildHeader(
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              Expanded(
                child: _buildList(
                  panelColor: panelColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              _buildComposer(
                panelColor: panelColor,
                borderColor: borderColor,
                textColor: textColor,
                mutedColor: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrabber(Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 9, bottom: 3),
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: mutedColor.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONVERSATION',
                  style: PaceUpTypography.sectionTitle(
                    PaceUpColors.electricGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _comments.isEmpty
                      ? 'Start the conversation'
                      : '${_comments.length} ${_comments.length == 1 ? 'COMMENT' : 'COMMENTS'}',
                  style: PaceUpTypography.heading(
                    textColor,
                  ).copyWith(
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: 'Close',
            icon: Icon(
              Icons.close_rounded,
              color: mutedColor,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required Color panelColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    if (_loading) {
      return const _CommentsLoadingState();
    }

    if (_error != null && _comments.isEmpty) {
      return _buildErrorState(
        textColor: textColor,
        mutedColor: mutedColor,
      );
    }

    if (_comments.isEmpty) {
      return _buildEmptyState(
        textColor: textColor,
        mutedColor: mutedColor,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: _comments.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _comments.length) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PaceUpColors.electricGreen,
                ),
              ),
            ),
          );
        }

        final comment = _comments[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: _CommentItem(
            comment: comment,
            currentUserId: widget.currentUserId,
            textColor: textColor,
            mutedColor: mutedColor,
            onDelete: () {
              _deleteComment(comment);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                border: Border.all(
                  color: PaceUpColors.electricGreen.withValues(
                    alpha: 0.35,
                  ),
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: PaceUpColors.electricGreen,
                size: 27,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'NO COMMENTS YET',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.electricGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation and share your thoughts.',
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
              size: 42,
              color: mutedColor,
            ),
            const SizedBox(height: 16),
            Text(
              'COMMENTS UNAVAILABLE',
              style: PaceUpTypography.sectionTitle(
                PaceUpColors.electricGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: PaceUpTypography.body(mutedColor),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadComments,
              style: FilledButton.styleFrom(
                backgroundColor: PaceUpColors.electricGreen,
                foregroundColor: PaceUpColors.greenInk,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'TRY AGAIN',
                style: PaceUpTypography.label(
                  PaceUpColors.greenInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer({
    required Color panelColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Container(
      color: panelColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_posting,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: PaceUpTypography.body(textColor),
              cursorColor: PaceUpColors.electricGreen,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: PaceUpTypography.body(mutedColor),
                filled: true,
                fillColor: Theme.of(context).brightness ==
                        Brightness.dark
                    ? PaceUpColors.darkPanelSecondary
                    : PaceUpColors.lightPanelSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: borderColor,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(14),
                  ),
                  borderSide: BorderSide(
                    color: PaceUpColors.electricGreen,
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            height: 48,
            child: FilledButton(
              onPressed: _posting ? null : _postComment,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: PaceUpColors.electricGreen,
                foregroundColor: PaceUpColors.greenInk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _posting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: PaceUpColors.greenInk,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward_rounded,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final CommentResponse comment;
  final String? currentUserId;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onDelete;

  const _CommentItem({
    required this.comment,
    required this.currentUserId,
    required this.textColor,
    required this.mutedColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwnComment =
        currentUserId != null &&
        currentUserId == comment.userId;

    final initial = comment.displayName.trim().isEmpty
        ? '?'
        : comment.displayName.trim()[0].toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentAvatar(
          imageUrl: comment.profileImageUrl,
          initial: initial,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      comment.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PaceUpTypography.bodyMedium(
                        textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatCommentTime(comment.createdAt),
                    style: PaceUpTypography.body(
                      mutedColor,
                    ).copyWith(
                      fontSize: 10,
                    ),
                  ),
                  if (isOwnComment)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      iconSize: 19,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: mutedColor,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 19,
                              ),
                              SizedBox(width: 9),
                              Text('Delete comment'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '@${comment.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PaceUpTypography.body(
                  mutedColor,
                ).copyWith(
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                comment.content,
                style: PaceUpTypography.body(
                  textColor,
                ).copyWith(
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCommentTime(DateTime date) {
    final difference = DateTime.now().difference(
      date.toLocal(),
    );

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _CommentAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initial;

  const _CommentAvatar({
    required this.imageUrl,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: PaceUpColors.electricGreen.withValues(
          alpha: 0.08,
        ),
        border: Border.all(
          color: PaceUpColors.electricGreen.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return _buildInitial();
                },
              )
            : _buildInitial(),
      ),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        initial,
        style: PaceUpTypography.bodyMedium(
          PaceUpColors.electricGreen,
        ),
      ),
    );
  }
}

class _CommentsLoadingState extends StatelessWidget {
  const _CommentsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: const [
        _CommentSkeleton(),
        _CommentSkeleton(),
        _CommentSkeleton(),
        _CommentSkeleton(),
      ],
    );
  }
}

class _CommentSkeleton extends StatelessWidget {
  const _CommentSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: PaceUpColors.darkPanelSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 130,
                  height: 11,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 82,
                  height: 8,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: PaceUpColors.darkPanelSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  width: 190,
                  height: 10,
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

Future<void> showCommentsSheet(
  BuildContext context,
  String activityId, {
  String? currentUserId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return CommentsSheet(
        activityId: activityId,
        currentUserId: currentUserId,
      );
    },
  );
}