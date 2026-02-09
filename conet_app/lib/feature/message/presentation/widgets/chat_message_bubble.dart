import 'package:conet_app/feature/message/presentation/pages/image_viewer_page.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final List<String> mediaUrls;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    this.mediaUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    final hasMedia = mediaUrls.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.black : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display text if present
                  if (hasText)
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),

                  // Add spacing between text and images
                  if (hasText && hasMedia) const SizedBox(height: 8),

                  // Display images if present
                  if (hasMedia) _buildImageGrid(context),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    if (mediaUrls.length == 1) {
      return _buildSingleImage(context, mediaUrls[0], 0);
    }

    // For multiple images, show in a grid
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(
        mediaUrls.length,
        (index) => _buildGridImage(context, mediaUrls[index], index),
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, String url, int index) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image, size: 50),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridImage(BuildContext context, String url, int index) {
    final maxWidth =
        MediaQuery.of(context).size.width * 0.75 - 24; // Account for padding
    final imageSize = mediaUrls.length == 2
        ? (maxWidth - 4) /
              2 // 2 images side by side
        : (maxWidth - 8) / 3; // 3 images per row

    return GestureDetector(
      onTap: () => _openImageViewer(context, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: imageSize,
          height: imageSize,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image, size: 30),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageViewerPage(imageUrls: mediaUrls, initialIndex: initialIndex),
      ),
    );
  }
}
