import 'package:cached_network_image/cached_network_image.dart';
import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/media_cache_manager.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class PostImageViewerPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const PostImageViewerPage({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<PostImageViewerPage> createState() => _PostImageViewerPageState();
}

class _PostImageViewerPageState extends State<PostImageViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  String _normalizedUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri != null) return uri.toString();
    return Uri.encodeFull(rawUrl.trim());
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: semantic.backgroundInverse,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: _normalizedUrl(widget.imageUrls[index]),
                    cacheManager: MediaCacheManager.instance,
                    fit: BoxFit.contain,
                    progressIndicatorBuilder: (context, _, downloadProgress) {
                      return Center(
                        child: Loader(
                          color: semantic.iconInverse,
                          value: downloadProgress.totalSize != null
                              ? downloadProgress.downloaded /
                                    downloadProgress.totalSize!
                              : null,
                        ),
                      );
                    },
                    errorWidget: (context, _, error) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.image,
                              size: 72,
                              color: semantic.iconInverse.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load image',
                              style: textTheme.bodyMedium?.copyWith(
                                color: semantic.textInverse.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: FaIcon(
                      FontAwesomeIcons.xmark,
                      color: semantic.iconInverse,
                    ),
                  ),
                  if (widget.imageUrls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: semantic.backgroundBackdrop,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} of ${widget.imageUrls.length}',
                        style: textTheme.bodySmall?.copyWith(
                          color: semantic.textInverse,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
