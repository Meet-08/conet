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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _fileLabel(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ChatMediaDownloadButton(
            mediaUrl: fileUrl,
            iconColor: Colors.black87,
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
