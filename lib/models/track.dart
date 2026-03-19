/// 음악 트랙 모델
class Track {
  final String id;
  final String taskId;
  final String title;
  final String audioUrl;
  final String videoUrl;
  final String imageUrl;
  final String tags;
  final String lyrics;
  final String genMode;
  final String ownerName;
  final String ownerAvatar;
  final String ownerProvider;
  final bool isPublic;
  final int likes;
  final int dislikes;
  final int plays;
  final int created;

  Track({
    required this.id,
    this.taskId = '',
    this.title = '무제',
    this.audioUrl = '',
    this.videoUrl = '',
    this.imageUrl = '',
    this.tags = '',
    this.lyrics = '',
    this.genMode = 'custom',
    this.ownerName = '익명',
    this.ownerAvatar = '',
    this.ownerProvider = 'guest',
    this.isPublic = true,
    this.likes = 0,
    this.dislikes = 0,
    this.plays = 0,
    this.created = 0,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] ?? '',
        taskId: json['task_id'] ?? '',
        title: json['title'] ?? '무제',
        audioUrl: json['audio_url'] ?? '',
        videoUrl: json['video_url'] ?? '',
        imageUrl: json['image_url'] ?? '',
        tags: json['tags'] ?? '',
        lyrics: json['lyrics'] ?? '',
        genMode: json['gen_mode'] ?? 'custom',
        ownerName: json['owner_name'] ?? '익명',
        ownerAvatar: json['owner_avatar'] ?? '',
        ownerProvider: json['owner_provider'] ?? 'guest',
        isPublic: json['is_public'] ?? true,
        likes: json['comm_likes'] ?? 0,
        dislikes: json['comm_dislikes'] ?? 0,
        plays: json['comm_plays'] ?? 0,
        created: json['created'] ?? 0,
      );

  bool get hasMV => videoUrl.isNotEmpty;
  bool get isGuest => ownerProvider == 'guest' || ownerName == '익명';
}
