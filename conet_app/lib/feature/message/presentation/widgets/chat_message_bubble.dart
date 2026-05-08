import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/presentation/widgets/media/chat_media_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final List<String> mediaUrls;
  final MessageDeliveryStatus status;
  final String? senderId;
  final String? senderName;
  final String? senderImageUrl;
  final bool showSeenStatus;
  final bool isSeen;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.isMe,
    this.mediaUrls = const [],
    this.status = MessageDeliveryStatus.sent,
    this.senderId,
    this.senderName,
    this.senderImageUrl,
    this.showSeenStatus = false,
    this.isSeen = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    final hasMedia = mediaUrls.isNotEmpty;
    final shouldShowSenderIdentity =
        !isMe && (senderName ?? '').trim().isNotEmpty;
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    final bubbleColor = status == MessageDeliveryStatus.error
        ? colors.backgroundError
        : (isMe ? colors.borderBrand : colors.backgroundTertiary);

    final textColor = status == MessageDeliveryStatus.error
        ? colors.textError
        : (isMe ? colors.textOnWarning : colors.textPrimary);

    final messageColumn = Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (shouldShowSenderIdentity)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: Text(
              senderName!,
              style: AppTextStyles.micro.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Opacity(
          opacity: status == MessageDeliveryStatus.pending ? 0.5 : 1.0,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(14),
              border: status == MessageDeliveryStatus.error
                  ? Border.all(color: colors.borderError)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasText)
                  Linkify(
                    text: text,
                    style: AppTextStyles.bodyDefault.copyWith(color: textColor),
                    linkStyle: AppTextStyles.bodyDefault.copyWith(
                      color: colors.textLink,
                      decoration: TextDecoration.none,
                    ),
                    onOpen: (link) async {
                      final uri = Uri.parse(link.url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                if (hasText && hasMedia) const SizedBox(height: 8),
                if (hasMedia) _buildMediaGrid(context),
                if (status == MessageDeliveryStatus.error) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.triangleExclamation,
                        size: 12,
                        color: colors.iconError,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Failed to send',
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
              style: AppTextStyles.micro.copyWith(color: colors.textTertiary),
            ),
            if (status == MessageDeliveryStatus.pending) ...[
              const SizedBox(width: 4),
              const Loader(size: 8, strokeWidth: 1),
            ],
            if (showSeenStatus && status == MessageDeliveryStatus.sent) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.done_all,
                size: 12,
                color: isSeen ? colors.iconInfo : colors.iconTertiary,
              ),
            ],
          ],
        ),
      ],
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: shouldShowSenderIdentity
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomCircleAvatar(
                    size: CustomCircleAvatarSize.small,
                    userId: senderId,
                    imageUrl: senderImageUrl,
                    displayName: senderName,
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: messageColumn),
                ],
              )
            : messageColumn,
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
