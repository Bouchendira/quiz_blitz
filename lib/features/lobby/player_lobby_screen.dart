import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/game_session_model.dart';
import '../../data/models/game_player_model.dart';
import '../../data/repositories/providers.dart';
import '../../main.dart';
 
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
    // OR when host leaves and session is set to 'finished'
    ref.listen(watchSessionProvider(widget.sessionId), (prev, next) {
      print('[PLAYER-LISTENER] Previous: ${prev?.value?.status}, Next: ${next.value?.status}');
      next.whenData((session) {
        print('[PLAYER-LISTENER] Session status changed to: ${session.status}');
        print('[PLAYER-LISTENER] Status type: ${session.status.runtimeType}');
        print('[PLAYER-LISTENER] Checking question: ${session.status == GameStatus.question}');
        print('[PLAYER-LISTENER] Checking finished: ${session.status == GameStatus.finished}');
        
        if (session.status == GameStatus.question && mounted) {
          print('[PLAYER-LISTENER] ✓ Status is QUESTION - navigating to game');
          context.go(
            '/play/${widget.sessionId}?playerId=${widget.playerId ?? ''}',
          );
        } else if (session.status == GameStatus.finished && mounted) {
          print('[PLAYER-LISTENER] ✓ Status is FINISHED - host left! Redirecting...');
          final currentUser = ref.read(authRepositoryProvider).currentUser;
          final isLoggedIn = currentUser != null && !currentUser.isAnonymous;
          final destination = isLoggedIn ? '/home' : '/join';
          print('[PLAYER-LISTENER] Redirecting to: $destination');
          context.go(destination);
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
          // DEBUG: Log session status every build
          print('[PLAYER-BUILD] Session status: ${session.status}, mounted: $mounted');
          
          // Check if host left (status changed to finished)
          if (session.status == GameStatus.finished && mounted) {
            print('[PLAYER-BUILD] *** DETECTED FINISHED STATUS - Host left! ***');
            final currentUser = ref.read(authRepositoryProvider).currentUser;
            final isLoggedIn = currentUser != null && !currentUser.isAnonymous;
            final destination = isLoggedIn ? '/home' : '/join';
            print('[PLAYER-BUILD] Scheduling redirect to: $destination');
            
            // Use Future.microtask to avoid navigation during build
            Future.microtask(() {
              if (mounted) {
                print('[PLAYER-BUILD] Executing redirect to: $destination');
                context.go(destination);
              }
            });
          }
          
          return SafeArea(
            child: Column(
              children: [
                // ── Top section: game info ─────────────────────────────
                _TopBar(session: session, playerId: widget.playerId ?? '', sessionId: widget.sessionId),
 
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
  final String sessionId;
 
  const _TopBar({required this.session, required this.playerId, required this.sessionId});
 
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
            onPressed: () async {
              Navigator.pop(context);
              final currentUser = ref.read(authRepositoryProvider).currentUser;
              final isLoggedIn = currentUser != null && !currentUser.isAnonymous;
              final gameRepo = ref.read(gameRepositoryProvider);
              
              print('\n======================================');
              print('=== PLAYER LEAVING LOBBY ===');
              print('======================================');
              print('[LEAVE] Timestamp: ${DateTime.now()}');
              print('[LEAVE] Current User ID: ${currentUser?.id}');
              print('[LEAVE] Current User isAnonymous: ${currentUser?.isAnonymous}');
              print('[LEAVE] Session ID: $sessionId');
              print('[LEAVE] PlayerId from route: $playerId');
              print('[LEAVE] IsLoggedIn: $isLoggedIn');
              
              try {
                print('[LEAVE] Step 1: Checking if user is host...');
                final session = await gameRepo.getSession(sessionId);
                print('[LEAVE] Step 2: Got session - Status: ${session?.status}, HostId: ${session?.hostId}');
                
                if (session != null && session.hostId == currentUser?.id) {
                  print('[LEAVE] *** USER IS HOST *** - Ending game session');
                  await gameRepo.endSession(sessionId);
                  print('[LEAVE] ✓ Game session ended');
                } else {
                  print('[LEAVE] User is a PLAYER - Proceeding with removal');
                  
                  String? playerIdToRemove;
                  
                  // Try playerId from route first
                  if (playerId.isNotEmpty) {
                    playerIdToRemove = playerId;
                    print('[LEAVE] Using playerId from route: $playerId');
                  } else {
                    print('[LEAVE] playerId is empty, querying database...');
                    // Query database to find player
                    try {
                      print('[LEAVE] Querying: SELECT id FROM game_players WHERE session_id=$sessionId AND user_id=${currentUser!.id}');
                      final playersResponse = await supabase
                          .from('game_players')
                          .select('id, display_name')
                          .eq('session_id', sessionId)
                          .eq('user_id', currentUser!.id)
                          .maybeSingle();
                      
                      print('[LEAVE] Query result: $playersResponse');
                      
                      if (playersResponse != null) {
                        playerIdToRemove = playersResponse['id'];
                        print('[LEAVE] ✓ Found player in DB: $playerIdToRemove (${playersResponse['display_name']})');
                      } else {
                        print('[LEAVE] ✗ No player found in database!');
                      }
                    } catch (e) {
                      print('[LEAVE] ✗ Error finding player: $e');
                    }
                  }
                  
                  if (playerIdToRemove != null && playerIdToRemove.isNotEmpty) {
                    try {
                      print('[LEAVE] Attempting to remove player: $playerIdToRemove');
                      await gameRepo.removePlayer(playerIdToRemove);
                      print('[LEAVE] ✓ Player removal completed successfully');
                    } catch (e) {
                      print('[LEAVE] ✗ Error deleting player: $e');
                    }
                  } else {
                    print('[LEAVE] ✗ No playerIdToRemove available!');
                  }
                }
              } catch (e) {
                print('[LEAVE] ✗ Error checking host status: $e');
              }
              
              // Refresh cache
              print('[LEAVE] Step 3: Invalidating Riverpod caches...');
              print('[LEAVE] - Invalidating watchPlayersProvider($sessionId)');
              ref.invalidate(watchPlayersProvider(sessionId));
              print('[LEAVE] - Invalidating watchSessionProvider($sessionId)');
              ref.invalidate(watchSessionProvider(sessionId));
              print('[LEAVE] ✓ Caches invalidated - Stream will refresh');
              
              // Wait for updates
              print('[LEAVE] Step 4: Waiting 800ms for realtime stream to update...');
              await Future.delayed(const Duration(milliseconds: 800));
              print('[LEAVE] ✓ Wait complete');
              
              print('[LEAVE] Step 5: Navigating to ${isLoggedIn ? '/home' : '/join'}');
              context.go(isLoggedIn ? '/home' : '/join');
              print('[LEAVE] ✓ Navigation completed');
              print('=== DONE ===\n');
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
 