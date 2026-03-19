import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';

class CommentSection extends StatefulWidget {
  final String trackId;
  const CommentSection({super.key, required this.trackId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  final _controller = TextEditingController();
  String? _replyToId;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    final comments = await ApiService.getComments(widget.trackId);
    if (mounted) setState(() { _comments = comments; _loading = false; });
  }

  Future<void> _postComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<AppProvider>();
    final user = provider.currentUser;

    final success = await ApiService.postComment(
      trackId: widget.trackId,
      content: content,
      authorName: user?.name ?? '익명',
      authorProvider: user?.provider ?? 'guest',
      parentId: _replyToId,
    );

    if (success) {
      _controller.clear();
      setState(() { _replyToId = null; _replyToName = null; });
      await _loadComments();
    }
  }

  void _setReply(String id, String name) {
    setState(() { _replyToId = id; _replyToName = name; });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() { _replyToId = null; _replyToName = null; });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '댓글 ${_comments.length}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Comment input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_replyToName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$_replyToName 님에게 답글',
                        style: const TextStyle(color: AppTheme.accent, fontSize: 12),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _cancelReply,
                        child: const Icon(Icons.close, size: 16, color: AppTheme.accent),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '댓글을 입력하세요...',
                        hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                        filled: true,
                        fillColor: AppTheme.bg3,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _postComment,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.border, height: 1),
        // Comments list
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          )
        else if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('아직 댓글이 없어요', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
            ),
          )
        else
          ..._buildCommentTree(),
      ],
    );
  }

  List<Widget> _buildCommentTree() {
    // Separate root and replies
    final roots = _comments.where((c) => c['parent_id'] == null || c['parent_id'] == '').toList();
    final replies = _comments.where((c) => c['parent_id'] != null && c['parent_id'] != '').toList();

    final widgets = <Widget>[];
    for (final root in roots) {
      widgets.add(_CommentTile(
        comment: root,
        onReply: () => _setReply(root['id'] ?? '', root['author_name'] ?? '익명'),
      ));
      // Find replies for this root
      final childReplies = replies.where((r) => r['parent_id'] == root['id']).toList();
      for (final reply in childReplies) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 32),
          child: _CommentTile(
            comment: reply,
            onReply: () => _setReply(root['id'] ?? '', reply['author_name'] ?? '익명'),
            isReply: true,
          ),
        ));
      }
    }
    return widgets;
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final VoidCallback onReply;
  final bool isReply;

  const _CommentTile({
    required this.comment,
    required this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = comment['author_name'] ?? '익명';
    final content = comment['content'] ?? '';
    final createdAt = comment['created_at'] ?? '';
    final avatar = comment['author_avatar'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: isReply ? 12 : 16,
            backgroundColor: AppTheme.bg3,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? Icon(Icons.person, size: isReply ? 14 : 18, color: AppTheme.textTertiary)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: isReply ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(createdAt),
                      style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: isReply ? 12 : 13,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onReply,
                  child: const Text(
                    '답글',
                    style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String ts) {
    if (ts.isEmpty) return '';
    try {
      final dt = DateTime.parse(ts);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}일 전';
      if (diff.inHours > 0) return '${diff.inHours}시간 전';
      if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
      return '방금';
    } catch (_) {
      return '';
    }
  }
}
