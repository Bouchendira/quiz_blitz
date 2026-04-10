// lib/data/repositories/game_repository.dart
import 'dart:math';
import '../models/game_session_model.dart';
import '../models/game_player_model.dart';
import '../../main.dart';

class GameRepository {

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ── Create a new session ──────────────────────────────────────────
  Future<GameSessionModel> createSession({
    required String quizId,
    required String hostId,
  }) async {
    final code = _generateCode();
    final data = await supabase.from('game_sessions').insert({
      'code': code,
      'quiz_id': quizId,
      'host_id': hostId,
      'status': 'waiting',
    }).select().single();
    return GameSessionModel.fromMap(data);
  }

  // ── Real-time: watch session changes ─────────────────────────────
  // Supabase Realtime uses channels — very different from Firestore streams!
  Stream<GameSessionModel> watchSession(String sessionId) {
    return supabase
        .from('game_sessions')
        .stream(primaryKey: ['id'])
        .asyncMap((rows) async {
          for (final row in rows) {
            if (row['id'] == sessionId) {
              return GameSessionModel.fromMap(row);
            }
          }
          return null;
        })
        .where((session) => session != null)
        .cast<GameSessionModel>();
  }

  // ── Real-time: watch players in a session ─────────────────────────
  Stream<List<GamePlayerModel>> watchPlayers(String sessionId) {
    return supabase
        .from('game_players')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final players = rows
              .where((row) => row['session_id'] == sessionId)
              .map(GamePlayerModel.fromMap)
              .toList();
          
          // Sort by total_score descending (highest first), then by ID for consistency
          players.sort((a, b) {
            final scoreComparison = b.totalScore.compareTo(a.totalScore);
            if (scoreComparison != 0) return scoreComparison;
            // For draws, sort by ID alphabetically for consistent ordering
            return a.id.compareTo(b.id);
          });
          
          return players;
        });
  }

  // ── Watch player answers for current question ─────────────────────
  Stream<List<Map<String, dynamic>>> watchAnswersForQuestion(
    String sessionId,
    int questionIndex,
  ) {
    return supabase
        .from('player_answers')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .where((row) => row['session_id'] == sessionId && row['question_index'] == questionIndex)
            .toList());
  }

  // ── Check if all players have answered ────────────────────────────
  Future<bool> allPlayersAnswered(String sessionId, int currentQuestion) async {
    try {
      // Get total number of active players
      final playersResponse = await supabase
          .from('game_players')
          .select('id')
          .eq('session_id', sessionId);
      final playerCount = (playersResponse as List).length;

      if (playerCount == 0) return false;

      // Get number of players who answered this question
      final answersResponse = await supabase
          .from('player_answers')
          .select('player_id')
          .eq('session_id', sessionId)
          .eq('question_index', currentQuestion);

      final answeredCount = (answersResponse as List).length;
      return answeredCount >= playerCount;
    } catch (e) {
      print('Error checking if all players answered: $e');
      return false;
    }
  }

  // ── Find session by code ──────────────────────────────────────────
  Future<GameSessionModel?> findByCode(String code) async {
    final data = await supabase
        .from('game_sessions')
        .select()
        .eq('code', code)
        .eq('status', 'waiting')
        .maybeSingle();
    if (data == null) return null;
    return GameSessionModel.fromMap(data);
  }

  // ── Join a session ────────────────────────────────────────────────
  Future<GamePlayerModel> joinSession({
    required String sessionId,
    required String userId,
    required String displayName,
    required String avatarUrl,
  }) async {
    // upsert: if player already joined, update; otherwise insert
    final data = await supabase.from('game_players').upsert({
      'session_id': sessionId,
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'total_score': 0,
    }, onConflict: 'session_id,user_id').select().single();
    return GamePlayerModel.fromMap(data);
  }

  // ── Remove a player from session ──────────────────────────────────
  Future<void> removePlayer(String playerId) async {
    await supabase.from('game_players').delete().eq('id', playerId);
  }

  // ── Host controls ─────────────────────────────────────────────────
  Future<void> startGame(String sessionId) => _updateSession(sessionId, {
    'status': 'question',
    'current_question': 0,
    'question_started_at': DateTime.now().toIso8601String(),
  });

  Future<void> nextQuestion(String sessionId, int nextIndex) =>
      _updateSession(sessionId, {
        'status': 'question',
        'current_question': nextIndex,
        'question_started_at': DateTime.now().toIso8601String(),
      });

  Future<void> showReview(String sessionId) =>
      _updateSession(sessionId, {'status': 'reviewing'});

  Future<void> endGame(String sessionId) =>
      _updateSession(sessionId, {'status': 'finished'});

  Future<void> _updateSession(String id, Map<String, dynamic> data) async {
    await supabase.from('game_sessions').update(data).eq('id', id);
  }

  // ── Submit an answer ──────────────────────────────────────────────
  Future<void> submitAnswer({
    required String sessionId,
    required String playerId,
    required int questionIndex,
    required int answerIndex,
    required int pointsEarned,
  }) async {
    // Insert the answer record
    await supabase.from('player_answers').upsert({
      'session_id': sessionId,
      'player_id': playerId,
      'question_index': questionIndex,
      'answer_index': answerIndex,
      'points_earned': pointsEarned,
    }, onConflict: 'player_id,question_index');

    // Update player total score
    // We use a raw RPC call (PostgreSQL function) for atomic increment
    await supabase.rpc('increment_player_score', params: {
      'player_id_param': playerId,
      'points_param': pointsEarned,
    });
  }
}