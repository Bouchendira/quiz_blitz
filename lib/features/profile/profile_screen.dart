// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repositories/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070718),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1040),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('My Profile',
            style: GoogleFonts.fredoka(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text('Profile not found',
                  style: GoogleFonts.nunito(color: Colors.white)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile header
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 56,
                  backgroundColor: const Color(0xFF7C73FF),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profile.avatarUrl,
                      width: 112,
                      height: 112,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          profile.displayName[0].toUpperCase(),
                          style: GoogleFonts.fredoka(
                              color: Colors.white, fontSize: 48),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(profile.displayName,
                    style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: profile.isGuest
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.isGuest ? '👤 Guest Player' : '✓ Registered User',
                    style: GoogleFonts.nunito(
                      color:
                          profile.isGuest ? Colors.orange : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Stats section
                if (!profile.isGuest)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Stats',
                          style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: '🎮',
                              label: 'Quizzes Taken',
                              value: profile.quizzesTaken.toString(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: '🏆',
                              label: 'Total Points',
                              value: profile.totalPoints.toString(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Profile info section
                      Text('Profile Information',
                          style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(label: 'Display Name', value: profile.displayName),
                            const Divider(color: Colors.white12),
                            _InfoRow(
                              label: 'Member Since',
                              value: profile.createdAt.year.toString(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Quiz History section
                      Text('Quiz History',
                          style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _QuizHistoryPlaceholder(),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      border:
                          Border.all(color: Colors.orange.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('👤',
                            style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text('Guest Player',
                            style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          'Sign up to save your progress and compete in leaderboards!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C73FF),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Sign Up Now',
                                style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7C73FF).withOpacity(0.2),
            const Color(0xFF6C63FF).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C73FF).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.fredoka(
                  color: const Color(0xFF7C73FF),
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  color: Colors.white70, fontSize: 14)),
          Text(value,
              style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuizHistoryPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('📚',
              style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('No quizzes yet',
              style: GoogleFonts.fredoka(
                  color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Start playing quizzes to see your history here!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
