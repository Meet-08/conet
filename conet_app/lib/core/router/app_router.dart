import 'dart:async';

import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/widgets/main_scaffold.dart';
import 'package:conet_app/core/widgets/splash_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/add_details_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/email_signup_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/login_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/welcome_page.dart';
import 'package:conet_app/feature/event/pages/event_page.dart';
import 'package:conet_app/feature/explore/pages/explore_page.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/presentation/pages/chat_detail_page.dart';
import 'package:conet_app/feature/message/presentation/pages/messages_page.dart';
import 'package:conet_app/feature/post/presentation/pages/create_post_page.dart';
import 'package:conet_app/feature/post/presentation/pages/feed_page.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_about_me_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_academic_info_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_interests_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_personal_info_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_profile_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_profile_pictures_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_social_links_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/profile_page.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    // Start on splash page during auth check
    initialLocation: '/',

    refreshListenable: GoRouterRefreshStream(
      serviceLocator<AppUserCubit>().stream,
    ),

    redirect: (context, state) {
      final userState = serviceLocator<AppUserCubit>().state;
      final location = state.uri.toString();

      // Auth pages that unauthenticated users can access
      final publicAuthRoutes = [
        '/welcome',
        '/login',
        '/register',
        '/email-signup',
        '/add-details',
      ];

      // Routes that authenticated users with complete profile can access
      final protectedRoutes = [
        '/home',
        '/create-post',
        '/profile',
        '/edit-profile',
        '/event',
        '/explore',
        '/messages',
        '/chat-detail',
      ];

      // While auth state is unknown, stay on/go to splash
      if (userState is AppUserUnknown) {
        return location == '/' ? null : '/';
      }

      // User is not authenticated
      if (userState is AppUserUnauthenticated) {
        // If on splash or protected route, go to welcome
        if (location == '/' || protectedRoutes.contains(location)) {
          return '/welcome';
        }
        // Otherwise stay where they are (login, signup, etc.)
        return null;
      }

      // User is authenticated
      if (userState is AppUserAuthenticated) {
        final hasUsername = userState.user.username.isNotEmpty;

        // If user doesn't have username, force to add-details
        if (!hasUsername && location != '/add-details') {
          return '/add-details';
        }

        // If user has complete profile and is on splash/auth routes, go home
        if (hasUsername) {
          if (location == '/' || publicAuthRoutes.contains(location)) {
            return '/home';
          }
        }
      }

      return null;
    },

    routes: [
      // Splash page shown during auth check
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),

      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
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
        path: '/email-signup',
        builder: (context, state) => const EmailSignupPage(),
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
        path: '/chat-detail',
        builder: (context, state) {
          final conversation = state.extra as Conversation;
          return ChatDetailPage(conversation: conversation);
        },
      ),

      GoRoute(
        path: '/edit-profile',
        builder: (_, _) => const EditProfilePage(),
        routes: [
          GoRoute(
            path: ':section',
            builder: (_, state) {
              final section = state.pathParameters['section'];
              final userProfile = state.extra as UserProfile?;

              if (userProfile == null) {
                return const Scaffold(
                  body: Center(
                    child: Text("Error: No user profile data provided"),
                  ),
                );
              }

              return switch (section) {
                'personal-info' => EditPersonalInfoPage(
                  userProfile: userProfile,
                ),
                'academic-info' => EditAcademicInfoPage(
                  userProfile: userProfile,
                ),
                'about-me' => EditAboutMePage(userProfile: userProfile),
                'interests' => EditInterestsPage(userProfile: userProfile),
                'social-links' => EditSocialLinksPage(userProfile: userProfile),
                'pictures' => EditProfilePicturesPage(userProfile: userProfile),
                _ => EditPersonalInfoPage(userProfile: userProfile),
              };
            },
          ),
        ],
      ),

      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const FeedPage()),
          GoRoute(path: '/explore', builder: (_, _) => const ExplorePage()),
          GoRoute(path: '/event', builder: (_, _) => const EventPage()),
          GoRoute(path: '/messages', builder: (_, _) => const MessagesPage()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Defer initial notification until after first frame to avoid assertion error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
