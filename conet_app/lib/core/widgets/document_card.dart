import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/file_download_open_button.dart';
import 'package:flutter/material.dart';

class DocumentCard extends StatelessWidget {
  final String? downloadUrl;
  final String? filename;
  final Future<int?>? fileSizeFuture;

  const DocumentCard({
    super.key,
    this.downloadUrl,
    this.filename,
    this.fileSizeFuture,
  });

  String _extractFilename(String? url) {
    if (filename != null && filename!.isNotEmpty) {
      return filename!;
    }
    if (url == null || url.isEmpty) return 'Document';
    try {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final lastSegment = uri.pathSegments.last;
        if (lastSegment.isNotEmpty) return lastSegment;
      }
    } catch (_) {}
    return 'Document';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    final displayFilename = _extractFilename(downloadUrl);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: colors.iconPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayFilename,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileSizeFuture != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FutureBuilder<int?>(
                      future: fileSizeFuture,
                      builder: (context, snapshot) {
                        final sizeText =
                            snapshot.connectionState == ConnectionState.waiting
                            ? 'Checking size...'
                            : _formatFileSize(snapshot.data);

                        return Text(
                          sizeText,
                          style: AppTextStyles.micro.copyWith(
                            color: colors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (downloadUrl != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FileDownloadOpenButton(
                downloadUrl: downloadUrl!,
                fileName: displayFilename,
                allowRedownload: false,
                usePublicDownloads: true,
              ),
            ),
        ],
      ),
    );
  }

  static String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Size unavailable';
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (bytes >= gb) {
      return '${(bytes / gb).toStringAsFixed(2)} GB';
    }
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    }
    if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(2)} KB';
    }
    return '$bytes B';
  }
}
