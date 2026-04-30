import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onFilesSelected;
  final int selectedFilesCount;
  final bool enabled;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onFilesSelected,
    this.selectedFilesCount = 0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            Stack(
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.paperclip),
                  onPressed: enabled ? onFilesSelected : null,
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
                enabled: enabled,
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Type a message...'
                      : 'Only admins can send messages',
                  filled: true,
                  fillColor: colors.backgroundSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              backgroundColor: colors.backgroundInverse,
              child: IconButton(
                icon: FaIcon(
                  FontAwesomeIcons.paperPlane,
                  color: colors.textInverse,
                  size: 20,
                ),
                onPressed: enabled ? onSend : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
