import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Animated background blobs ────────────────────────────────────────────────
 
class AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
 
  const AnimatedBackground({required this.controller});
 
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _BlobPainter(controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
 
class _BlobPainter extends CustomPainter {
  final double t;
  _BlobPainter(this.t);
 
  @override
  void paint(Canvas canvas, Size size) {
    final blobs = [
      _BlobData(
        center: Offset(
          size.width * (0.15 + 0.1 * math.sin(t * 2 * math.pi)),
          size.height * (0.2 + 0.08 * math.cos(t * 2 * math.pi)),
        ),
        radius: size.width * 0.35,
        color: const Color(0xFF7C73FF).withOpacity(0.12),
      ),
      _BlobData(
        center: Offset(
          size.width * (0.85 + 0.08 * math.cos(t * 2 * math.pi + 1)),
          size.height * (0.3 + 0.1 * math.sin(t * 2 * math.pi + 1)),
        ),
        radius: size.width * 0.28,
        color: const Color(0xFF00C9A7).withOpacity(0.08),
      ),
      _BlobData(
        center: Offset(
          size.width * (0.5 + 0.12 * math.sin(t * 2 * math.pi + 2)),
          size.height * (0.85 + 0.05 * math.cos(t * 2 * math.pi + 2)),
        ),
        radius: size.width * 0.32,
        color: const Color(0xFFFF6B6B).withOpacity(0.07),
      ),
    ];
 
    for (final blob in blobs) {
      final paint = Paint()
        ..color = blob.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
      canvas.drawCircle(blob.center, blob.radius, paint);
    }
  }
 
  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
 
class _BlobData {
  final Offset center;
  final double radius;
  final Color color;
  const _BlobData(
      {required this.center, required this.radius, required this.color});
}
 
// ─── Logo badge ───────────────────────────────────────────────────────────────
 
class LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9C94FF), Color(0xFF5A50FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C73FF).withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '⚡',
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}
 
// ─── Reusable input field ─────────────────────────────────────────────────────
 
class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
 
  const InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.nunito(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
                color: Colors.white.withOpacity(0.18), fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.white24, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFF7C73FF), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: GoogleFonts.nunito(
                color: Colors.redAccent, fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
 
// ─── Primary button ───────────────────────────────────────────────────────────
 
class PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
 
  const PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C73FF),
          disabledBackgroundColor: const Color(0xFF7C73FF).withOpacity(0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: const Color(0xFF7C73FF).withOpacity(0.4),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
 
// ─── Ghost / outline button ───────────────────────────────────────────────────
 
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
 
  const GhostButton({required this.label, required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: Colors.white.withOpacity(0.15), width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
 
// ─── Or divider ───────────────────────────────────────────────────────────────
 
class OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(color: Colors.white.withOpacity(0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: GoogleFonts.nunito(
                color: Colors.white24, fontSize: 13),
          ),
        ),
        Expanded(
            child: Divider(color: Colors.white.withOpacity(0.1))),
      ],
    );
  }
}
 
// ─── Error banner ─────────────────────────────────────────────────────────────
 
class ErrorBanner extends StatelessWidget {
  final String message;
 
  const ErrorBanner({required this.message});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                  color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().shakeX(hz: 3, amount: 4);
  }
}
 
// ─── Password strength bar ────────────────────────────────────────────────────
 
class PasswordStrengthBar extends StatelessWidget {
  final double strength;
  final Color color;
  final String label;
 
  const PasswordStrengthBar({
    required this.strength,
    required this.color,
    required this.label,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Password strength',
                style: GoogleFonts.nunito(
                    color: Colors.white38, fontSize: 11)),
            Text(label,
                style: GoogleFonts.nunito(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}