import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/feature/message/presentation/widgets/media/chat_media_download_button.dart';
import 'package:flutter/material.dart';

class ChatDocumentMedia extends StatelessWidget {
  final String fileUrl;

  const ChatDocumentMedia({super.key, required this.fileUrl});

  String _fileLabel() {
    final uri = Uri.tryParse(fileUrl);
    if (uri == null || uri.pathSegments.isEmpty) return 'Attached file';
    return uri.pathSegments.last;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 24,
            color: colors.iconPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _fileLabel(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: colors.textPrimary),
            ),
          ),
          ChatMediaDownloadButton(
            mediaUrl: fileUrl,
            iconColor: colors.textPrimary,
            backgroundColor: colors.backgroundPrimary,
          ),
        ],
      ),
    );
  }
}
