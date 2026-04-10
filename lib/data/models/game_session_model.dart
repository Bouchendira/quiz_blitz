// lib/data/models/game_session_model.dart
enum GameStatus { waiting, question, reviewing, finished }

class GameSessionModel {
  final String id;
  final String code;
  final String quizId;
  final String hostId;
  final GameStatus status;
  final int currentQuestion;
  final DateTime? questionStartedAt;

  const GameSessionModel({
    required this.id,
    required this.code,
    required this.quizId,
    required this.hostId,
    required this.status,
    this.currentQuestion = 0,
    this.questionStartedAt,
  });

  factory GameSessionModel.fromMap(Map<String, dynamic> map) => GameSessionModel(
    id: map['id'] as String,
    code: map['code'] as String,
    quizId: map['quiz_id'] as String,
    hostId: map['host_id'] as String,
    status: GameStatus.values.byName(map['status'] as String),
    currentQuestion: map['current_question'] as int? ?? 0,
    questionStartedAt: map['question_started_at'] != null
        ? DateTime.parse(map['question_started_at'] as String)
        : null,
  );
}