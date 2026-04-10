// lib/data/models/game_player_model.dart
class GamePlayerModel {
  final String id;
  final String sessionId;
  final String userId;
  final String displayName;
  final String avatarUrl;
  final int totalScore;

  const GamePlayerModel({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    this.totalScore = 0,
  });

  factory GamePlayerModel.fromMap(Map<String, dynamic> map) => GamePlayerModel(
    id: map['id'] as String,
    sessionId: map['session_id'] as String,
    userId: map['user_id'] as String,
    displayName: map['display_name'] as String,
    avatarUrl: map['avatar_url'] as String,
    totalScore: map['total_score'] as int? ?? 0,
  );
}