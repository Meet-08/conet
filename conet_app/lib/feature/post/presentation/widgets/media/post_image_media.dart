import 'package:cached_network_image/cached_network_image.dart';
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostImageViewerPage(
          imageUrls: imageUrlsForViewer,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openViewer(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
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
          ),
        ],
      ),
    );
  }
}
