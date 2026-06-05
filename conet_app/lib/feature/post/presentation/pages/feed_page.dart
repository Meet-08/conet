import 'dart:async';

import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/core/widgets/responsive_center_scrollable.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_fab.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_app_bar.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _seenPostIds = {};
  final Map<String, Timer> _viewTimers = {};
  Timer? _flushTimer;
  late final PostBloc _postBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _postBloc = context.read<PostBloc>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postBloc.add(const PostGetPostsEvent(page: 1, limit: 20));
    });

    _flushTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _postBloc.add(const PostFlushImpressionsEvent());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _postBloc.add(const PostFlushImpressionsEvent());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final timer in _viewTimers.values) {
      timer.cancel();
    }
    _viewTimers.clear();
    _flushTimer?.cancel();
    _scrollController.dispose();

    // Final flush on page dispose using cached bloc reference
    _postBloc.add(const PostFlushImpressionsEvent());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: semantic.backgroundPrimary,
      appBar: const PostAppBar(),
      floatingActionButton: const CreatePostFab(),
      body: BlocConsumer<PostBloc, PostState>(
        listener: (context, state) {
          if (state is PostFailure) {
            AppToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is PostLoading) {
            return ColoredBox(
              color: semantic.surfaceBase,
              child: const Center(child: Loader()),
            );
          }

          if (state is! PostLoaded) {
            return ColoredBox(
              color: semantic.surfaceBase,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
                  child: Text(
                    'Unable to load feed right now.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: semantic.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }

          final posts = state.posts;

          if (posts.isEmpty) {
            return ColoredBox(
              color: semantic.surfaceBase,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
                  child: Text(
                    'No posts yet. Pull to refresh to check again.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: semantic.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }

          return ColoredBox(
            color: semantic.surfaceBase,
            child: ResponsiveCenterScrollable(
              maxContentWidth: 640,
              child: RefreshIndicator(
                color: semantic.backgroundBrand,
                backgroundColor: semantic.surfaceBase,
                onRefresh: () async {
                  _postBloc.add(const PostGetPostsEvent(page: 1, limit: 20));
                },
                child: ListView.separated(
                  scrollCacheExtent: const .pixels(400),
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return VisibilityDetector(
                      key: Key('post-feed-${post.id}'),
                      onVisibilityChanged: (info) {
                        final visibleFraction = info.visibleFraction;
                        final postId = post.id;

                        // If already marked seen in this session, skip
                        if (_seenPostIds.contains(postId)) return;

                        if (visibleFraction >= 0.5) {
                          if (!_viewTimers.containsKey(postId)) {
                            _viewTimers[postId] = Timer(
                              const Duration(seconds: 1),
                              () {
                                if (mounted && !_seenPostIds.contains(postId)) {
                                  _seenPostIds.add(postId);
                                  _postBloc.add(
                                    PostMarkSeenEvent(postId: postId),
                                  );
                                }
                                _viewTimers.remove(postId);
                              },
                            );
                          }
                        } else {
                          _viewTimers[postId]?.cancel();
                          _viewTimers.remove(postId);
                        }
                      },
                      child: PostCard(post: post),
                    );
                  },
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: semantic.borderDefault,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
