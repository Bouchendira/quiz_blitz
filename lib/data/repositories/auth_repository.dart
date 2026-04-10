// lib/data/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/avatar_generator.dart';
import '../../core/utils/name_generator.dart';
import '../../main.dart'; // for supabase global
import '../models/profile_model.dart';
class AuthRepository {
  // ── Auth state stream ─────────────────────────────────────────────
  Stream<AuthState> get authStateChanges =>
      supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );

    final user = response.user;
    if (user != null) {
      // User is logged in (no email confirmation required)
      await Future.delayed(const Duration(milliseconds: 200));

      // 🔍 Check if profile already exists
      final existing = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) {
        // ✅ Profile already exists → do nothing
        return;
      }

      // ✅ Insert only if not exists
      await supabase.from('profiles').insert({
        'id': user.id,
        'display_name': displayName,
        'avatar_url': AvatarGenerator.generate(seed: user.id),
        'is_guest': false,
      });
    }
    // If user is null, email confirmation is required, profile will be created on login
  }

  // ── Login ─────────────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Ensure profile exists
      final existing = await supabase
          .from('profiles')
          .select('id')
          .eq('id', response.user!.id)
          .maybeSingle();
      if (existing == null) {
        await supabase.from('profiles').insert({
          'id': response.user!.id,
          'display_name': response.user!.userMetadata?['display_name'] ?? 'User',
          'avatar_url': AvatarGenerator.generate(seed: response.user!.id),
          'is_guest': false,
        });
      }
    }
  }

  // ── Guest sign-in (Anonymous) ─────────────────────────────────────
  // Supabase supports anonymous sign-in natively
  Future<ProfileModel> signInAsGuest({String? customName}) async {
    final displayName = customName ?? NameGenerator.random();
    final response = await supabase.auth.signInAnonymously();

    if (response.user == null) throw Exception('Guest sign-in failed');
    final uid = response.user!.id;

    // Create profile
    await supabase.from('profiles').upsert({
      'id': uid,
      'display_name': displayName,
      'avatar_url': AvatarGenerator.generate(seed: uid),
      'is_guest': true,
    });

    return _fetchProfile(uid);
  }

  Future<void> signOut() => supabase.auth.signOut();

  Future<ProfileModel> _fetchProfile(String uid) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .single();
    return ProfileModel.fromMap(data);
  }

  Future<ProfileModel?> getProfile(String uid) async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', uid)
          .single();
      return ProfileModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }
}