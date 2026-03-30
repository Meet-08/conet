import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/date_formatter.dart';
import 'package:conet_app/core/utils/media_type_utils.dart';
import 'package:conet_app/core/utils/post_share_helper.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_media_item.dart';
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
    // Refresh the bookmarked-IDs set in the Bloc for this post's card.
    // The Bloc handler is efficient: it only re-emits if the set changed.
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

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    final user = widget.post.user;
    final displayName = _buildDisplayName();
    final handle = _buildHandle();
    final tags = _extractTags(widget.post.content);
    final displayedContent = _removeTags(widget.post.content);
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
      MediaType.document || MediaType.unknown => 16 / 4,
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
                GestureDetector(
                  onTap: () {
                    context.push('/user-profile', extra: user.id);
                  },
                  child: CircleAvatar(
                    radius: 21,
                    backgroundColor: _getAvatarColor(user.username),
                    backgroundImage:
                        user.profilePicUrl != null &&
                            user.profilePicUrl!.isNotEmpty
                        ? NetworkImage(user.profilePicUrl!)
                        : null,
                    child:
                        user.profilePicUrl == null ||
                            user.profilePicUrl!.isEmpty
                        ? Text(
                            _getInitials(),
                            style: textTheme.labelMedium?.copyWith(
                              color: semantic.textPrimary,
                            ),
                          )
                        : null,
                  ),
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
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {},
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

            if (displayedContent.isNotEmpty) ...[
              const SizedBox(height: 11),
              Text(
                displayedContent,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.42,
                  color: semantic.textPrimary,
                  letterSpacing: -0.05,
                ),
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
                scrollDirection: .horizontal,
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
                    await PostShareHelper.sharePost(
                      postId: widget.post.id,
                      username: widget.post.user.username,
                      content: widget.post.content,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      CupertinoIcons.arrowshape_turn_up_right,
                      fontWeight: const FontWeight(500),
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

  String _getInitials() {
    final base = _buildDisplayName();
    if (base.isEmpty) return '?';

    final parts = base.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return base.substring(0, base.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatDisplayName(String username) {
    if (username.isEmpty) return 'Unknown User';

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

  List<String> _extractTags(String content) {
    final regex = RegExp(r'\B#\w\w+');
    final matches = regex.allMatches(content);
    return matches.map((match) => match.group(0)!).toList();
  }

  String _removeTags(String content) {
    return content.replaceAll(RegExp(r'\B#\w\w+'), '').trim();
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
