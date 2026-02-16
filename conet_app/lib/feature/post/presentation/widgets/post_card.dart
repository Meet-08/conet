import 'package:cached_network_image/cached_network_image.dart';
import 'package:conet_app/core/utils/date_formatter.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
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

  @override
  Widget build(BuildContext context) {
    final tags = _extractTags(widget.post.content);
    final displayedContent = _removeTags(widget.post.content);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.isDetailView
              ? null
              : () {
                  context.push('/post-detail', extra: widget.post);
                },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade300,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDisplayName(widget.post.user.username),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormatter.format(widget.post.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.ellipsis,
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

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

              const SizedBox(height: 14),

              // Carousel Image with Indicators
              if (widget.post.mediaUrls.isNotEmpty) ...[
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      // Corrected from ClipRRRect
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemCount: widget.post.mediaUrls.length,
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: widget.post.mediaUrls[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey.shade200),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.triangleExclamation,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
              ],

              // Tags Section
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: tags.map((tag) => _TagChip(text: tag)).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Action Buttons
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
                        color: _isLiked ? Colors.red : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: widget.isDetailView
                        ? null
                        : () {
                            context.push('/post-detail', extra: widget.post);
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: _ActionItem(
                        icon: FontAwesomeIcons.comment,
                        label: '${widget.post.commentCount}',
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FaIcon(
                        FontAwesomeIcons.paperPlane,
                        size: 20,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FaIcon(
                        FontAwesomeIcons.bookmark,
                        size: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 20, color: color ?? Colors.grey.shade800),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
