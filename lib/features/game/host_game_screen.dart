// lib/features/game/host_game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/game_session_model.dart';
import '../../data/repositories/providers.dart';

class HostGameScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const HostGameScreen({super.key, required this.sessionId});

  @override
  ConsumerState<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends ConsumerState<HostGameScreen> {
  late String _previousSessionStatus;
  late int _previousQuestion;
  bool _autoSkipTriggered = false;

  @override
  void initState() {
    super.initState();
    _previousSessionStatus = '';
    _previousQuestion = -1;
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(watchSessionProvider(widget.sessionId));
    final playersAsync = ref.watch(watchPlayersProvider(widget.sessionId));

    return sessionAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (session) {
        // Reset auto-skip flag when question changes
        if (session.currentQuestion != _previousQuestion) {
          _previousQuestion = session.currentQuestion;
          _autoSkipTriggered = false;
        }

        // Load the quiz
        final quizAsync = ref.watch(quizProvider(session.quizId));
        return quizAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
          data: (quiz) {
            if (quiz == null) return const Scaffold(body: Center(child: Text('Quiz not found')));
            final q = quiz.questions[session.currentQuestion];
            final isLastQuestion =
                session.currentQuestion >= quiz.questions.length - 1;

            // Watch player answers for current question
            final answersAsync = ref.watch(
              watchAnswersForQuestionProvider(
                (sessionId: widget.sessionId, questionIndex: session.currentQuestion),
              ),
            );

            // Auto-skip logic: check if all players answered
            playersAsync.maybeWhen(
              data: (players) {
                if (!_autoSkipTriggered &&
                    session.status == GameStatus.question &&
                    players.isNotEmpty) {
                  final answeredCount = answersAsync.maybeWhen(
                    data: (answers) => answers.length,
                    orElse: () => 0,
                  );
                  // Auto-show review when all players answered
                  if (answeredCount >= players.length) {
                    _autoSkipTriggered = true;
                    Future.microtask(() {
                      ref.read(gameRepositoryProvider).showReview(widget.sessionId);
                    });
                  }
                }
              },
              orElse: () => {},
            );

            return Scaffold(
              backgroundColor: const Color(0xFF0D0D2B),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress
                      Text(
                        'Question ${session.currentQuestion + 1} of ${quiz.questions.length}',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (session.currentQuestion + 1) /
                            quiz.questions.length,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFF6C63FF),
                      ),
                      const SizedBox(height: 24),

                      // Scrollable content area
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Question display
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(q.text,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center),
                              ),
                              const SizedBox(height: 24),

                              // Answer options display (for host to show on big screen)
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 3,
                                children: List.generate(q.options.length, (i) {
                                  const colors = [
                                    Color(0xFFE53935), Color(0xFF1565C0),
                                    Color(0xFF2E7D32), Color(0xFFF57F17),
                                  ];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: colors[i].withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(q.options[i],
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Live player count and answered count
                      playersAsync.maybeWhen(
                        data: (players) {
                          final answeredCount = answersAsync.maybeWhen(
                            data: (answers) => answers.length,
                            orElse: () => 0,
                          );
                          return Text(
                            '${players.length} players connected • $answeredCount/${players.length} answered',
                            style: GoogleFonts.poppins(color: Colors.white38),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      // Control buttons
                      Row(children: [
                        if (session.status == GameStatus.question)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => ref
                                  .read(gameRepositoryProvider)
                                  .showReview(widget.sessionId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Show Answer',
                                  style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (session.status == GameStatus.question)
                          const SizedBox(width: 12),
                        if (session.status == GameStatus.question && !isLastQuestion)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                // First show the review
                                await ref
                                    .read(gameRepositoryProvider)
                                    .showReview(widget.sessionId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Skip Question',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (session.status == GameStatus.reviewing) ...[
                          if (!isLastQuestion)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => ref
                                    .read(gameRepositoryProvider)
                                    .nextQuestion(widget.sessionId,
                                        session.currentQuestion + 1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text('Next Question →',
                                    style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          if (isLastQuestion)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await ref
                                      .read(gameRepositoryProvider)
                                      .endGame(widget.sessionId);
                                  if (context.mounted) {
                                    context.go('/results/${widget.sessionId}');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text('Show Results 🏆',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}