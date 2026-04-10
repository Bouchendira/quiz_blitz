// lib/features/results/results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/game_player_model.dart';
import '../../data/repositories/providers.dart';

class ResultsScreen extends ConsumerWidget {
  final String sessionId;
  const ResultsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watchPlayers already orders by total_score DESC
    final playersAsync = ref.watch(watchPlayersProvider(sessionId));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      body: playersAsync.when(
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF0D0D2B),
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: const Color(0xFF0D0D2B),
          body: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        ),
        data: (players) {
          final currentUser = ref.read(authRepositoryProvider).currentUser;
          final isGuest = currentUser?.isAnonymous ?? false;
          
          // Find current player to remove them when leaving
          final currentPlayer = players
              .where((p) => p.userId == currentUser?.id)
              .firstOrNull;
          
          return SafeArea(
            child: Column(children: [
              const SizedBox(height: 16),
              Text('🏆 Final Results',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 32,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${players.length} player${players.length == 1 ? '' : 's'} participated',
                  style: GoogleFonts.nunito(
                      color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 24),

              // Podium
              if (players.length >= 1)
                _Podium(top3: players.take(3).toList()),

              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Full Leaderboard',
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white12, indent: 20, endIndent: 20),

              // Full leaderboard
              Expanded(
                child: players.isEmpty
                    ? Center(
                        child: Text('No players completed the game',
                            style: GoogleFonts.poppins(color: Colors.white54)),
                      )
                    : ListView.builder(
                      itemCount: players.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (_, i) {
                        final p = players[i];
                        final medals = ['🥇', '🥈', '🥉'];
                        final rank = i < 3 ? medals[i] : '#${i + 1}';
                        final isWinner = i == 0;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: isWinner
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFFFFD700).withOpacity(0.2),
                                        const Color(0xFF6C63FF).withOpacity(0.1),
                                      ],
                                    )
                                  : null,
                              color: isWinner
                                  ? null
                                  : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: isWinner
                                  ? Border.all(
                                      color: const Color(0xFFFFD700).withOpacity(0.5),
                                      width: 1.5,
                                    )
                                  : null,
                              boxShadow: isWinner
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFFD700).withOpacity(0.1),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(rank,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center),
                                ),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFF6C63FF),
                                  child: ClipOval(
                                    child: p.avatarUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: p.avatarUrl,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Center(
                                              child: Text(
                                                p.displayName[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              p.displayName[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.displayName,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(
                                        i == 0
                                            ? 'Winner! 🎉'
                                            : '${(i).abs()} behind winner',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${p.totalScore}',
                                      style: GoogleFonts.poppins(
                                        color: isWinner
                                            ? const Color(0xFFFFD700)
                                            : const Color(0xFF6C63FF),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      'points',
                                      style: GoogleFonts.nunito(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: isGuest
                    ? SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (currentPlayer != null) {
                              ref.read(gameRepositoryProvider).removePlayer(currentPlayer.id);
                            }
                            context.go('/join');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text('Play Again',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (currentPlayer != null) {
                              ref.read(gameRepositoryProvider).removePlayer(currentPlayer.id);
                            }
                            context.go('/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.home),
                          label: Text('Home',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )),
                        ),
                      ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<GamePlayerModel> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    final heights = [90.0, 70.0, 50.0];
    final order = [1, 0, 2]; // display: 2nd, 1st, 3rd
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: order.map((i) {
        if (i >= top3.length) {
          return SizedBox.shrink();
        }
        final p = top3[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: i == 0 ? 32 : 24,
              backgroundColor: const Color(0xFF6C63FF),
              child: ClipOval(
                child: p.avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.avatarUrl,
                        width: i == 0 ? 64 : 48,
                        height: i == 0 ? 64 : 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Center(
                          child: Text(
                            p.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          p.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(['🥇', '🥈', '🥉'][i],
                style: const TextStyle(fontSize: 20)),
            Container(
              width: 80,
              height: heights[i],
              decoration: BoxDecoration(
                color: [
                  const Color(0xFFFFD700),
                  const Color(0xFFC0C0C0),
                  const Color(0xFFCD7F32),
                ][i].withOpacity(0.7),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(
                child: Text('${p.totalScore}',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}