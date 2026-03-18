import 'dart:io';

import 'package:conet_app/core/utils/media_type_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreatePostMediaPreviewItem extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback onRemove;

  static const double _defaultSize = 100;
  static const double _visualMediaSize = 128;

  const CreatePostMediaPreviewItem({
    super.key,
    required this.file,
    required this.onRemove,
  });

  double get _previewSize {
    final mediaType = getMediaTypeFromFileName(file.name);
    if (mediaType == MediaType.image || mediaType == MediaType.video) {
      return _visualMediaSize;
    }
    return _defaultSize;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _previewSize,
      height: _previewSize,
      child: Stack(
        children: [
          Positioned.fill(child: _buildMediaBody()),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.xmark,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBody() {
    final mediaType = getMediaTypeFromFileName(file.name);

    if (mediaType == MediaType.image) {
      if (file.bytes != null) {
        return _mediaContainer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(file.bytes!, fit: BoxFit.cover),
          ),
        );
      }

      if (file.path != null && file.path!.isNotEmpty) {
        return _mediaContainer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(file.path!), fit: BoxFit.cover),
          ),
        );
      }
    }

    return _mediaContainer(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              _iconForMediaType(mediaType),
              size: 24,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 6),
            Text(
              file.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  IconData _iconForMediaType(MediaType type) {
    return switch (type) {
      MediaType.image => FontAwesomeIcons.image,
      MediaType.video => FontAwesomeIcons.video,
      MediaType.audio => FontAwesomeIcons.music,
      MediaType.document => FontAwesomeIcons.file,
      MediaType.unknown => FontAwesomeIcons.fileCircleQuestion,
    };
  }
}
