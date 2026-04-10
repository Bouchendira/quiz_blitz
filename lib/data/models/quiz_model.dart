// lib/data/models/quiz_model.dart
import 'question_model.dart';

class QuizModel {
  final String? id;
  final String ownerId;
  final String title;
  final String description;
  final String coverEmoji;
  final DateTime? createdAt;
  final List<QuestionModel> questions; // loaded separately via join

  const QuizModel({
    this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    this.coverEmoji = '🎯',
    this.createdAt,
    this.questions = const [],
  });

  factory QuizModel.fromMap(Map<String, dynamic> map) => QuizModel(
    id: map['id'] as String?,
    ownerId: map['owner_id'] as String,
    title: map['title'] as String,
    description: map['description'] as String? ?? '',
    coverEmoji: map['cover_emoji'] as String? ?? '🎯',
    createdAt: map['created_at'] != null
        ? DateTime.parse(map['created_at'] as String)
        : null,
    // Supabase join: quizzes?select=*,questions(*)
    questions: (map['questions'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((q) => QuestionModel.fromMap(q))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'owner_id': ownerId,
    'title': title,
    'description': description,
    'cover_emoji': coverEmoji,
  };
}