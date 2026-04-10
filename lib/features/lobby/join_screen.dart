// lib/features/lobby/join_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/name_generator.dart';
import '../../core/utils/avatar_generator.dart';
import '../../data/repositories/providers.dart';

class JoinScreen extends ConsumerStatefulWidget {
  final String? code;
  
  const JoinScreen({super.key, this.code});
  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  late String _avatarSeed;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = NameGenerator.random();
    _avatarSeed = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Check if user is logged in
    final currentUser = ref.read(authRepositoryProvider).currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      // Logged-in users should not use join screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return;
    }
    
    // Pre-fill code if provided
    if (widget.code != null && widget.code!.isNotEmpty) {
      _codeCtrl.text = widget.code!.toUpperCase();
    }
  }
  

  
  @override
  void didUpdateWidget(JoinScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != null && widget.code != oldWidget.code) {
      _codeCtrl.text = widget.code!.toUpperCase();
    }
  }

  String get _avatarUrl => AvatarGenerator.generate(seed: _avatarSeed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Join a Quiz 🎮',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),

                // Avatar with refresh
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.white12,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: _avatarUrl,
                          width: 112, height: 112, fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _avatarSeed =
                            DateTime.now().millisecondsSinceEpoch.toString();
                        _nameCtrl.text = NameGenerator.random();
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF), 
                            shape: BoxShape.circle),
                        child: Icon(Icons.refresh,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Tap 🔄 to get a new look!',
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 24),

                // Editable name
                _buildField(
                  initialValue: _nameCtrl.text,
                  onChanged: (v) => _nameCtrl.text = v,
                  label: 'Your nickname',
                  icon: Icons.person_outline,
                  enabled: true,
                ),
                const SizedBox(height: 16),

                // Game code
                TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 24,
                      letterSpacing: 8, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'ENTER CODE',
                    hintStyle: const TextStyle(
                        color: Colors.white24, letterSpacing: 4, fontSize: 18),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _join,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Join!',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 18,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('Already have an account? Login',
                      style: GoogleFonts.poppins(color: Colors.white38)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String initialValue,
    required Function(String) onChanged,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: enabled ? onChanged : null,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the 6-character code')));
      return;
    }
    setState(() => _loading = true);
    try {
      final gameRepo = ref.read(gameRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      
      // Find session by code
      final session = await gameRepo.findByCode(code);
      if (session == null) {
        throw Exception('Game not found. Check the code and try again.');
      }

      // All users reaching join_screen are anonymous - sign in as guest
      final guestProfile = await authRepo.signInAsGuest(customName: _nameCtrl.text);
      final userId = guestProfile.id;
      final displayName = guestProfile.displayName;
      final avatarUrl = guestProfile.avatarUrl;

      // Join the game session
      final player = await gameRepo.joinSession(
        sessionId: session.id,
        userId: userId,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      // Give the realtime stream a moment to reflect the new player
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