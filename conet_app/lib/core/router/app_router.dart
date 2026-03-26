import 'dart:async';

import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/widgets/main_scaffold.dart';
import 'package:conet_app/core/widgets/splash_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/add_details_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/email_signup_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/login_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/welcome_page.dart';
import 'package:conet_app/feature/event/presentation/constants/event_constants.dart';
import 'package:conet_app/feature/event/presentation/pages/create_event_page.dart';
import 'package:conet_app/feature/event/presentation/pages/event_detail_page.dart';
import 'package:conet_app/feature/event/presentation/pages/event_page.dart';
import 'package:conet_app/feature/event/presentation/pages/my_events_page.dart';
import 'package:conet_app/feature/explore/pages/explore_page.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/presentation/pages/chat_detail_page.dart';
import 'package:conet_app/feature/message/presentation/pages/messages_page.dart';
import 'package:conet_app/feature/notification/presentation/pages/notification_page.dart'
    as notification_ui;
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/presentation/bloc/liked_posts_bloc.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/pages/create_post_page.dart';
import 'package:conet_app/feature/post/presentation/pages/feed_page.dart';
import 'package:conet_app/feature/post/presentation/pages/post_detail_page.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_about_me_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_academic_info_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_interests_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_personal_info_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_profile_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_profile_pictures_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_social_links_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/profile_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/saved/liked_post.dart';
import 'package:conet_app/feature/profile/presentation/pages/saved/saved_post.dart';
import 'package:conet_app/feature/profile/presentation/pages/settings_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/user_profile_page.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static String? _pendingRedirectLocation;

  static const Set<String> _publicAuthRoutes = {
    '/welcome',
    '/login',
    '/register',
    '/email-signup',
    '/add-details',
  };

  static bool _isAuthRoute(String path) => _publicAuthRoutes.contains(path);

  static String _locationFromUri(Uri uri) {
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '${uri.path}$query';
  }

  static String? _sanitizeRedirect(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('/')) return null;

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    if (uri.path == '/' || _isAuthRoute(uri.path)) return null;
    return value;
  }

  static void _rememberRedirect(String location) {
    final sanitized = _sanitizeRedirect(location);
    if (sanitized != null) {
      _pendingRedirectLocation = sanitized;
    }
  }

  static String? _resolveRedirectCandidate(Uri currentUri) {
    final fromQuery = _sanitizeRedirect(currentUri.queryParameters['redirect']);
    return fromQuery ?? _pendingRedirectLocation;
  }

  static String _buildAuthPath(String basePath, String? redirectTarget) {
    if (redirectTarget == null) return basePath;
    return Uri(
      path: basePath,
      queryParameters: {'redirect': redirectTarget},
    ).toString();
  }

  static final router = GoRouter(
    // Start on splash page during auth check
    initialLocation: '/',

    refreshListenable: GoRouterRefreshStream(
      serviceLocator<AppUserCubit>().stream,
    ),

    redirect: (context, state) {
      final userState = serviceLocator<AppUserCubit>().state;
      final uri = state.uri;
      final path = uri.path;
      final location = _locationFromUri(uri);

      // While auth state is unknown, stay on/go to splash
      if (userState is AppUserUnknown) {
        if (path == '/') return null;
        _rememberRedirect(location);
        return '/';
      }

      // User is not authenticated
      if (userState is AppUserUnauthenticated) {
        if (path == '/') {
          final redirect = _resolveRedirectCandidate(uri);
          return _buildAuthPath('/welcome', redirect);
        }

        // Keep query redirect if auth pages are opened manually after deep-link.
        if (_isAuthRoute(path)) {
          final redirectInQuery = _sanitizeRedirect(
            uri.queryParameters['redirect'],
          );
          if (redirectInQuery != null) {
            _pendingRedirectLocation = redirectInQuery;
          }
          return null;
        }

        // Any non-auth page is protected for unauthenticated users.
        _rememberRedirect(location);
        return _buildAuthPath('/welcome', _pendingRedirectLocation);
      }

      // User is authenticated
      if (userState is AppUserAuthenticated) {
        final hasUsername = userState.user.username.isNotEmpty;
        final redirectTarget = _resolveRedirectCandidate(uri);

        // If user doesn't have username, force to add-details
        if (!hasUsername && path != '/add-details') {
          return _buildAuthPath('/add-details', redirectTarget);
        }

        // If user has complete profile and is on splash/auth routes, go to pending target first.
        if (hasUsername) {
          if (path == '/' || _isAuthRoute(path)) {
            final destination = _sanitizeRedirect(redirectTarget);
            _pendingRedirectLocation = null;
            return destination ?? '/home';
          }

          // Already on app content; pending redirect no longer needed.
          _pendingRedirectLocation = null;
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
        path: '/create-event',
        builder: (context, state) => const CreateEventPage(),
      ),

      GoRoute(
        path: '/event-detail/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id'];
          if (eventId == null || eventId.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Invalid event id')),
            );
          }

          return EventDetailPage(eventId: eventId);
        },
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
        path: '/post-detail/:id',
        builder: (context, state) {
          final post = state.extra as Post?;
          final postId = state.pathParameters['id'];

          if (post != null) {
            return PostDetailPage(post: post);
          }

          return PostDetailPage(postId: postId);
        },
      ),

      GoRoute(
        path: '/user-profile',
        builder: (context, state) {
          final userId = state.extra as String;
          return UserProfilePage(userId: userId);
        },
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),

      GoRoute(
        path: '/notifications',
        builder: (context, state) => const notification_ui.NotificationPage(),
      ),

      GoRoute(
        path: '/saved-posts',
        builder: (context, state) => BlocProvider(
          create: (_) =>
              serviceLocator<PostBloc>()
                ..add(const PostLoadBookmarkedPostsEvent()),
          child: const SavedPostsPage(),
        ),
      ),

      GoRoute(
        path: '/liked-posts',
        builder: (context, state) => BlocProvider(
          create: (_) =>
              serviceLocator<LikedPostsBloc>()
                ..add(const LikedPostsFetchEvent()),
          child: const LikedPostsPage(),
        ),
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

      GoRoute(
        path: "/my-events",
        builder: (context, state) {
          final typeString = state.uri.queryParameters['type'];
          EventType eventType = EventType.upcoming;
          if (typeString != null) {
            for (final type in EventType.values) {
              if (type.name == typeString) {
                eventType = type;
                break;
              }
            }
          }
          return MyEventsPage(eventType: eventType);
        },
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
