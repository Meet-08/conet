import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Displays all locally bookmarked posts (Hive-backed).
///
/// This page uses its own [PostBloc] instance (provided by the router via
/// [BlocProvider]) to avoid state collisions with the global feed bloc.
///
/// Architecture:
///   UI → PostBloc (local) → PostLoadBookmarkedPostsEvent
///       → PostGetBookmarks UseCase → PostRepository → PostBookmarkLocalDataSource
class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({super.key});

  @override
  State<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PostBloc>().add(const PostLoadBookmarkedPostsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Posts', style: AppTextStyles.headingH1),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(
          context,
        ).extension<AppSemanticColors>()!.textPrimary,
      ),
      backgroundColor: Theme.of(
        context,
      ).extension<AppSemanticColors>()!.backgroundSecondary,
      body: BlocBuilder<PostBloc, PostState>(
        builder: (context, state) {
          if (state is PostLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostFailure) {
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

          if (state is PostBookmarksLoaded) {
            if (state.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.bookmark,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).extension<AppSemanticColors>()!.iconTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No saved posts yet',
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
                      'Tap the bookmark icon on any post to save it here.',
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
