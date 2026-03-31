import 'package:cached_network_image/cached_network_image.dart';
import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/feature/message/presentation/pages/image_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatImageMedia extends StatelessWidget {
  final String imageUrl;
  final List<String> imageUrlsForViewer;

  const ChatImageMedia({
    super.key,
    required this.imageUrl,
    required this.imageUrlsForViewer,
  });

  void _openViewer(BuildContext context) {
    final initialIndex = imageUrlsForViewer.indexOf(imageUrl);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewerPage(
          imageUrls: imageUrlsForViewer,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return GestureDetector(
      onTap: () => _openViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          maxHeightDiskCache: 400,
          maxWidthDiskCache: 400,
          placeholder: (context, url) =>
              Container(color: colors.backgroundTertiary),
          errorWidget: (context, url, error) => Container(
            color: colors.backgroundTertiary,
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 32,
                color: colors.iconTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
