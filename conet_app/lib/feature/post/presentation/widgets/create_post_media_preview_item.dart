import 'dart:io';

import 'package:conet_app/core/theme/theme.dart';
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
    final semantic = context.semanticColors;

    return SizedBox(
      width: _previewSize,
      height: _previewSize,
      child: Stack(
        children: [
          Positioned.fill(child: _buildMediaBody(context)),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: semantic.backgroundBackdrop,
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  FontAwesomeIcons.xmark,
                  size: 16,
                  color: semantic.iconInverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaBody(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;
    final mediaType = getMediaTypeFromFileName(file.name);

    if (mediaType == MediaType.image) {
      if (file.bytes != null) {
        return _mediaContainer(
          context,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(file.bytes!, fit: BoxFit.cover),
          ),
        );
      }

      if (file.path != null && file.path!.isNotEmpty) {
        return _mediaContainer(
          context,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(file.path!), fit: BoxFit.cover),
          ),
        );
      }
    }

    return _mediaContainer(
      context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              _iconForMediaType(mediaType),
              size: 24,
              color: semantic.iconSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              file.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: semantic.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaContainer(BuildContext context, {required Widget child}) {
    final semantic = context.semanticColors;

    return Container(
      decoration: BoxDecoration(
        color: semantic.backgroundTertiary,
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
