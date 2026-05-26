// ============================================================
// Guru App Router
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wtf_shared/services/services.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import 'chat_list_screen.dart';
import 'chat_screen.dart';
import 'schedule_screen.dart';
import 'requests_screen.dart';
import 'sessions_screen.dart';
import 'call_screen.dart';

GoRouter buildRouter(AuthService authService) => GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final onboarded = await authService.isOnboardingDone();
    if (!onboarded && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    if (onboarded && state.matchedLocation == '/') {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(
      path: '/home',
      builder: (_, _) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'chat',
          builder: (_, _) => const ChatListScreen(),
          routes: [
            GoRoute(
              path: ':chatId',
              builder: (_, state) =>
                  ChatScreen(chatId: state.pathParameters['chatId']!),
            ),
          ],
        ),
        GoRoute(path: 'schedule', builder: (_, _) => const ScheduleScreen()),
        GoRoute(path: 'requests', builder: (_, _) => const RequestsScreen()),
        GoRoute(path: 'sessions', builder: (_, _) => const SessionsScreen()),
        GoRoute(
          path: 'call/:requestId',
          builder: (_, state) =>
              CallScreen(requestId: state.pathParameters['requestId']!),
        ),
      ],
    ),
    GoRoute(path: '/', builder: (_, _) => const Scaffold()),
  ],
);
