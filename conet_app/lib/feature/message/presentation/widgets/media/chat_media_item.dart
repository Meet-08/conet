import 'package:conet_app/core/utils/media_type_utils.dart';
import 'package:conet_app/feature/message/presentation/widgets/media/chat_audio_media.dart';
import 'package:conet_app/feature/message/presentation/widgets/media/chat_document_media.dart';
import 'package:conet_app/feature/message/presentation/widgets/media/chat_image_media.dart';
import 'package:conet_app/feature/message/presentation/widgets/media/chat_video_media.dart';
import 'package:flutter/widgets.dart';

class ChatMediaItem extends StatelessWidget {
  final String mediaUrl;
  final List<String> imageUrlsForViewer;
  final bool isMe;

  const ChatMediaItem({
    super.key,
    required this.mediaUrl,
    required this.imageUrlsForViewer,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return switch (getMediaType(mediaUrl)) {
      MediaType.image => ChatImageMedia(
        imageUrl: mediaUrl,
        imageUrlsForViewer: imageUrlsForViewer,
      ),
      MediaType.video => ChatVideoMedia(videoUrl: mediaUrl),
      MediaType.audio => ChatAudioMedia(audioUrl: mediaUrl),
      MediaType.document ||
      MediaType.unknown => ChatDocumentMedia(fileUrl: mediaUrl),
    };
  }
}
