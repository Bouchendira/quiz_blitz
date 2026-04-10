// lib/data/repositories/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';
import '../models/game_session_model.dart';
import '../models/game_player_model.dart';
import '../models/quiz_model.dart';
import 'auth_repository.dart';
import 'quiz_repository.dart';
import 'game_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());
final quizRepositoryProvider = Provider((ref) => QuizRepository());
final gameRepositoryProvider = Provider((ref) => GameRepository());

// Current logged-in user profile
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final auth = ref.watch(authRepositoryProvider);
  final user = auth.currentUser;
  if (user == null) return null;
  return auth.getProfile(user.id);
});

// Riverpod stream providers for real-time data
final watchSessionProvider = StreamProvider.family<GameSessionModel, String>(
  (ref, sessionId) => ref.read(gameRepositoryProvider).watchSession(sessionId),
);

final watchPlayersProvider = StreamProvider.family<List<GamePlayerModel>, String>(
  (ref, sessionId) => ref.read(gameRepositoryProvider).watchPlayers(sessionId),
);

final watchAnswersForQuestionProvider = StreamProvider.family<List<Map<String, dynamic>>, ({String sessionId, int questionIndex})>(
  (ref, params) =>
      ref.read(gameRepositoryProvider).watchAnswersForQuestion(params.sessionId, params.questionIndex),
);

final allPlayersAnsweredProvider = FutureProvider.family<bool, ({String sessionId, int currentQuestion})>(
  (ref, params) =>
      ref.read(gameRepositoryProvider).allPlayersAnswered(params.sessionId, params.currentQuestion),
);

final quizProvider = FutureProvider.family<QuizModel?, String>((ref, quizId) async {
  return ref.read(quizRepositoryProvider).getQuiz(quizId);
});