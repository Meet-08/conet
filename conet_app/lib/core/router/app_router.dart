import 'dart:async';

import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/widgets/main_scaffold.dart';
import 'package:conet_app/core/widgets/splash_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/add_details_page.dart';
import 'package:conet_app/feature/emailsign/pages/email_signup_page.dart';
import 'package:conet_app/feature/login/pages/login_page.dart';
import 'package:conet_app/feature/welcome/screens/welcome_screen.dart';
import 'package:conet_app/feature/googlesign/add_details_page.dart'
    as googlesign;

import 'package:conet_app/feature/postcreate/pages/create_post_page.dart';
import 'package:conet_app/feature/event/pages/event_page.dart';
import 'package:conet_app/feature/profile/pages/profile_page.dart';
import 'package:conet_app/feature/messages/pages/chat_detail_page.dart';  
import 'package:conet_app/feature/messages/pages/messages_page.dart'; 
import 'package:conet_app/feature/explore/pages/explore_page.dart'; 
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/home/pages/home_page.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/welcome',

    refreshListenable: GoRouterRefreshStream(
      serviceLocator<AppUserCubit>().stream,
    ),

    redirect: (context, state) {
      final userState = serviceLocator<AppUserCubit>().state;
      final location = state.uri.toString();

      if (userState is AppUserUnknown) return null;

      final isAuthRoute = [
        '/login',
        '/home',
        '/register',
        '/welcome',
        '/create-post',
        '/profile',
        '/event',
        '/explore', 
        '/messages',
        '/chat-detail', 
        '/emailsign',
        '/googlesign',
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
      // 🔹 Kept as-is (not default anymore)
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),

      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) => const LoginPage(),
      ),
  
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostPage(),
      ),
      GoRoute(
        path: '/emailsign',
        builder: (context, state) => const EmailSignupPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

      GoRoute(
        path: '/googlesign',
        builder: (context, state) =>
            const googlesign.AddDetailsPage(isGoogle: true),
      ),
     
      GoRoute(
        path: '/chat-detail',
        builder: (context, state) => const ChatDetailPage(),
      ),  

      // GoRoute(
      //   path: '/profile',
      //   builder: (context, state) => const ProfilePage(),
      // ),
      GoRoute(
        path: '/add-details',
        builder: (context, state) {
          final isGoogle = state.extra as bool? ?? true;
          return AddDetailsPage(isGoogle: isGoogle);
        },
      ),

      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomePage()),
          GoRoute(path: '/explore', builder: (_, _) => const ExplorePage()), // Added Explore
          GoRoute(path: '/event', builder: (_, _) => const EventPage()), // Moved EventPage here
          GoRoute(path: '/messages', builder: (_, _) => const MessagesPage()), // Switched to MessagesPage
          GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()), // Use ProfilePage or Placeholder? Kept Placeholder in orig but ProfilePage exists. Using Placeholder to match orig shell route unless user wants full profile. Reverting to Placeholder for internal tab if ProfilePage is top-level?
                                                                             
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
