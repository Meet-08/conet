import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/date_formatter.dart';
import 'package:conet_app/core/utils/media_type_utils.dart';
import 'package:conet_app/core/utils/quill_content_utils.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/core/widgets/quill_read_only_view.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_media_item.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_share_sheet.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:conet_app/feature/report/domain/entities/report_target_type.dart';
import 'package:conet_app/feature/report/presentation/widgets/report_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isDetailView;

  const PostCard({super.key, required this.post, this.isDetailView = false});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _currentImageIndex = 0;

  final PageController _pageController = PageController();

  late bool _isLiked;
  late int _likeCount;
  late bool _isFollowingAuthor;

  bool _isExpanded = false;

  static const _avatarColors = [
    Color(0xFFF7E6E6),
    Color(0xFFE8EEF9),
    Color(0xFFE6F4EA),
    Color(0xFFF9EFD9),
    Color(0xFFEFE8FB),
  ];

  @override
  void initState() {
    super.initState();

    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
    _isFollowingAuthor = widget.post.user.isFollowing;

    context.read<PostBloc>().add(
      PostCheckBookmarkStatusEvent(postId: widget.post.id),
    );
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.post != widget.post) {
      _isLiked = widget.post.isLiked;
      _likeCount = widget.post.likeCount;
      _isFollowingAuthor = widget.post.user.isFollowing;
      _isExpanded = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _getAvatarColor(String username) {
    if (username.isEmpty) return _avatarColors[0];

    final hash = username.codeUnits.fold<int>(0, (prev, c) => prev + c);

    return _avatarColors[hash % _avatarColors.length];
  }

  void _toggleFollowAuthor() {
    final nextValue = !_isFollowingAuthor;

    setState(() {
      _isFollowingAuthor = nextValue;
    });

    final profileBloc = context.read<ProfileBloc>();

    if (nextValue) {
      profileBloc.add(ProfileFollowUserEvent(targetUid: widget.post.user.id));
    } else {
      profileBloc.add(ProfileUnfollowUserEvent(targetUid: widget.post.user.id));
    }
  }

  Future<void> _openPostShareSheet(String contentPreview) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PostShareSheet(
        parentContext: context,
        postId: widget.post.id,
        username: widget.post.user.username,
        contentPreview: contentPreview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    final user = widget.post.user;

    final displayName = _buildDisplayName();
    final handle = _buildHandle();

    final renderedContent = quillPlainTextFromString(
      widget.post.content,
    ).trim();

    final tags = quillTagsFromString(widget.post.content);

    final hasMedia = widget.post.mediaUrls.isNotEmpty;

    final imageUrlsForViewer = widget.post.mediaUrls
        .where((url) => getMediaType(url) == MediaType.image)
        .toList();

    final currentMediaUrl = widget.post.mediaUrls.isNotEmpty
        ? widget.post.mediaUrls[_currentImageIndex.clamp(
            0,
            widget.post.mediaUrls.length - 1,
          )]
        : '';

    final currentMediaType = currentMediaUrl.isEmpty
        ? MediaType.unknown
        : getMediaType(currentMediaUrl);

    final mediaAspectRatio = switch (currentMediaType) {
      MediaType.image || MediaType.video => 4 / 3,
      MediaType.audio => 16 / 7,
      MediaType.document => 16 / 4,
      MediaType.unknown => 4 / 3,
    };

    return InkWell(
      onTap: widget.isDetailView
          ? null
          : () {
              context.push(
                '/post-detail/${widget.post.id}',
                extra: widget.post,
              );
            },
      borderRadius: BorderRadius.zero,
      child: Container(
        color: semantic.surfaceBase,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomCircleAvatar(
                  size: CustomCircleAvatarSize.medium,
                  imageUrl: user.profilePicUrl,
                  displayName: displayName,
                  userId: user.id,
                  backgroundColor: _getAvatarColor(user.username),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: semantic.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          '$handle · ${DateFormatter.format(widget.post.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12.5,
                            color: semantic.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FollowButton(
                      isFollowing: _isFollowingAuthor,
                      onTap: _toggleFollowAuthor,
                    ),

                    PopupMenuButton<_PostActionMenuItem>(
                      position: PopupMenuPosition.under,
                      padding: EdgeInsets.zero,
                      color: semantic.surfaceBase,
                      offset: const Offset(0, 10),
                      onSelected: (value) {
                        switch (value) {
                          case _PostActionMenuItem.follow:
                          case _PostActionMenuItem.unfollow:
                            _toggleFollowAuthor();
                            break;

                          case _PostActionMenuItem.report:
                            showReportBottomSheet(
                              context: context,
                              targetId: widget.post.id,
                              targetType: ReportTargetType.post,
                              targetLabel: 'Post',
                              targetSubtitle: '$displayName · $handle',
                            );
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<_PostActionMenuItem>(
                          value: _isFollowingAuthor
                              ? _PostActionMenuItem.unfollow
                              : _PostActionMenuItem.follow,
                          child: Row(
                            children: [
                              FaIcon(
                                _isFollowingAuthor
                                    ? FontAwesomeIcons.userMinus
                                    : FontAwesomeIcons.userPlus,
                                size: 15,
                                color: semantic.iconSecondary,
                              ),

                              const SizedBox(width: 10),

                              Text(
                                _isFollowingAuthor ? 'Unfollow' : 'Follow',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: semantic.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        PopupMenuItem<_PostActionMenuItem>(
                          value: _PostActionMenuItem.report,
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.flag,
                                size: 15,
                                color: semantic.textError,
                              ),

                              const SizedBox(width: 10),

                              Text(
                                'Report',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: semantic.textError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                        child: Icon(
                          FontAwesomeIcons.ellipsisVertical,
                          color: semantic.iconSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (renderedContent.isNotEmpty) ...[
              const SizedBox(height: 11),

              if (widget.isDetailView || !hasMedia)
                QuillReadOnlyView(deltaJson: widget.post.content)
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textStyle = textTheme.bodyMedium?.copyWith(
                      color: semantic.textPrimary,
                      height: 1.45,
                    );

                    final textPainter = TextPainter(
                      text: TextSpan(text: renderedContent, style: textStyle),
                      maxLines: 2,
                      textDirection: TextDirection.ltr,
                    )..layout(maxWidth: constraints.maxWidth);

                    final exceedsMaxLines = textPainter.didExceedMaxLines;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: ClipRect(
                            child: SizedBox(
                              width: double.infinity,
                              height: _isExpanded
                                  ? null
                                  : (textStyle?.fontSize ?? 14) *
                                            (textStyle?.height ?? 1.4) *
                                            2 +
                                        6,
                              child: IgnorePointer(
                                ignoring: true,
                                child: QuillReadOnlyView(
                                  deltaJson: widget.post.content,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (exceedsMaxLines)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                              child: Text(
                                _isExpanded ? 'Show less' : 'Read more',
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],

            if (widget.post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    AspectRatio(
                      aspectRatio: mediaAspectRatio,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: widget.post.mediaUrls.length,
                        itemBuilder: (context, index) {
                          return PostMediaItem(
                            mediaUrl: widget.post.mediaUrls[index],
                            imageUrlsForViewer: imageUrlsForViewer,
                          );
                        },
                      ),
                    ),

                    if (widget.post.mediaUrls.length > 1)
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: semantic.backgroundBackdrop,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.post.mediaUrls.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: _currentImageIndex == index ? 8 : 6,
                                height: _currentImageIndex == index ? 8 : 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? semantic.iconInverse
                                      : semantic.iconInverse.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 8,
                  children: tags.map((tag) => _TagChip(text: tag)).toList(),
                ),
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isLiked = !_isLiked;
                      _likeCount += _isLiked ? 1 : -1;
                    });

                    context.read<PostBloc>().add(
                      PostToggleLikePostEvent(postId: widget.post.id),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: _ActionItem(
                      icon: _isLiked
                          ? FontAwesomeIcons.solidHeart
                          : FontAwesomeIcons.heart,
                      label: '$_likeCount',
                      color: _isLiked
                          ? const Color(0xFFE53935)
                          : semantic.iconSecondary,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.isDetailView
                      ? null
                      : () {
                          context.push(
                            '/post-detail/${widget.post.id}',
                            extra: widget.post,
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: _ActionItem(
                      icon: FontAwesomeIcons.comment,
                      label: '${widget.post.commentCount}',
                      color: semantic.iconSecondary,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await _openPostShareSheet(renderedContent);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      CupertinoIcons.arrowshape_turn_up_right,
                      size: 20,
                      color: semantic.iconSecondary,
                    ),
                  ),
                ),

                const Spacer(),

                BlocBuilder<PostBloc, PostState>(
                  buildWhen: (prev, curr) {
                    if (prev is PostLoaded && curr is PostLoaded) {
                      return prev.bookmarkedPostIds.contains(widget.post.id) !=
                          curr.bookmarkedPostIds.contains(widget.post.id);
                    }

                    if (prev is PostBookmarksLoaded ||
                        curr is PostBookmarksLoaded) {
                      return true;
                    }

                    return false;
                  },
                  builder: (context, state) {
                    final isBookmarked = switch (state) {
                      PostLoaded s => s.bookmarkedPostIds.contains(
                        widget.post.id,
                      ),
                      PostBookmarksLoaded _ => true,
                      _ => false,
                    };

                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (isBookmarked) {
                          context.read<PostBloc>().add(
                            PostRemoveBookmarkEvent(postId: widget.post.id),
                          );
                        } else {
                          context.read<PostBloc>().add(
                            PostBookmarkEvent(post: widget.post),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: FaIcon(
                          isBookmarked
                              ? FontAwesomeIcons.solidBookmark
                              : FontAwesomeIcons.bookmark,
                          size: 18,
                          color: isBookmarked
                              ? Theme.of(context).colorScheme.primary
                              : semantic.iconSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            if (!widget.isDetailView) ...[
              const SizedBox(height: 12),

              Divider(height: 1, thickness: 0.7, color: semantic.borderSubtle),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDisplayName(String username) {
    if (username.isEmpty) {
      return 'Unknown User';
    }

    final words = username.split('_');

    return words
        .map((word) {
          if (word.isEmpty) return '';

          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _buildDisplayName() {
    final first = widget.post.user.firstName.trim();
    final last = widget.post.user.lastName.trim();

    final full = '$first $last'.trim();

    if (full.isNotEmpty) {
      return full;
    }

    return _formatDisplayName(widget.post.user.username);
  }

  String _buildHandle() {
    final username = widget.post.user.username.trim();

    if (username.isNotEmpty) {
      return '@$username';
    }

    final fallback = _buildDisplayName()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    return fallback.isEmpty ? '@user' : '@$fallback';
  }
}

class _TagChip extends StatelessWidget {
  final String text;

  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: semantic.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: semantic.borderSubtle),
      ),
      child: Text(
        text,
        style: textTheme.labelSmall?.copyWith(color: semantic.textSecondary),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.fullAll,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isFollowing ? semantic.surfaceBase : semantic.backgroundBrand,
          borderRadius: AppRadius.fullAll,
          border: Border.all(
            color: isFollowing
                ? semantic.borderDefault
                : semantic.backgroundBrand,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isFollowing ? semantic.textPrimary : semantic.textOnBrand,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ActionItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 17, color: color ?? semantic.iconSecondary),

        const SizedBox(width: 6),

        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: color ?? semantic.textSecondary,
          ),
        ),
      ],
    );
  }
}

enum _PostActionMenuItem { follow, unfollow, report }
