import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_media_download_button.dart';
import 'package:flutter/material.dart';

class PostDocumentMedia extends StatelessWidget {
  final String fileUrl;

  const PostDocumentMedia({super.key, required this.fileUrl});

  String _fileLabel() {
    final uri = Uri.tryParse(fileUrl);
    if (uri == null || uri.pathSegments.isEmpty) return 'Attached file';
    return uri.pathSegments.last;
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: semantic.backgroundSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 24,
            color: semantic.iconSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _fileLabel(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(
                color: semantic.textPrimary,
              ),
            ),
          ),
          PostMediaDownloadButton(
            mediaUrl: fileUrl,
            iconColor: semantic.iconPrimary,
            backgroundColor: semantic.surfaceBase,
          ),
        ],
      ),
    );
  }
}
