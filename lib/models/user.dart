class AppUser {
  String name;
  final String provider;
  final String? email;
  final String? avatar;
  final String? uid;
  String? bio;
  String plan;
  int creditsSong;
  int creditsMv;
  int creditsLyrics;

  AppUser({
    required this.name, required this.provider, this.email, this.avatar,
    this.uid, this.bio, this.plan = 'free',
    this.creditsSong = 5, this.creditsMv = 0, this.creditsLyrics = 5,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    name: j['name'] ?? '',
    provider: j['provider'] ?? 'guest',
    email: j['email'],
    avatar: j['avatar'],
    uid: j['uid'],
    bio: j['bio'],
    plan: j['plan'] ?? 'free',
    creditsSong: j['credits_song'] ?? 5,
    creditsMv: j['credits_mv'] ?? 0,
    creditsLyrics: j['credits_lyrics'] ?? 5,
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'provider': provider, 'email': email, 'avatar': avatar,
    'uid': uid, 'bio': bio, 'plan': plan, 'credits_song': creditsSong,
    'credits_mv': creditsMv, 'credits_lyrics': creditsLyrics,
  };

  bool get isGuest => provider == 'guest';
  bool get isPro => plan == 'pro' || plan == 'creator';
  bool get isCreator => plan == 'creator';
  String get planLabel => plan == 'creator' ? 'Creator' : plan == 'pro' ? 'Pro' : 'Free';
  String get planIcon => plan == 'creator' ? '👑' : plan == 'pro' ? '💜' : '🆓';
}
