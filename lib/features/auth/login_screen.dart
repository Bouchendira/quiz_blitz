// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/repositories/providers.dart';
import '../../main.dart';
 
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
 
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
 
class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePass = true;
  String? _errorMessage;
  late AnimationController _bgController;
 
  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }
 
  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _bgController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070718),
      body: Stack(
        children: [
          // ── Animated background blobs ──────────────────────────
          AnimatedBackground(controller: _bgController),
 
          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 32),
 
                        // Logo
                        LogoBadge()
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(begin: const Offset(0.7, 0.7)),
 
                        const SizedBox(height: 16),
 
                        Text(
                          'Welcome back!',
                          style: GoogleFonts.fredoka(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                            .animate(delay: 100.ms)
                            .fadeIn()
                            .slideY(begin: 0.3, end: 0),
 
                        const SizedBox(height: 6),
 
                        Text(
                          'Sign in to host or join quizzes',
                          style: GoogleFonts.nunito(
                            color: Colors.white38,
                            fontSize: 15,
                          ),
                        )
                            .animate(delay: 150.ms)
                            .fadeIn()
                            .slideY(begin: 0.3, end: 0),
 
                        const SizedBox(height: 40),
 
                        // ── Email field ──────────────────────────
                        InputField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'you@example.com',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        )
                            .animate(delay: 200.ms)
                            .fadeIn()
                            .slideX(begin: -0.1, end: 0),
 
                        const SizedBox(height: 14),
 
                        // ── Password field ───────────────────────
                        InputField(
                          controller: _passCtrl,
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePass,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Password must be 6+ characters'
                              : null,
                        )
                            .animate(delay: 250.ms)
                            .fadeIn()
                            .slideX(begin: -0.1, end: 0),
 
                        const SizedBox(height: 10),
 
                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPassword(),
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.nunito(
                                  color: const Color(0xFF7C73FF),
                                  fontSize: 13),
                            ),
                          ),
                        ),
 
                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 4),
                          ErrorBanner(message: _errorMessage!),
                          const SizedBox(height: 4),
                        ],
 
                        const SizedBox(height: 8),
 
                        // ── Login button ─────────────────────────
                        PrimaryButton(
                          label: 'Sign In',
                          loading: _loading,
                          onTap: _login,
                        )
                            .animate(delay: 300.ms)
                            .fadeIn()
                            .slideY(begin: 0.2, end: 0),
 
                        const SizedBox(height: 24),
 
                        // ── Divider ──────────────────────────────
                        OrDivider()
                            .animate(delay: 350.ms)
                            .fadeIn(),
 
                        const SizedBox(height: 24),
 
                        // ── Join as guest ────────────────────────
                        GhostButton(
                          label: '🎮  Join a quiz without account',
                          onTap: () => context.go('/join'),
                        )
                            .animate(delay: 400.ms)
                            .fadeIn()
                            .slideY(begin: 0.2, end: 0),
 
                        const SizedBox(height: 32),
 
                        // ── Register link ────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: GoogleFonts.nunito(
                                    color: Colors.white38, fontSize: 14)),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: Text(
                                'Create one',
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFF7C73FF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: const Color(0xFF7C73FF),
                                ),
                              ),
                            ),
                          ],
                        ).animate(delay: 450.ms).fadeIn(),
 
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).login(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _errorMessage = 'Incorrect email or password. Try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12122A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset Password',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email and we\'ll send a reset link.',
                style: GoogleFonts.nunito(
                    color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            InputField(
              controller: ctrl,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.nunito(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Supabase reset password
              await supabase.auth.resetPasswordForEmail(ctrl.text.trim());
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Reset link sent! Check your email.')));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C73FF)),
            child: Text('Send Link',
                style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

