// lib/data/models/profile_model.dart
class ProfileModel {
  final String id;
  final String displayName;
  final String avatarUrl;
  final bool isGuest;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    this.isGuest = false,
    required this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) => ProfileModel(
    id: map['id'] as String,
    displayName: map['display_name'] as String,
    avatarUrl: map['avatar_url'] as String,
    isGuest: map['is_guest'] as bool? ?? false,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  // Note: snake_case keys — Supabase uses PostgreSQL naming conventions
  Map<String, dynamic> toMap() => {
    'id': id,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'is_guest': isGuest,
  };
}