import 'dart:async';

import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/widgets/splash_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/add_details_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/login_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/register_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/welcome_page.dart';
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

      if (userState is AppUserUnknown) {
        return null;
      }

      final isAuthPath =
          state.uri.toString() == '/login' ||
          state.uri.toString() == '/register' ||
          state.uri.toString() == '/welcome';

      if (userState is AppUserUnauthenticated) {
        return isAuthPath ? null : '/welcome';
      }

      if (userState is AppUserAuthenticated) {
        if (userState.user.username.isEmpty &&
            state.uri.toString() != '/add-details') {
          return '/add-details';
        }

        if (userState.user.username.isNotEmpty &&
            state.uri.toString() == '/add-details') {
          return '/home';
        }

        if (isAuthPath || state.uri.toString() == '/') return '/home';
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
        path: '/home',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('You are logged in'))),
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
