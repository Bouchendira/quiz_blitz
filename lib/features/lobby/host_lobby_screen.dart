// lib/features/lobby/host_lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repositories/providers.dart';

class HostLobbyScreen extends ConsumerWidget {
  final String sessionId;
  const HostLobbyScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(watchSessionProvider(sessionId));
    final playersAsync = ref.watch(watchPlayersProvider(sessionId));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (session) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header with leave button
                Row(
                  children: [
                    const Spacer(),
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
                const SizedBox(height: 8),

                // Code display card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3F3D9F)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(children: [
                    Text('GAME CODE',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 13,
                            letterSpacing: 3)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(session.code,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 48,
                                fontWeight: FontWeight.w900, letterSpacing: 8)),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white70),
                          onPressed: () => Clipboard.setData(
                              ClipboardData(text: session.code)),
                        ),
                      ],
                    ),
                    Text('Share this code with your players',
                        style: GoogleFonts.poppins(
                            color: Colors.white60, fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 24),

                // Player grid — live updated via Supabase Realtime
                Expanded(
                  child: playersAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (players) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Players (${players.length})',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: players.isEmpty
                              ? Center(
                                  child: Text('Waiting for players...',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white38)))
                              : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 110,
                                    childAspectRatio: 0.8,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: players.length,
                                  itemBuilder: (_, i) {
                                    final p = players[i];
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          child: ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: p.avatarUrl,
                                              width: 56, height: 56,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(p.displayName,
                                            style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 11),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Start button
                playersAsync.maybeWhen(
                  data: (players) => players.isNotEmpty
                      ? SizedBox(
                          width: double.infinity, height: 56,
                          child: ElevatedButton(
                            onPressed: () async {
                              await ref
                                  .read(gameRepositoryProvider)
                                  .startGame(sessionId);
                              if (context.mounted) {
                                context.go('/host-game/$sessionId');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('Start Game! 🚀',
                                style: GoogleFonts.poppins(
                                    color: Colors.black, fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                          ),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
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
        content: Text('This will end the game for all players.',
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