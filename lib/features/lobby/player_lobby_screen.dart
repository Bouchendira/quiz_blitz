import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/game_session_model.dart';
import '../../data/models/game_player_model.dart';
import '../../data/repositories/providers.dart';
 
class PlayerLobbyScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String? playerId;

  const PlayerLobbyScreen({super.key, required this.sessionId, this.playerId});
 
  @override
  ConsumerState<PlayerLobbyScreen> createState() => _PlayerLobbyScreenState();
}
 
class _PlayerLobbyScreenState extends ConsumerState<PlayerLobbyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
 
  @override
  void initState() {
    super.initState();
    // Looping animation for the "waiting" pulse effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }
 
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(watchSessionProvider(widget.sessionId));
    final playersAsync = ref.watch(watchPlayersProvider(widget.sessionId));
 
    // Listen to session changes to auto-navigate when host starts the game
    ref.listen(watchSessionProvider(widget.sessionId), (_, next) {
      next.whenData((session) {
        if (session.status == GameStatus.question && mounted) {
          context.go(
            '/play/${widget.sessionId}?playerId=${widget.playerId ?? ''}',
          );
        }
      });
    });
 
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      body: sessionAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Text('Something went wrong: $e',
              style: const TextStyle(color: Colors.white)),
        ),
        data: (session) {
          return SafeArea(
            child: Column(
              children: [
                // ── Top section: game info ─────────────────────────────
                _TopBar(session: session, playerId: widget.playerId ?? ''),
 
                // ── Waiting animation ──────────────────────────────────
                const SizedBox(height: 24),
                _WaitingIndicator(controller: _pulseController),
                const SizedBox(height: 32),
 
                // ── Player grid — live updated ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      playersAsync.maybeWhen(
                        data: (players) => Text(
                          '${players.length} player${players.length == 1 ? '' : 's'} joined',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
 
                Expanded(
                  child: playersAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (players) => players.isEmpty
                        ? _EmptyPlayersHint()
                        : _PlayerGrid(players: players),
                  ),
                ),
 
                // ── Bottom: your profile card ──────────────────────────
                _MyProfileCard(sessionId: widget.sessionId),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
 
// ─── Top bar showing the game code ───────────────────────────────────────────
 
class _TopBar extends ConsumerWidget {
  final GameSessionModel session;
  final String playerId;
 
  const _TopBar({required this.session, required this.playerId});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF3F3D9F)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '⚡ QuizBlitz',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Leave button
              TextButton.icon(
                onPressed: () => _confirmLeave(context, ref),
                icon: const Icon(Icons.exit_to_app,
                    color: Colors.white60, size: 18),
                label: Text('Leave',
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re in! 🎉',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Waiting for the host to start the game...',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Game code display (read-only for player, just for reference)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag, color: Colors.white60, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Room: ${session.code}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  void _confirmLeave(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A3E),
        title: Text('Leave game?',
            style: GoogleFonts.poppins(color: Colors.white)),
        content: Text('You\'ll lose your spot in the lobby.',
            style: GoogleFonts.poppins(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Stay',
                style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Check if user is logged in (not anonymous)
              final currentUser = ref.read(authRepositoryProvider).currentUser;
              final isLoggedIn = currentUser != null && !currentUser.isAnonymous;
              
              // Remove player from the game session
              final gameRepo = ref.read(gameRepositoryProvider);
              gameRepo.removePlayer(playerId);
              
              // Navigate to home for logged-in users, join for guests
              context.go(isLoggedIn ? '/home' : '/join');
            },
            child: Text('Leave',
                style: GoogleFonts.poppins(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
 
// ─── Animated waiting indicator ───────────────────────────────────────────────
 
class _WaitingIndicator extends StatelessWidget {
  final AnimationController controller;
 
  const _WaitingIndicator({required this.controller});
 
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Column(
          children: [
            // Three bouncing dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                // Stagger each dot's animation
                final delay = i * 0.15;
                final value = (controller.value + delay) % 1.0;
                final bounce = (value < 0.5 ? value * 2 : (1 - value) * 2);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12,
                  height: 12,
                  transform: Matrix4.translationValues(
                      0, -12 * bounce, 0),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFF6C63FF),
                      Colors.white,
                      bounce,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Get ready!',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.4 + controller.value * 0.6),
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}
 
// ─── Grid of all joined players ──────────────────────────────────────────────
 
class _PlayerGrid extends StatelessWidget {
  final List<GamePlayerModel> players;
 
  const _PlayerGrid({required this.players});
 
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: players.length,
      itemBuilder: (_, i) {
        final player = players[i];
        return _PlayerCard(player: player, index: i);
      },
    );
  }
}
 
class _PlayerCard extends StatelessWidget {
  final GamePlayerModel player;
  final int index;
 
  const _PlayerCard({required this.player, required this.index});
 
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white12,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: player.avatarUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (_, __) => const CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white54),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          player.displayName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.3, end: 0, duration: 300.ms);
  }
}
 
// ─── Empty state hint ─────────────────────────────────────────────────────────
 
class _EmptyPlayersHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎮', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'You\'re the first one here!',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Others will appear when they join',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
 
// ─── Current player's own profile card at the bottom ─────────────────────────
 
class _MyProfileCard extends ConsumerWidget {
  final String sessionId;
 
  const _MyProfileCard({required this.sessionId});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.read(authRepositoryProvider).currentUser?.id;
    final playersAsync = ref.watch(watchPlayersProvider(sessionId));
 
    return playersAsync.maybeWhen(
      data: (players) {
        final me = players.where((p) => p.userId == myUid).firstOrNull;
        if (me == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: me.avatarUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      me.displayName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'That\'s you!',
                      style: GoogleFonts.poppins(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.4)),
                ),
                child: Text(
                  '✓ Ready',
                  style: GoogleFonts.poppins(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
 