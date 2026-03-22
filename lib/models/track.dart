class Track {
  final String id;
  final String title;
  final String? tags;
  final String? lyrics;
  final String? audioUrl;
  final String? imageUrl;
  final String? videoUrl;
  final String? model;
  final String? prompt;
  final String ownerName;
  final String ownerProvider;
  final bool isPublic;
  final int playCount;
  final int likeCount;
  final int dislikeCount;
  final int duration;
  final String? taskId;
  final DateTime? createdAt;
  bool liked;
  bool disliked;

  Track({
    required this.id, required this.title, this.tags, this.lyrics,
    this.audioUrl, this.imageUrl, this.videoUrl, this.model, this.prompt,
    this.ownerName = '', this.ownerProvider = '', this.isPublic = true,
    this.playCount = 0, this.likeCount = 0, this.dislikeCount = 0,
    this.duration = 0, this.taskId, this.createdAt,
    this.liked = false, this.disliked = false,
  });

  factory Track.fromJson(Map<String, dynamic> j) => Track(
    id: j['id']?.toString() ?? '',
    title: j['title'] ?? '',
    tags: j['tags'],
    lyrics: j['lyrics'],
    audioUrl: j['audio_url'],
    imageUrl: j['image_url'],
    videoUrl: j['video_url'],
    model: j['model'],
    prompt: j['prompt'],
    ownerName: j['owner_name'] ?? j['user_name'] ?? '',
    ownerProvider: j['owner_provider'] ?? j['user_provider'] ?? '',
    isPublic: j['is_public'] ?? true,
    playCount: j['play_count'] ?? j['comm_plays'] ?? 0,
    likeCount: j['like_count'] ?? j['comm_likes'] ?? 0,
    dislikeCount: j['dislike_count'] ?? j['comm_dislikes'] ?? 0,
    duration: j['duration'] ?? 0,
    taskId: j['task_id'],
    createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'tags': tags, 'lyrics': lyrics,
    'audio_url': audioUrl, 'image_url': imageUrl, 'video_url': videoUrl,
    'model': model, 'prompt': prompt, 'owner_name': ownerName,
    'owner_provider': ownerProvider, 'is_public': isPublic,
    'play_count': playCount, 'like_count': likeCount, 'duration': duration,
    'task_id': taskId, 'created_at': createdAt?.toIso8601String(),
  };
}
