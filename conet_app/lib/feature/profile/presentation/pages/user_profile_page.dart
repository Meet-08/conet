import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_card.dart';
import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:conet_app/feature/profile/presentation/pages/profile_page.dart';
import 'package:conet_app/feature/profile/presentation/widgets/interests_section.dart';
import 'package:conet_app/feature/profile/presentation/widgets/social_links_section.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool get _isCurrentUser {
    final s = context.read<AppUserCubit>().state;
    return s is AppUserAuthenticated && s.user.id == widget.userId;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCurrentUser) return const ProfilePage();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              serviceLocator<ProfileBloc>()
                ..add(ProfileGetEvent(uid: widget.userId)),
        ),
        BlocProvider(
          create: (_) =>
              serviceLocator<PostBloc>()
                ..add(PostGetUserPostsEvent(userId: widget.userId)),
        ),
      ],
      child: _OtherUserProfileView(userId: widget.userId),
    );
  }
}

class _OtherUserProfileView extends StatelessWidget {
  final String userId;

  const _OtherUserProfileView({required this.userId});

  String _initials(String? first, String? last) =>
      '${first?.isNotEmpty == true ? first![0].toUpperCase() : ''}'
      '${last?.isNotEmpty == true ? last![0].toUpperCase() : ''}';

  String _fullName(String? first, String? last) =>
      '${first ?? ''} ${last ?? ''}'.trim();

  List<UserAcademics> _uniqueAcademics(List<UserAcademics> list) {
    final seen = <String>{};
    return list
        .where((a) => seen.add('${a.collegeName}|${a.course}|${a.major}'))
        .toList();
  }

  String _courseText(UserAcademics a) {
    final buffer = StringBuffer(a.course);
    if (a.startYear != null || a.endYear != null) {
      buffer.write(' • ');
      if (a.startYear != null) buffer.write('${a.startYear}');
      if (a.startYear != null && a.endYear != null) buffer.write('-');
      if (a.endYear != null) buffer.write('${a.endYear}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileUpdateFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.error, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileBloc>().add(
                      ProfileGetEvent(uid: userId),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            final profile = state.userProfile;
            final initials = _initials(profile.firstName, profile.lastName);
            final fullName = _fullName(profile.firstName, profile.lastName);
            final academics = _uniqueAcademics(profile.academics);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Banner + back button + avatar ─────────────
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Banner
                          Container(
                            margin: .only(top: topPad),
                            height: 190,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: profile.bannerImageUrl == null
                                  ? LinearGradient(
                                      colors: [
                                        Colors.blueGrey.shade700,
                                        Colors.blueGrey.shade400,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: profile.bannerImageUrl != null
                                  ? Colors.grey.shade300
                                  : null,
                              image: profile.bannerImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        profile.bannerImageUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            // Gradient scrim at the bottom for depth
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.25),
                                  ],
                                  stops: const [0.55, 1.0],
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            top: topPad + 8,
                            left: 8,
                            child: GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.arrowLeft,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Avatar overhangs the banner bottom
                          Positioned(
                            bottom: -40,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: profile.profilePicUrl?.isNotEmpty == true
                                  ? CircleAvatar(
                                      radius: 42,
                                      backgroundImage: NetworkImage(
                                        profile.profilePicUrl!,
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 42,
                                      backgroundColor: Colors.grey.shade400,
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      // ── Action buttons (right-aligned, beside avatar) ─
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          right: 16,
                          bottom: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(10),
                                side: BorderSide(color: Colors.grey.shade400),
                                foregroundColor: Colors.black87,
                                minimumSize: Size.zero,
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.comment,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Follow'),
                            ),
                          ],
                        ),
                      ),

                      // Space to clear avatar overhang (40px below banner)
                      const SizedBox(height: 8),

                      // ── Full name ─────────────────────────────────
                      if (fullName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),

                      // ── Username ──────────────────────────────────
                      if (profile.username?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '@${profile.username}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],

                      // ── Bio ───────────────────────────────────────
                      if (profile.aboutMe?.isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            profile.aboutMe!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ),
                      ],

                      // ── Academic info ─────────────────────────────
                      if (academics.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...academics.map(
                          (a) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 3,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.buildingColumns,
                                      size: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        a.collegeName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.graduationCap,
                                      size: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _courseText(a),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // ── Following / Followers ─────────────────────
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              '${profile.followingCount}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Following',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              '${profile.followerCount}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Followers',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Interests ─────────────────────────────────
                      if (profile.interests.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InterestsSection(interests: profile.interests),
                        ),
                      ],

                      // ── Social links ──────────────────────────────
                      if (profile.socialLinks.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SocialLinksSection(
                            socialLinks: profile.socialLinks,
                          ),
                        ),
                      ],

                      // ── Posts heading ─────────────────────────────
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Posts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          color: Colors.grey.shade500,
                          thickness: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Posts list ───────────────────────────────────────
                BlocBuilder<PostBloc, PostState>(
                  builder: (context, postState) {
                    if (postState is PostLoading) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }
                    if (postState is PostFailure) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              postState.message,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      );
                    }
                    if (postState is PostLoaded) {
                      if (postState.posts.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No posts yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => PostCard(post: postState.posts[i]),
                          childCount: postState.posts.length,
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          }

          return const Center(child: Text('Loading profile...'));
        },
      ),
    );
  }
}
