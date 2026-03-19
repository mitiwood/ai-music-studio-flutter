/// 사용자 모델
class AppUser {
  final String name;
  final String provider;
  final String email;
  final String avatar;
  final String plan;
  final int credits;
  final int loginCount;
  final int lastLogin;

  AppUser({
    required this.name,
    required this.provider,
    this.email = '',
    this.avatar = '',
    this.plan = 'free',
    this.credits = 2,
    this.loginCount = 1,
    this.lastLogin = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        name: json['name'] ?? '',
        provider: json['provider'] ?? 'guest',
        email: json['email'] ?? '',
        avatar: json['avatar'] ?? '',
        plan: json['plan'] ?? 'free',
        credits: json['credits'] ?? 2,
        loginCount: json['login_count'] ?? json['loginCount'] ?? 1,
        lastLogin: json['last_login'] ?? json['lastLogin'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'provider': provider,
        'email': email,
        'avatar': avatar,
        'plan': plan,
        'credits': credits,
      };

  bool get isLoggedIn => provider != 'guest' && name.isNotEmpty;
  bool get isPremium => plan != 'free';
}
