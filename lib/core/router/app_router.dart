// lib/core/router/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../../features/game/host_game_screen.dart';
import '../../features/game/player_game_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/quiz_creator/quiz_creator_screen.dart';
import '../../features/lobby/host_lobby_screen.dart';
import '../../features/lobby/join_screen.dart';
import '../../features/lobby/player_lobby_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';    

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = supabase.auth.currentUser;
      final goingToAuth = ['/login', '/register', '/join']
          .any((p) => state.matchedLocation.startsWith(p));
      
      // Check if user is anonymous/guest
      final isGuest = user != null && user.isAnonymous;
      
      // Guest-allowed routes - anonymous users can access these
      final guestAllowedRoutes = ['/join', '/join-lobby', '/play', '/results', '/login', '/register']
          .any((p) => state.matchedLocation.startsWith(p));

      if (user == null && !goingToAuth) return '/login';
      
      // Anonymous/guest users trying to access protected routes should go to /join
      if (isGuest && !guestAllowedRoutes && !goingToAuth) return '/join';
      
      // Authenticated non-guest users trying to access auth pages should go to home
      if (user != null && !isGuest && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) return '/home';
      
      return null;
    },
    routes: [
      GoRoute(path: '/login',       builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',    builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/join',
        builder: (_, s) => JoinScreen(code: s.uri.queryParameters['code']),
      ),
      GoRoute(path: '/home',        builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/profile',     builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings',    builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/create-quiz', builder: (_, __) => const QuizCreatorScreen()),
      GoRoute(
        path: '/lobby/:sessionId',
        builder: (_, s) => HostLobbyScreen(
            sessionId: s.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/join-lobby/:sessionId',
        builder: (_, s) => PlayerLobbyScreen(
             sessionId: s.pathParameters['sessionId']!,
             playerId: s.uri.queryParameters['playerId'],
        ),
        
      ),
      GoRoute(
        path: '/host-game/:sessionId',
        builder: (_, s) => HostGameScreen(
            sessionId: s.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/play/:sessionId',
        builder: (_, s) => PlayerGameScreen(
          sessionId: s.pathParameters['sessionId']!,
          playerId: s.uri.queryParameters['playerId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/results/:sessionId',
        builder: (_, s) => ResultsScreen(
            sessionId: s.pathParameters['sessionId']!),
      ),
    ],
  );
});