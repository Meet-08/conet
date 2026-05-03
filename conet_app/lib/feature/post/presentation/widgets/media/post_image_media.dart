import 'package:cached_network_image/cached_network_image.dart';
import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/media_cache_manager.dart';
import 'package:conet_app/feature/post/presentation/pages/post_image_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PostImageMedia extends StatelessWidget {
  final String imageUrl;
  final List<String> imageUrlsForViewer;

  const PostImageMedia({
    super.key,
    required this.imageUrl,
    required this.imageUrlsForViewer,
  });

  void _openViewer(BuildContext context) {
    final initialIndex = imageUrlsForViewer.indexOf(imageUrl);
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => PostImageViewerPage(
          imageUrls: imageUrlsForViewer,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
        ),
      ),
    );
  }

  String _normalizedUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri != null) return uri.toString();
    return Uri.encodeFull(rawUrl.trim());
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final normalizedImageUrl = _normalizedUrl(imageUrl);

    return GestureDetector(
      onTap: () => _openViewer(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: normalizedImageUrl,
            cacheManager: MediaCacheManager.instance,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: semantic.backgroundTertiary),
            errorWidget: (context, url, error) => Container(
              color: semantic.backgroundTertiary,
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  size: 48,
                  color: semantic.iconSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
