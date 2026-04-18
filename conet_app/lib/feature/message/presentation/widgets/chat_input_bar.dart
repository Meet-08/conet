import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onFilesSelected;
  final int selectedFilesCount;
  final bool isGroupChat;
  final bool isAdmin;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onFilesSelected,
    this.selectedFilesCount = 0,
    this.isGroupChat = false,
    this.isAdmin = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    final canSendMessage = !isGroupChat || isAdmin;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canSendMessage)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Only admins can send messages in this group',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textError),
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              children: [
                Stack(
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.paperclip),
                      onPressed: canSendMessage ? onFilesSelected : null,
                    ),
                    if (selectedFilesCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.backgroundError,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '$selectedFilesCount',
                              style: AppTextStyles.caption.copyWith(
                                color: colors.textOnError,
                                fontWeight: AppTypographyTokens.weightBold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: canSendMessage,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: canSendMessage
                          ? 'Type a message...'
                          : 'You can only read messages in this group',
                      filled: true,
                      fillColor: canSendMessage
                          ? colors.backgroundSecondary
                          : colors.backgroundSecondary.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  backgroundColor: canSendMessage
                      ? colors.backgroundInverse
                      : colors.backgroundInverse.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.paperPlane,
                      color: colors.textInverse,
                      size: 20,
                    ),
                    onPressed: canSendMessage ? onSend : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
