// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
 
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0; // 0 = My Quizzes, 1 = Play
  
  @override
  void initState() {
    super.initState();
    // Check if user is a guest and redirect them to join screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGuestAccess();
    });
  }
  
  void _checkGuestAccess() {
    final profileAsync = ref.read(currentProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null && profile.isGuest) {
        // Guest users should not access home page
        context.go('/join');
      }
    });
  }
 
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
 
    return Scaffold(
      backgroundColor: const Color(0xFF070718),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            _HomeHeader(profileAsync: profileAsync),
 
            // ── Tab bar ──────────────────────────────────────────
            _TabBar(
              selected: _tab,
              onSelect: (i) => setState(() => _tab = i),
            ),
 
            const SizedBox(height: 4),
 
            // ── Content ──────────────────────────────────────────
            Expanded(
              child: _tab == 0 ? _MyQuizzesTab() : _PlayTab(),
            ),
          ],
        ),
      ),
 
      // ── FAB: Create quiz ─────────────────────────────────────
      floatingActionButton: _tab == 0
          ? _CreateQuizFab()
          : null,
    );
  }
}
 
// ─── Header ──────────────────────────────────────────────────────────────────
 
class _HomeHeader extends ConsumerWidget {
  final AsyncValue profileAsync;
 
  const _HomeHeader({required this.profileAsync});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1040), Color(0xFF0D0D25)],
        ),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C73FF).withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: logo + avatar
          Row(
            children: [
              // Logo text
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '⚡',
                      style: GoogleFonts.fredoka(fontSize: 24),
                    ),
                    TextSpan(
                      text: 'Quiz',
                      style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: 'Blitz',
                      style: GoogleFonts.fredoka(
                          color: const Color(0xFF7C73FF),
                          fontSize: 24,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Avatar + logout
              profileAsync.maybeWhen(
                data: (profile) => profile == null
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        onTap: () => _showProfileMenu(context, ref),
                        child: Row(
                          children: [
                            Text(
                              profile.displayName.split(' ').first,
                              style: GoogleFonts.nunito(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(width: 10),
                            Hero(
                              tag: 'avatar',
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF7C73FF),
                                child: ClipOval(
                                  child: Image.network(
                                    profile.avatarUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Text(
                                          profile.displayName[0].toUpperCase(),
                                          style: GoogleFonts.fredoka(
                                              color: Colors.white,
                                              fontSize: 18),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                orElse: () => const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white12,
                ),
              ),
            ],
          ),
 
          const SizedBox(height: 20),
 
          // Greeting
          profileAsync.maybeWhen(
            data: (profile) => profile == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(profile.displayName),
                          style: GoogleFonts.fredoka(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Ready to quiz? 🎯',
                          style: GoogleFonts.nunito(
                              color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
 
  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final first = name.split(' ').first;
    if (hour < 12) return 'Good morning, $first! ☀️';
    if (hour < 17) return 'Good afternoon, $first!';
    return 'Good evening, $first! 🌙';
  }
 
  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12122A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white70),
              title: Text('My Profile',
                  style: GoogleFonts.nunito(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined,
                  color: Colors.white70),
              title: Text('Settings',
                  style: GoogleFonts.nunito(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Colors.redAccent),
              title: Text('Sign out',
                  style: GoogleFonts.nunito(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
 
// ─── Custom tab bar ───────────────────────────────────────────────────────────
 
class _TabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
 
  const _TabBar({required this.selected, required this.onSelect});
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _Tab(
                label: '📚  My Quizzes',
                selected: selected == 0,
                onTap: () => onSelect(0)),
            _Tab(
                label: '🎮  Play',
                selected: selected == 1,
                onTap: () => onSelect(1)),
          ],
        ),
      ),
    );
  }
}
 
class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
 
  const _Tab(
      {required this.label, required this.selected, required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7C73FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C73FF).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: selected ? Colors.white : Colors.white38,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 
// ─── My Quizzes tab ───────────────────────────────────────────────────────────
 
class _MyQuizzesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
 
    return profileAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => Center(child: Text('$e')),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
 
        return FutureBuilder<List<QuizModel>>(
          future: ref
              .read(quizRepositoryProvider)
              .getMyQuizzes(profile.id),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            final quizzes = snap.data ?? [];
 
            if (quizzes.isEmpty) {
              return _EmptyQuizState();
            }
 
            return ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: quizzes.length,
              itemBuilder: (_, i) => _QuizCard(
                quiz: quizzes[i],
                index: i,
                onHost: () => _hostQuiz(context, ref, quizzes[i], profile.id),
                onDelete: () => _deleteQuiz(context, ref, quizzes[i].id!),
              ),
            );
          },
        );
      },
    );
  }
 
  Future<void> _hostQuiz(
    BuildContext context,
    WidgetRef ref,
    QuizModel quiz,
    String hostId,
  ) async {
    try {
      final session = await ref.read(gameRepositoryProvider).createSession(
            quizId: quiz.id!,
            hostId: hostId,
          );
      if (context.mounted) context.go('/lobby/${session.id}');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to create session: $e')));
    }
  }
 
  Future<void> _deleteQuiz(
      BuildContext context, WidgetRef ref, String quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12122A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Quiz?',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
        content: Text('This action cannot be undone.',
            style: GoogleFonts.nunito(color: Colors.white54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.nunito(color: Colors.white38))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: GoogleFonts.nunito(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(quizRepositoryProvider).deleteQuiz(quizId);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Quiz deleted')));
    }
  }
}
 
// ─── Quiz card ────────────────────────────────────────────────────────────────
 
class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final int index;
  final VoidCallback onHost;
  final VoidCallback onDelete;
 
  static const _cardGradients = [
    [Color(0xFF7C73FF), Color(0xFF4A3FF5)],
    [Color(0xFF00C9A7), Color(0xFF007A65)],
    [Color(0xFFFF6B6B), Color(0xFFCC2A2A)],
    [Color(0xFFFFBE0B), Color(0xFFCC8800)],
    [Color(0xFF845EC2), Color(0xFF4A1C6E)],
    [Color(0xFF0081CF), Color(0xFF004A7C)],
  ];
 
  const _QuizCard({
    required this.quiz,
    required this.index,
    required this.onHost,
    required this.onDelete,
  });
 
  @override
  Widget build(BuildContext context) {
    final gradient = _cardGradients[index % _cardGradients.length];
 
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: emoji + question count + menu
            Row(
              children: [
                Text(quiz.coverEmoji,
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${quiz.questions.length} question${quiz.questions.length == 1 ? '' : 's'}',
                        style: GoogleFonts.nunito(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: const Color(0xFF1A1A3E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      context.go('/edit-quiz/${quiz.id}');
                    } else if (val == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit_outlined,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 10),
                        Text('Edit',
                            style: GoogleFonts.nunito(color: Colors.white)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 18),
                        const SizedBox(width: 10),
                        Text('Delete',
                            style: GoogleFonts.nunito(
                                color: Colors.redAccent)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
 
            if (quiz.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                quiz.description,
                style: GoogleFonts.nunito(
                    color: Colors.white60, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
 
            const SizedBox(height: 16),
 
            // Host button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: quiz.questions.isEmpty ? null : onHost,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text('Host this quiz',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: gradient[1],
                  disabledBackgroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
 
            if (quiz.questions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '⚠️ Add questions before hosting',
                  style: GoogleFonts.nunito(
                      color: Colors.white60, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}
 
// ─── Empty quiz state ─────────────────────────────────────────────────────────
 
class _EmptyQuizState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF7C73FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('📋', style: TextStyle(fontSize: 48))),
            ),
            const SizedBox(height: 20),
            Text(
              'No quizzes yet',
              style: GoogleFonts.fredoka(
                  color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your\nfirst quiz!',
              style: GoogleFonts.nunito(
                  color: Colors.white38, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
 
// ─── Play tab ─────────────────────────────────────────────────────────────────
 
class _PlayTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PlayTab> createState() => _PlayTabState();
}
 
class _PlayTabState extends ConsumerState<_PlayTab> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
 
  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
 
          // Enter code card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF12122A)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFF7C73FF).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join a Game',
                  style: GoogleFonts.fredoka(
                      color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter the 6-character code from your host',
                  style: GoogleFonts.nunito(
                      color: Colors.white38, fontSize: 13),
                ),
                const SizedBox(height: 20),
 
                // Code input
                TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 32,
                    letterSpacing: 10,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '······',
                    hintStyle: GoogleFonts.fredoka(
                      color: Colors.white12,
                      fontSize: 32,
                      letterSpacing: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.07),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: Color(0xFF7C73FF), width: 2),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
 
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _codeCtrl.text.length == 6
                        ? _joinWithCode
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text('Join Game',
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C73FF),
                      disabledBackgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
 
          const SizedBox(height: 28),
 
          // How to play section
          Text(
            'How to play',
            style: GoogleFonts.fredoka(
                color: Colors.white, fontSize: 20),
          ).animate(delay: 100.ms).fadeIn(),
 
          const SizedBox(height: 14),
 
          ..._howToPlaySteps
              .asMap()
              .entries
              .map((e) => _HowToStep(
                    step: e.key + 1,
                    text: e.value,
                    index: e.key,
                  )),
        ],
      ),
    );
  }
 
  static const _howToPlaySteps = [
    'Get a 6-letter code from the quiz host',
    'Enter the code above or tap the join link',
    'Pick your nickname — or keep the fun one we picked!',
    'Answer as fast as you can — speed earns bonus points',
    'Watch the leaderboard to see who\'s winning 🏆',
  ];
 
  Future<void> _joinWithCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    
    // Check if user is logged in
    if (currentUser != null && !currentUser.isAnonymous) {
      // Logged-in user: join directly without going through join_screen
      _joinDirectly(code);
    } else {
      // Guest/Anonymous: use join_screen
      context.go('/join?code=$code');
    }
  }
  
  Future<void> _joinDirectly(String code) async {
    try {
      setState(() => _loading = true);
      final gameRepo = ref.read(gameRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      
      // Find session by code
      final session = await gameRepo.findByCode(code);
      if (session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game not found. Check the code and try again.')),
        );
        return;
      }
      
      // Get current user profile
      final currentUser = authRepo.currentUser;
      if (currentUser == null) {
        throw Exception('User not found');
      }
      
      final userProfile = await authRepo.getProfile(currentUser.id);
      if (userProfile == null) {
        throw Exception('Profile not found');
      }
      
      // Join the game session
      final player = await gameRepo.joinSession(
        sessionId: session.id,
        userId: currentUser.id,
        displayName: userProfile.displayName,
        avatarUrl: userProfile.avatarUrl,
      );
      
      // Give realtime stream a moment to reflect the new player
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) context.go('/join-lobby/${session.id}?playerId=${player.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
 
class _HowToStep extends StatelessWidget {
  final int step;
  final String text;
  final int index;
 
  const _HowToStep(
      {required this.step, required this.text, required this.index});
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF7C73FF).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF7C73FF).withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                '$step',
                style: GoogleFonts.fredoka(
                    color: const Color(0xFF7C73FF), fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: GoogleFonts.nunito(
                    color: Colors.white60, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 150 + index * 60))
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }
}
 
// ─── FAB ──────────────────────────────────────────────────────────────────────
 
class _CreateQuizFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.go('/create-quiz'),
      backgroundColor: const Color(0xFF7C73FF),
      elevation: 6,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text(
        'New Quiz',
        style: GoogleFonts.nunito(
            color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
