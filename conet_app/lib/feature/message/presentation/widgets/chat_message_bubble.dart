import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/presentation/widgets/media/chat_media_item.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final List<String> mediaUrls;
  final MessageDeliveryStatus status;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    this.mediaUrls = const [],
    this.status = MessageDeliveryStatus.sent,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    final hasMedia = mediaUrls.isNotEmpty;
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    final bubbleColor = status == MessageDeliveryStatus.error
        ? colors.backgroundError
        : (isMe ? colors.backgroundInverse : colors.backgroundTertiary);

    final textColor = status == MessageDeliveryStatus.error
        ? colors.textError
        : (isMe ? colors.textInverse : colors.textPrimary);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: status == MessageDeliveryStatus.pending ? 0.5 : 1.0,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(16),
                  border: status == MessageDeliveryStatus.error
                      ? Border.all(color: colors.borderError)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display text if present
                    if (hasText)
                      Text(
                        text,
                        style: AppTextStyles.bodyDefault.copyWith(
                          color: textColor,
                        ),
                      ),

                    // Add spacing between text and media
                    if (hasText && hasMedia) const SizedBox(height: 8),

                    // Display media if present
                    if (hasMedia) _buildMediaGrid(context),

                    if (status == MessageDeliveryStatus.error) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: colors.iconError,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Failed to send",
                            style: AppTextStyles.caption.copyWith(
                              color: colors.textError,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                if (status == MessageDeliveryStatus.pending) ...[
                  const SizedBox(width: 4),
                  const Loader(size: 8, strokeWidth: 1),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context) {
    if (mediaUrls.length == 1) {
      return SizedBox(
        height: 200,
        width: 200,
        child: ChatMediaItem(
          mediaUrl: mediaUrls[0],
          imageUrlsForViewer: mediaUrls,
          isMe: isMe,
        ),
      );
    }

    // For multiple media items, show in a grid
    // For images only (backward compatibility), show in 2-3 per row
    // For mixed media, show 1 per row
    final maxWidth =
        MediaQuery.of(context).size.width * 0.75 - 24; // Account for padding
    final itemSize = mediaUrls.length == 2
        ? (maxWidth - 4) /
              2 // 2 items side by side
        : (maxWidth - 8) / 3; // 3 items per row

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(
        mediaUrls.length,
        (index) => SizedBox(
          width: itemSize,
          height: itemSize,
          child: ChatMediaItem(
            mediaUrl: mediaUrls[index],
            imageUrlsForViewer: mediaUrls,
            isMe: isMe,
          ),
        ),
      ),
    );
  }
}
