class Comment {
  final String id;
  final String trackId;
  final String? parentId;
  final String authorName;
  final String? authorAvatar;
  final String authorProvider;
  final String content;
  final bool isHidden;
  final DateTime? createdAt;
  final List<Comment> replies;

  Comment({
    required this.id, required this.trackId, this.parentId,
    required this.authorName, this.authorAvatar, this.authorProvider = 'guest',
    required this.content, this.isHidden = false, this.createdAt,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
    id: j['id']?.toString() ?? '',
    trackId: j['track_id'] ?? '',
    parentId: j['parent_id'],
    authorName: j['author_name'] ?? '익명',
    authorAvatar: j['author_avatar'],
    authorProvider: j['author_provider'] ?? 'guest',
    content: j['content'] ?? '',
    isHidden: j['is_hidden'] ?? false,
    createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
  );
}
