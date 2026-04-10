// lib/data/repositories/quiz_repository.dart
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../../main.dart';

class QuizRepository {

  /// Create a quiz with all its questions in one batch
  Future<QuizModel> createQuiz(QuizModel quiz) async {
    // 1. Insert quiz row
    final quizRow = await supabase
        .from('quizzes')
        .insert(quiz.toMap())
        .select()
        .single();

    final quizId = quizRow['id'] as String;

    // 2. Insert all questions
    if (quiz.questions.isNotEmpty) {
      final questionRows = quiz.questions
          .asMap()
          .entries
          .map((e) => e.value
              .copyWith(quizId: quizId, orderIndex: e.key)
              .toMap())
          .toList();
      await supabase.from('questions').insert(questionRows);
    }

    // 3. Return full quiz with questions
    return getQuiz(quizId);
  }

  /// Fetch a single quiz with all its questions
  Future<QuizModel> getQuiz(String quizId) async {
    // Supabase supports embedded selects (like a JOIN)
    // quizzes?select=*,questions(*) fetches quiz + all related questions
    final data = await supabase
        .from('quizzes')
        .select('*, questions(*)')
        .eq('id', quizId)
        .single();
    return QuizModel.fromMap(data);
  }

  /// Fetch all quizzes owned by a user
  Future<List<QuizModel>> getMyQuizzes(String ownerId) async {
    final data = await supabase
        .from('quizzes')
        .select('*, questions(*)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return data.map((row) => QuizModel.fromMap(row)).toList();
  }

  Future<void> deleteQuiz(String quizId) async {
    // questions are deleted automatically via CASCADE
    await supabase.from('quizzes').delete().eq('id', quizId);
  }
}

// Add copyWith to QuestionModel
extension QuestionCopyWith on QuestionModel {
  QuestionModel copyWith({String? quizId, int? orderIndex}) => QuestionModel(
    id: id,
    quizId: quizId ?? this.quizId,
    orderIndex: orderIndex ?? this.orderIndex,
    text: text,
    options: options,
    correctIndex: correctIndex,
    timeLimitSeconds: timeLimitSeconds,
    points: points,
  );
}