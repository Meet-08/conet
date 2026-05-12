import 'package:conet_app/feature/post/domain/entities/post.dart';

enum SharedContentType { media, post, docs }

/// Represents a single item in the shared content view
/// Can be an image/video, a post, or a document
class SharedMediaItem {
  final String id;
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final String? contentUrl;
  final SharedContentType type;
  final DateTime? createdAt;
  final String? senderName;

  /// For post type items
  final Post? post;

  /// For media items - the list of all media URLs from that message
  final List<String> mediaUrls;

  const SharedMediaItem({
    required this.id,
    this.title,
    this.description,
    this.thumbnailUrl,
    this.contentUrl,
    required this.type,
    this.createdAt,
    this.senderName,
    this.post,
    this.mediaUrls = const [],
  });

  /// Check if this is a video based on URL
  bool get isVideo {
    if (contentUrl == null && mediaUrls.isEmpty) return false;
    final url = contentUrl ?? mediaUrls.first;
    return url.contains('.mp4') ||
        url.contains('.mov') ||
        url.contains('.avi') ||
        url.contains('.webm') ||
        url.contains('video');
  }

  /// Check if this is an image
  bool get isImage {
    if (contentUrl == null && mediaUrls.isEmpty) return false;
    final url = contentUrl ?? mediaUrls.first;
    return url.contains('.jpg') ||
        url.contains('.jpeg') ||
        url.contains('.png') ||
        url.contains('.gif') ||
        url.contains('.webp') ||
        url.contains('image');
  }
}
