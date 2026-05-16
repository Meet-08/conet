import 'dart:async';

import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/core/widgets/main_scaffold.dart';
import 'package:conet_app/core/widgets/splash_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/add_details_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/email_signup_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/login_page.dart';
import 'package:conet_app/feature/auth/presentation/pages/welcome_page.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:conet_app/feature/event/presentation/constants/event_constants.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_analytics_bloc.dart';
import 'package:conet_app/feature/event/presentation/pages/create_event_page.dart';
import 'package:conet_app/feature/event/presentation/pages/event_attendance_scanner_page.dart';
import 'package:conet_app/feature/event/presentation/pages/event_attendees_page.dart';
import 'package:conet_app/feature/event/presentation/pages/event_analytics_page.dart';
import 'package:conet_app/feature/event/presentation/pages/event_dashboard_page.dart';
import 'package:conet_app/feature/event/presentation/pages/event_detail_page.dart';
import 'package:conet_app/feature/event/presentation/pages/event_page.dart';
import 'package:conet_app/feature/event/presentation/pages/event_search_page.dart';
import 'package:conet_app/feature/event/presentation/pages/my_events_page.dart';
import 'package:conet_app/feature/event/presentation/pages/team_registration_detail_page.dart';
import 'package:conet_app/feature/event/presentation/pages/view_ticket.dart';
import 'package:conet_app/feature/message/data/models/conversation_model.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/presentation/pages/chat_detail_page.dart';
import 'package:conet_app/feature/message/presentation/pages/chat_participant_details_page.dart';
import 'package:conet_app/feature/message/presentation/pages/group_details_page.dart';
import 'package:conet_app/feature/message/presentation/pages/messages_page.dart';
import 'package:conet_app/feature/notification/presentation/pages/notification_page.dart'
    as notification_ui;
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/presentation/bloc/liked_posts_bloc.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/pages/create_post_page.dart';
import 'package:conet_app/feature/post/presentation/pages/feed_page.dart';
import 'package:conet_app/feature/post/presentation/pages/post_detail_page.dart';
import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_about_me_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_academic_info_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_interests_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_personal_info_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_profile_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_profile_pictures_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/edit_social_links_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/followers_following_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/profile_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/saved/liked_post.dart';
import 'package:conet_app/feature/profile/presentation/pages/saved/saved_post.dart';
import 'package:conet_app/feature/profile/presentation/pages/settings_page.dart';
import 'package:conet_app/feature/profile/presentation/pages/user_profile_page.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Route observer used by pages that need to know when they become visible again
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

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
        builder: (context, state) {
          final launchData = state.extra is CreateEventLaunchData
              ? state.extra as CreateEventLaunchData
              : null;
          return CreateEventPage(launchData: launchData);
        },
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
        path: '/event-search',
        builder: (_, _) => const EventSearchPage(),
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
          final extra = state.extra;
          final Conversation? conversation = switch (extra) {
            Conversation c => c,
            Map<String, dynamic> m => ConversationModel.fromJson(m),
            _ => null,
          };

          if (conversation == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid conversation payload')),
            );
          }

          return ChatDetailPage(conversation: conversation);
        },
      ),

      GoRoute(
        path: '/group-details',
        builder: (context, state) {
          final extra = state.extra;
          final Conversation? conversation = switch (extra) {
            Conversation c => c,
            Map<String, dynamic> m => ConversationModel.fromJson(m),
            _ => null,
          };

          if (conversation == null || !conversation.isGroup) {
            return const Scaffold(
              body: Center(child: Text('Invalid group payload')),
            );
          }

          return GroupDetailsPage(conversation: conversation);
        },
      ),

      GoRoute(
        path: '/chat-participant-details',
        builder: (context, state) {
          final extra = state.extra;
          final Conversation? conversation = switch (extra) {
            Conversation c => c,
            Map<String, dynamic> m => ConversationModel.fromJson(m),
            _ => null,
          };

          if (conversation == null || conversation.isDirect == false) {
            return const Scaffold(
              body: Center(child: Text('Invalid chat participant payload')),
            );
          }

          return ChatParticipantDetailsPage(conversation: conversation);
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
        path: '/profile-connections',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return const Scaffold(
              body: Center(child: Text('Invalid profile connections payload')),
            );
          }

          final userId = extra['userId']?.toString();
          if (userId == null || userId.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Invalid profile connections payload')),
            );
          }

          final tabValue =
              extra['tab']?.toString().toLowerCase() ?? 'followers';
          final initialTab = tabValue == 'following'
              ? ProfileConnectionsInitialTab.following
              : ProfileConnectionsInitialTab.followers;

          return FollowersFollowingPage(userId: userId, initialTab: initialTab);
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
              final userProfile = _decodeUserProfileExtra(state.extra);

              if (userProfile == null) {
                return const EditProfilePage();
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

      GoRoute(
        path: "/view-ticket",
        builder: (context, state) {
          final extras = state.extra as Map<String, String>?;
          final eventId = extras?['eventId'];
          final ticketId = extras?['ticketId'];

          if (eventId == null || eventId.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Invalid event id')),
            );
          }

          return ViewTicket(eventId: eventId, ticketId: ticketId);
        },
      ),

      GoRoute(
        path: '/event-dashboard',
        builder: (_, _) => const EventDashboardPage(),
      ),

      GoRoute(
        path: '/event-analytics/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']?.trim();
          if (eventId == null || eventId.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Invalid event id')),
            );
          }
          return BlocProvider(
            create: (_) => serviceLocator<EventAnalyticsBloc>(),
            child: EventAnalyticsPage(eventId: eventId),
          );
        },
      ),

      GoRoute(
        path: '/event-attendance-scan',
        builder: (context, state) {
          final extras = state.extra as Map<String, String>?;
          final eventId = extras?['eventId'];
          final eventTitle = extras?['eventTitle'];

          if (eventId == null || eventId.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Invalid event id')),
            );
          }

          return EventAttendanceScannerPage(
            eventId: eventId,
            eventTitle: eventTitle,
          );
        },
      ),

      GoRoute(
        path: '/event-attendees/:eventId',
        builder: (context, state) {
          final rawExtra = state.extra;
          final extras = rawExtra is Map ? rawExtra : null;
          final eventId = state.pathParameters['eventId']?.trim();
          final eventTitle =
              state.uri.queryParameters['title']?.trim() ??
              extras?['eventTitle']?.toString();
          final rawEvent = extras?['event'];
          final event = rawEvent is Event ? rawEvent : null;

          if (eventId == null || eventId.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Invalid event id')),
            );
          }

          return EventAttendeesPage(
            eventId: eventId,
            eventTitle: eventTitle,
            event: event,
          );
        },
      ),

      GoRoute(
        path: '/team-registration-detail/:registrationId',
        builder: (context, state) {
          final rawExtra = state.extra;
          final extras = rawExtra is Map ? rawExtra : null;

          final attendee = extras?['attendee'];
          final rawEvent = extras?['event'];
          final event = rawEvent is Event ? rawEvent : null;

          if (attendee is EventAttendee) {
            return TeamRegistrationDetailPage(attendee: attendee, event: event);
          }

          final eventId = state.uri.queryParameters['eventId']?.trim();
          final eventTitle = state.uri.queryParameters['title']?.trim();

          if (eventId != null && eventId.isNotEmpty) {
            return EventAttendeesPage(
              eventId: eventId,
              eventTitle: eventTitle,
              event: event,
            );
          }

          return const Scaffold(
            body: Center(child: Text('Invalid attendee data')),
          );
        },
      ),

      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const FeedPage()),
          GoRoute(path: '/event', builder: (_, _) => const EventPage()),
          GoRoute(path: '/messages', builder: (_, _) => const MessagesPage()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
        ],
      ),
    ],
  );
}

UserProfile? _decodeUserProfileExtra(Object? extra) {
  if (extra is UserProfile) return extra;
  if (extra is! Map<String, dynamic>) return null;

  final id = extra['id'];
  final email = extra['email'];
  if (id is! String || id.isEmpty || email is! String || email.isEmpty) {
    return null;
  }

  DateTime? parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  int? parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  final rawAcademics = extra['academics'];
  final academics = <UserAcademics>[];
  if (rawAcademics is List) {
    for (final item in rawAcademics) {
      if (item is! Map<String, dynamic>) continue;
      final academicId = item['id']?.toString() ?? '';
      final userId = item['userId']?.toString() ?? item['user_id']?.toString();
      final collegeName =
          item['collegeName']?.toString() ?? item['college_name']?.toString();
      final course = item['course']?.toString();
      final createdAt = parseDate(item['createdAt'] ?? item['created_at']);

      if (academicId.isEmpty ||
          userId == null ||
          userId.isEmpty ||
          collegeName == null ||
          collegeName.isEmpty ||
          course == null ||
          course.isEmpty ||
          createdAt == null) {
        continue;
      }

      academics.add(
        UserAcademics(
          id: academicId,
          userId: userId,
          collegeName: collegeName,
          degree: item['degree']?.toString(),
          course: course,
          major: item['major']?.toString(),
          startYear: parseInt(item['startYear'] ?? item['start_year']),
          endYear: parseInt(item['endYear'] ?? item['end_year']),
          createdAt: createdAt,
        ),
      );
    }
  }

  final rawSocialLinks = extra['socialLinks'];
  final socialLinks = <SocialLinks>[];
  if (rawSocialLinks is List) {
    for (final item in rawSocialLinks) {
      if (item is! Map<String, dynamic>) continue;
      final name = item['name']?.toString();
      final link = item['link']?.toString();
      if (name == null || name.isEmpty || link == null || link.isEmpty) {
        continue;
      }
      socialLinks.add(SocialLinks(name: name, link: link));
    }
  }

  final rawInterests = extra['interests'];
  final interests = rawInterests is List
      ? rawInterests.map((item) => item.toString()).toList(growable: false)
      : const <String>[];

  return UserProfile(
    id: id,
    email: email,
    firstName:
        extra['firstName']?.toString() ?? extra['first_name']?.toString(),
    lastName: extra['lastName']?.toString() ?? extra['last_name']?.toString(),
    username: extra['username']?.toString(),
    aboutMe: extra['aboutMe']?.toString() ?? extra['about_me']?.toString(),
    profilePicUrl:
        extra['profilePicUrl']?.toString() ??
        extra['profile_pic_url']?.toString(),
    bannerImageUrl:
        extra['bannerImageUrl']?.toString() ??
        extra['banner_image_url']?.toString(),
    interests: interests,
    isVerified: extra['isVerified'] == true || extra['is_verified'] == true,
    socialLinks: socialLinks,
    academics: academics,
    dateOfBirth: parseDate(extra['dateOfBirth'] ?? extra['date_of_birth']),
    followerCount:
        parseInt(extra['followerCount'] ?? extra['follower_count']) ?? 0,
    followingCount:
        parseInt(extra['followingCount'] ?? extra['following_count']) ?? 0,
    isFollowing: extra['isFollowing'] == true || extra['is_following'] == true,
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
