class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.createdAt,
    required this.authMode,
  });

  final String displayName;
  final int createdAt;
  final String authMode;

  static const localAuthMode = 'local_v1';

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'createdAt': createdAt,
    'authMode': authMode,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'];
    final createdAt = json['createdAt'];
    final authMode = json['authMode'];
    if (displayName is! String || displayName.trim().isEmpty) {
      throw const FormatException('invalid displayName');
    }
    return UserProfile(
      displayName: displayName.trim(),
      createdAt: createdAt is num ? createdAt.toInt() : 0,
      authMode: authMode is String && authMode.trim().isNotEmpty
          ? authMode
          : localAuthMode,
    );
  }
}
