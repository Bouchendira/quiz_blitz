// lib/features/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/shared_widgets.dart';
import '../../data/repositories/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
 
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}
 
class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  late AnimationController _bgController;
 
  // Password strength
  double get _passStrength {
    final p = _passCtrl.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.25;
    if (p.contains(RegExp(r'[0-9]'))) s += 0.25;
    if (p.contains(RegExp(r'[!@#\$&*~]'))) s += 0.25;
    return s;
  }
 
  Color get _strengthColor {
    final s = _passStrength;
    if (s <= 0.25) return Colors.redAccent;
    if (s <= 0.5) return Colors.orangeAccent;
    if (s <= 0.75) return Colors.yellowAccent;
    return Colors.greenAccent;
  }
 
  String get _strengthLabel {
    final s = _passStrength;
    if (s <= 0.25) return 'Weak';
    if (s <= 0.5) return 'Fair';
    if (s <= 0.75) return 'Good';
    return 'Strong 💪';
  }
 
  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    // Rebuild on password change for strength meter
    _passCtrl.addListener(() => setState(() {}));
  }
 
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _bgController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070718),
      body: Stack(
        children: [
          AnimatedBackground(controller: _bgController),
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
 
                        LogoBadge()
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scale(begin: const Offset(0.7, 0.7)),
 
                        const SizedBox(height: 16),
 
                        Text(
                          'Create account',
                          style: GoogleFonts.fredoka(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w600),
                        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.3),
 
                        const SizedBox(height: 6),
 
                        Text(
                          'Join QuizBlitz and start creating!',
                          style: GoogleFonts.nunito(
                              color: Colors.white38, fontSize: 15),
                        ).animate(delay: 150.ms).fadeIn(),
 
                        const SizedBox(height: 36),
 
                        // Name
                        InputField(
                          controller: _nameCtrl,
                          label: 'Display Name',
                          hint: 'How should we call you?',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.trim().length < 2
                              ? 'Name must be at least 2 characters'
                              : null,
                        )
                            .animate(delay: 200.ms)
                            .fadeIn()
                            .slideX(begin: -0.1),
 
                        const SizedBox(height: 14),
 
                        // Email
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
                            .animate(delay: 250.ms)
                            .fadeIn()
                            .slideX(begin: -0.1),
 
                        const SizedBox(height: 14),
 
                        // Password
                        InputField(
                          controller: _passCtrl,
                          label: 'Password',
                          hint: 'Min. 6 characters',
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
                            .animate(delay: 300.ms)
                            .fadeIn()
                            .slideX(begin: -0.1),
 
                        // Password strength meter
                        if (_passCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          PasswordStrengthBar(
                            strength: _passStrength,
                            color: _strengthColor,
                            label: _strengthLabel,
                          ).animate().fadeIn(),
                        ],
 
                        const SizedBox(height: 14),
 
                        // Confirm password
                        InputField(
                          controller: _confirmCtrl,
                          label: 'Confirm Password',
                          hint: 'Repeat your password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator: (v) => v != _passCtrl.text
                              ? 'Passwords do not match'
                              : null,
                        )
                            .animate(delay: 350.ms)
                            .fadeIn()
                            .slideX(begin: -0.1),
 
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          ErrorBanner(message: _errorMessage!),
                        ],
 
                        const SizedBox(height: 24),
 
                        PrimaryButton(
                          label: 'Create Account',
                          loading: _loading,
                          onTap: _register,
                        )
                            .animate(delay: 400.ms)
                            .fadeIn()
                            .slideY(begin: 0.2),
 
                        const SizedBox(height: 32),
 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ',
                                style: GoogleFonts.nunito(
                                    color: Colors.white38, fontSize: 14)),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Text(
                                'Sign in',
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
 
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).register(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            displayName: _nameCtrl.text.trim(),
          );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _errorMessage = 'Registration failed. $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
