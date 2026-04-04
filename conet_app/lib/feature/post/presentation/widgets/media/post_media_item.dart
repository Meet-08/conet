import 'package:cached_network_image/cached_network_image.dart';
import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/media_cache_manager.dart';
import 'package:conet_app/core/utils/media_type_utils.dart';
import 'package:conet_app/feature/post/presentation/pages/post_image_viewer_page.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_audio_media.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_document_media.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_image_media.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_video_media.dart';
import 'package:flutter/material.dart';

class PostMediaItem extends StatelessWidget {
  final String mediaUrl;
  final List<String> imageUrlsForViewer;

  const PostMediaItem({
    super.key,
    required this.mediaUrl,
    required this.imageUrlsForViewer,
  });

  @override
  Widget build(BuildContext context) {
    return switch (getMediaType(mediaUrl)) {
      MediaType.image => PostImageMedia(
        imageUrl: mediaUrl,
        imageUrlsForViewer: imageUrlsForViewer,
      ),
      MediaType.video => PostVideoMedia(videoUrl: mediaUrl),
      MediaType.audio => PostAudioMedia(audioUrl: mediaUrl),
      MediaType.document => PostDocumentMedia(fileUrl: mediaUrl),
      MediaType.unknown => _UnknownPostMedia(
        mediaUrl: mediaUrl,
        imageUrlsForViewer: imageUrlsForViewer,
      ),
    };
  }
}

class _UnknownPostMedia extends StatelessWidget {
  final String mediaUrl;
  final List<String> imageUrlsForViewer;

  const _UnknownPostMedia({
    required this.mediaUrl,
    required this.imageUrlsForViewer,
  });

  String _normalizedUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri != null) return uri.toString();
    return Uri.encodeFull(rawUrl.trim());
  }

  void _openViewer(BuildContext context) {
    final viewerUrls = imageUrlsForViewer.isEmpty
        ? [mediaUrl]
        : imageUrlsForViewer;
    final initialIndex = viewerUrls.indexOf(mediaUrl);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostImageViewerPage(
          imageUrls: viewerUrls,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return GestureDetector(
      onTap: () => _openViewer(context),
      child: CachedNetworkImage(
        imageUrl: _normalizedUrl(mediaUrl),
        cacheManager: MediaCacheManager.instance,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Container(color: semantic.backgroundTertiary),
        errorWidget: (context, url, error) =>
            PostDocumentMedia(fileUrl: mediaUrl),
      ),
    );
  }
}
