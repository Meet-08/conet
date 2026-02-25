import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/core/widgets/responsive_center_scrollable.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_detail_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_card.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostDetailPage extends StatelessWidget {
  final Post? post;
  final String? postId;

  const PostDetailPage({super.key, this.post, this.postId})
    : assert(
        post != null || postId != null,
        'Either post or postId must be provided',
      );

  @override
  Widget build(BuildContext context) {
    final resolvedId = post?.id ?? postId!;

    return BlocProvider(
      create: (context) {
        final bloc = serviceLocator<PostDetailBloc>();
        if (post == null) {
          bloc.add(PostDetailFetchPostEvent(postId: resolvedId));
        }
        return bloc;
      },
      child: post != null
          ? _PostDetailPageContent(post: post!)
          : const _PostDetailPageFetchWrapper(),
    );
  }
}

class _PostDetailPageFetchWrapper extends StatelessWidget {
  const _PostDetailPageFetchWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostDetailBloc, PostDetailState>(
      buildWhen: (previous, current) =>
          current is PostDetailPostLoaded ||
          current is PostDetailPostFailure ||
          current is PostDetailLoading,
      builder: (context, state) {
        if (state is PostDetailPostLoaded) {
          return _PostDetailPageContent(post: state.post);
        }

        if (state is PostDetailPostFailure) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.arrowLeft,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.circleExclamation,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: Loader()),
        );
      },
    );
  }
}

class _PostDetailPageContent extends StatefulWidget {
  final Post post;

  const _PostDetailPageContent({required this.post});

  @override
  State<_PostDetailPageContent> createState() => _PostDetailPageContentState();
}

class _PostDetailPageContentState extends State<_PostDetailPageContent> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  late Post _displayPost;

  @override
  void initState() {
    super.initState();
    _displayPost = widget.post;
    context.read<PostDetailBloc>().add(
      PostDetailWatchCommentsEvent(postId: widget.post.id),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final userState = context.read<AppUserCubit>().state;
    if (userState is! AppUserAuthenticated) return;

    final user = userState.user;

    final optimisticComment = Comment(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: commentText,
      userId: user.id,
      postId: widget.post.id,
      username: user.username,
      profilePicUrl: user.profilePicUrl,
    );

    context.read<PostDetailBloc>().add(
      PostDetailAddCommentEvent(
        postId: widget.post.id,
        comment: commentText,
        optimisticComment: optimisticComment,
      ),
    );

    _commentController.clear();
    // Keep focus or unfocus? User usually expects to stay focused for rapid commenting,
    // or unfocus if submitting via button. Let's keep it as is (just clear).
    // Actually typically on mobile you might want to dismiss keyboard, but let's stick to simple clear.
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PostDetailBloc, PostDetailState>(
      listener: (context, state) {
        if (state is PostDetailLoaded) {
          final nextCount = state.comments.length;
          if (_displayPost.commentCount != nextCount) {
            setState(() {
              _displayPost = _displayPost.copyWith(commentCount: nextCount);
            });

            context.read<PostBloc>().add(
              PostSyncCommentCountEvent(
                postId: widget.post.id,
                commentCount: nextCount,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Post',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
        body: ResponsiveCenterScrollable(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Card
                      PostCard(post: _displayPost, isDetailView: true),

                      const Divider(height: 1, thickness: 1),

                      // Comments Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),

                      // Comments List
                      BlocBuilder<PostDetailBloc, PostDetailState>(
                        builder: (context, state) {
                          if (state is PostDetailLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Loader()),
                            );
                          }

                          if (state is PostDetailLoaded) {
                            if (state.comments.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.commentDots,
                                        size: 48,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No comments yet',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Be the first to comment!',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: state.comments.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final comment = state.comments[index];
                                return _CommentItem(comment: comment);
                              },
                            );
                          }

                          if (state is PostDetailFailure) {
                            return Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Column(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.circleExclamation,
                                      size: 48,
                                      color: Colors.red.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Failed to load comments',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        context.read<PostDetailBloc>().add(
                                          PostDetailWatchCommentsEvent(
                                            postId: widget.post.id,
                                          ),
                                        );
                                      },
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 80), // Space for comment input
                    ],
                  ),
                ),
              ),

              // Comment Input (Fixed at bottom)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              maxLines: null,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.paperPlane,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _submitComment,
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade300,
          backgroundImage:
              comment.profilePicUrl != null && comment.profilePicUrl!.isNotEmpty
              ? NetworkImage(comment.profilePicUrl!)
              : null,
          child: comment.profilePicUrl == null || comment.profilePicUrl!.isEmpty
              ? Text(
                  comment.username.isNotEmpty
                      ? comment.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),

        // Comment Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username
              Text(
                comment.username,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),

              // Comment Text
              Text(
                comment.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
