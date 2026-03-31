import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/post/presentation/bloc/liked_posts_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LikedPostsPage extends StatefulWidget {
  const LikedPostsPage({super.key});

  @override
  State<LikedPostsPage> createState() => _LikedPostsPageState();
}

class _LikedPostsPageState extends State<LikedPostsPage> {
  @override
  void initState() {
    super.initState();
    context.read<LikedPostsBloc>().add(const LikedPostsFetchEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked Posts', style: AppTextStyles.headingH1),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(
          context,
        ).extension<AppSemanticColors>()!.textPrimary,
      ),
      backgroundColor: Theme.of(
        context,
      ).extension<AppSemanticColors>()!.backgroundSecondary,
      body: BlocBuilder<LikedPostsBloc, LikedPostsState>(
        builder: (context, state) {
          if (state is LikedPostsLoading) {
            return const Loader();
          }

          if (state is LikedPostsFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 40,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).extension<AppSemanticColors>()!.textError,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is LikedPostsLoaded) {
            if (state.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.heart,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).extension<AppSemanticColors>()!.iconTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No liked posts yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).extension<AppSemanticColors>()!.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the heart icon on any post to like it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).extension<AppSemanticColors>()!.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: state.posts[index]);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
