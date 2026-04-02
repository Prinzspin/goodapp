import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/events/presentation/home_screen.dart';
import 'package:frontend_flutter/features/events/presentation/event_detail_screen.dart';
import 'package:frontend_flutter/features/events/presentation/event_form_screen.dart';
import 'package:frontend_flutter/features/events/presentation/likes_screen.dart';
import 'package:frontend_flutter/features/map/presentation/map_screen.dart';
import 'package:frontend_flutter/features/chat/presentation/chat_list_screen.dart';
import 'package:frontend_flutter/features/chat/presentation/chat_detail_screen.dart';
import 'package:frontend_flutter/features/profile/presentation/profile_screen.dart';
import 'package:frontend_flutter/features/auth/presentation/login_screen.dart';
import 'package:frontend_flutter/features/auth/presentation/register_screen.dart';
import 'package:frontend_flutter/features/auth/presentation/splash_screen.dart';
import 'package:frontend_flutter/shared/providers/auth_provider.dart';
import 'package:frontend_flutter/shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      
      // Navigation Shell pour Accueil, Carte, Likes
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
          GoRoute(path: '/likes', builder: (context, state) => const LikesScreen()),
        ],
      ),

      // Routes hors Shell (sans footer)
      GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatDetailScreen(eventId: id);
        },
      ),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/event/create', builder: (context, state) => const EventFormScreen()),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EventDetailScreen(eventId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isAuthenticated = authState != null;

      if (isSplash) return isAuthenticated ? '/home' : '/login';
      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/home';
      return null;
    },
  );
});
