// lib/features/game/player_game_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/game_session_model.dart';
import '../../data/repositories/providers.dart';

class PlayerGameScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String playerId; // game_players.id
  const PlayerGameScreen(
      {super.key, required this.sessionId, required this.playerId});
  @override
  ConsumerState<PlayerGameScreen> createState() => _PlayerGameScreenState();
}

class _PlayerGameScreenState extends ConsumerState<PlayerGameScreen> {
  int? _selectedAnswer;
  bool _answered = false;
  Timer? _timer;
  int _secondsLeft = 20;
  int _lastQuestionIndex = -1; // tracks when question changes

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _secondsLeft = seconds;
      _answered = false;
      _selectedAnswer = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_secondsLeft <= 1) {
        t.cancel();
        _submitAnswer(-1, 0);  // timed out
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(watchSessionProvider(widget.sessionId));

    return sessionAsync.when(
      loading: () => _scaffold(const Center(child: CircularProgressIndicator())),
      error: (e, _) => _scaffold(Center(child: Text('$e'))),
      data: (session) {
        if (session.status == GameStatus.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/results/${widget.sessionId}');
          });
        }
        if (session.status == GameStatus.waiting) {
          return _scaffold(_waiting());
        }

        final quizAsync = ref.watch(quizProvider(session.quizId));
        return quizAsync.when(
          loading: () => _scaffold(const Center(child: CircularProgressIndicator())),
          error: (e, _) => _scaffold(Center(child: Text('$e'))),
          data: (quiz) {
            if (quiz == null) return _scaffold(const Center(child: Text('Quiz not found')));
            final q = quiz.questions[session.currentQuestion];

            // Start timer when question changes
            if (session.currentQuestion != _lastQuestionIndex) {
              _lastQuestionIndex = session.currentQuestion;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _startTimer(q.timeLimitSeconds);
              });
            }

            if (session.status == GameStatus.reviewing) {
              _timer?.cancel();
              return _scaffold(_reviewScreen(
                  q, _selectedAnswer, _answered));
            }

            return Scaffold(
              backgroundColor: const Color(0xFF0D0D2B),
              body: SafeArea(
                child: Column(children: [
                  // Timer bar
                  LinearProgressIndicator(
                    value: _secondsLeft / q.timeLimitSeconds,
                    backgroundColor: Colors.white12,
                    color: _secondsLeft < 5
                        ? Colors.redAccent
                        : const Color(0xFF6C63FF),
                    minHeight: 6,
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Q${session.currentQuestion + 1}',
                              style: GoogleFonts.poppins(
                                  color: Colors.white54, fontSize: 14)),
                          _TimerBubble(seconds: _secondsLeft),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(q.text,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center),
                      ),
                    ]),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: List.generate(q.options.length, (i) {
                          const colors = [
                            Color(0xFFE53935), Color(0xFF1565C0),
                            Color(0xFF2E7D32), Color(0xFFF57F17),
                          ];
                          const icons = ['▲', '◆', '●', '■'];
                          final selected = _selectedAnswer == i;
                          return GestureDetector(
                            onTap: _answered ? null : () {
                              final isCorrect = i == q.correctIndex;
                              final points = isCorrect
                                  ? (_secondsLeft / q.timeLimitSeconds * q.points)
                                      .round()
                                  : 0;
                              setState(() {
                                _selectedAnswer = i;
                                _answered = true;
                              });
                              _timer?.cancel();
                              _submitAnswer(i, points);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: selected
                                    ? colors[i]
                                    : colors[i].withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                                border: selected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(icons[i],
                                        style: const TextStyle(
                                            fontSize: 20, color: Colors.white70)),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(q.options[i],
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                          textAlign: TextAlign.center,
                                          maxLines: 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  if (_answered)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Answer submitted! Waiting for others...',
                          style: GoogleFonts.poppins(
                              color: Colors.white54, fontSize: 13)),
                    ),
                  const SizedBox(height: 8),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitAnswer(int answerIndex, int points) async {
    await ref.read(gameRepositoryProvider).submitAnswer(
      sessionId: widget.sessionId,
      playerId: widget.playerId,
      questionIndex: _lastQuestionIndex,
      answerIndex: answerIndex,
      pointsEarned: points,
    );
  }

  Widget _scaffold(Widget body) =>
      Scaffold(backgroundColor: const Color(0xFF0D0D2B), body: body);

  Widget _waiting() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('⏳', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      Text('Waiting for the host...',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 22)),
    ]),
  );

  Widget _reviewScreen(question, int? selected, bool answered) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(answered && selected == question.correctIndex ? '✅' : '❌',
          style: const TextStyle(fontSize: 72)),
      const SizedBox(height: 16),
      Text(answered && selected == question.correctIndex
          ? 'Correct! 🎉' : 'Not quite!',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 24,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Get ready for next question...',
          style: GoogleFonts.poppins(color: Colors.white54)),
    ]),
  );
}

class _TimerBubble extends StatelessWidget {
  final int seconds;
  const _TimerBubble({required this.seconds});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: 52, height: 52,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: seconds < 5
          ? Colors.redAccent.withOpacity(0.3)
          : const Color(0xFF6C63FF).withOpacity(0.3),
      border: Border.all(
        color: seconds < 5 ? Colors.redAccent : const Color(0xFF6C63FF),
        width: 2),
    ),
    child: Center(
      child: Text('$seconds',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
    ),
  );
}