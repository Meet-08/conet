import 'dart:async';

import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/widgets/main_scaffold.dart';
import 'package:conet_app/core/widgets/splash_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/add_details_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/login_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/register_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/welcome_page.dart';
import 'package:conet_app/feature/message/presentation/pages/chat_page.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/presentation/pages/home_page.dart';
import 'package:conet_app/feature/post/presentation/pages/post_page.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: "/",
    refreshListenable: GoRouterRefreshStream(
      serviceLocator<AppUserCubit>().stream,
    ),
    redirect: (context, state) {
      final userState = serviceLocator<AppUserCubit>().state;
      final location = state.uri.toString();

      if (userState is AppUserUnknown) return null;

      final isAuthRoute = [
        '/login',
        '/register',
        '/welcome',
      ].contains(location);

      if (userState is AppUserUnauthenticated) {
        return isAuthRoute ? null : '/welcome';
      }

      if (userState is AppUserAuthenticated) {
        if (userState.user.username.isEmpty && location != '/add-details') {
          return '/add-details';
        }

        if (userState.user.username.isNotEmpty &&
            (isAuthRoute || location == '/')) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/add-details',
        builder: (context, state) {
          final isGoogle = state.extra as bool? ?? true;
          return AddDetailsPage(isGoogle: isGoogle);
        },
      ),
      GoRoute(
        path: '/post',
        builder: (context, state) => PostPage(post: state.extra as Post),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomePage()),
          GoRoute(path: '/event', builder: (_, _) => const Placeholder()),
          GoRoute(path: '/chat', builder: (_, _) => const ChatPage()),
          GoRoute(path: '/profile', builder: (_, _) => const Placeholder()),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
