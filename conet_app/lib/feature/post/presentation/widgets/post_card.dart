import 'package:conet_app/core/utils/date_formatter.dart';
import 'package:conet_app/core/utils/media_type_utils.dart';
import 'package:conet_app/core/utils/post_share_helper.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_media_item.dart';
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

  static const _avatarColors = [Color(0xFFE0E0E0)];

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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.push('/user-profile', extra: widget.post.user.id);
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: _getAvatarColor(widget.post.user.username),
                    backgroundImage:
                        widget.post.user.profilePicUrl != null &&
                            widget.post.user.profilePicUrl!.isNotEmpty
                        ? NetworkImage(widget.post.user.profilePicUrl!)
                        : null,
                    child:
                        widget.post.user.profilePicUrl == null ||
                            widget.post.user.profilePicUrl!.isEmpty
                        ? Text(
                            _getInitials(widget.post.user.username),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.grey.shade700,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDisplayName(widget.post.user.username),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Text(
                  DateFormatter.format(widget.post.createdAt),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {},
                  child: Icon(
                    FontAwesomeIcons.ellipsisVertical,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content Text
            Text(
              displayedContent,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: Colors.grey.shade900,
                letterSpacing: -0.1,
              ),
            ),

            // Carousel Image with Indicators
            if (widget.post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                    // Dot Indicators (only show if multiple images)
                    if (widget.post.mediaUrls.length > 1)
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
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
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
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

            // Tags Section
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: .horizontal,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: tags.map((tag) => _TagChip(text: tag)).toList(),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              mainAxisAlignment: .spaceBetween,
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
                      color: _isLiked ? Colors.red : Colors.grey.shade700,
                    ),
                  ),
                ),
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
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await PostShareHelper.sharePost(
                      postId: widget.post.id,
                      username: widget.post.user.username,
                      content: widget.post.content,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: FaIcon(
                      FontAwesomeIcons.shareNodes,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // Bookmark button — state derived from PostBloc.bookmarkedPostIds
                BlocBuilder<PostBloc, PostState>(
                  buildWhen: (prev, curr) {
                    // Feed view: only rebuild when this post's bookmark status changes
                    if (prev is PostLoaded && curr is PostLoaded) {
                      return prev.bookmarkedPostIds.contains(widget.post.id) !=
                          curr.bookmarkedPostIds.contains(widget.post.id);
                    }
                    // SavedPostsPage (PostBookmarksLoaded): rebuild on any list change
                    // so the button reacts when a bookmark is removed
                    if (prev is PostBookmarksLoaded ||
                        curr is PostBookmarksLoaded) {
                      return true;
                    }
                    return false;
                  },
                  builder: (context, state) {
                    // All posts shown in SavedPostsPage are bookmarked by definition
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
                          size: 20,
                          color: isBookmarked
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String username) {
    if (username.isEmpty) return '?';
    final parts = username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatDisplayName(String username) {
    if (username.isEmpty) return 'Unknown User';

    // For now, just capitalize first letter of each word
    final words = username.split('_');
    return words
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 18, color: color ?? Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color ?? Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
