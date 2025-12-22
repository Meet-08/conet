import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/auth/presentation/pages/register_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/result_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final user = extra?['user'] as User?;
          if (user == null) {
            return const Scaffold(
              body: Center(child: Text('User data not found')),
            );
          }
          return ResultPage(user: user);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
}
