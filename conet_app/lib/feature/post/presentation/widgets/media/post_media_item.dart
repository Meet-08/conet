import 'package:conet_app/core/utils/media_type_utils.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_audio_media.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_document_media.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_image_media.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_video_media.dart';
import 'package:flutter/widgets.dart';

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
      MediaType.document ||
      MediaType.unknown => PostDocumentMedia(fileUrl: mediaUrl),
    };
  }
}
