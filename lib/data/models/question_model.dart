// lib/data/models/question_model.dart
class QuestionModel {
  final String? id; // null when not yet saved
  final String quizId;
  final int orderIndex;
  final String text;
  final List<String> options;
  final int correctIndex;
  final int timeLimitSeconds;
  final int points;

  const QuestionModel({
    this.id,
    required this.quizId,
    required this.orderIndex,
    required this.text,
    required this.options,
    required this.correctIndex,
    this.timeLimitSeconds = 20,
    this.points = 1000,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) => QuestionModel(
    id: map['id'] as String?,
    quizId: map['quiz_id'] as String,
    orderIndex: map['order_index'] as int,
    text: map['text'] as String,
    // options is stored as JSONB, comes back as List<dynamic>
    options: List<String>.from(map['options'] as List),
    correctIndex: map['correct_index'] as int,
    timeLimitSeconds: map['time_limit_seconds'] as int? ?? 20,
    points: map['points'] as int? ?? 1000,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'quiz_id': quizId,
    'order_index': orderIndex,
    'text': text,
    'options': options,
    'correct_index': correctIndex,
    'time_limit_seconds': timeLimitSeconds,
    'points': points,
  };

  QuestionModel copyWith({
    String? id,
    String? quizId,
    int? orderIndex,
    String? text,
    List<String>? options,
    int? correctIndex,
    int? timeLimitSeconds,
    int? points,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      orderIndex: orderIndex ?? this.orderIndex,
      text: text ?? this.text,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      points: points ?? this.points,
    );
  }
}
