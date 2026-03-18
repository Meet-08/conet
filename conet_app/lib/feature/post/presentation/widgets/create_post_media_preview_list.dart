import 'package:conet_app/core/utils/media_type_utils.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_media_preview_item.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CreatePostMediaPreviewList extends StatelessWidget {
  final List<PlatformFile> files;
  final ValueChanged<int> onRemove;

  const CreatePostMediaPreviewList({
    super.key,
    required this.files,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    final hasVisualMedia = files.any((file) {
      final mediaType = getMediaTypeFromFileName(file.name);
      return mediaType == MediaType.image || mediaType == MediaType.video;
    });

    return SizedBox(
      height: hasVisualMedia ? 128 : 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return CreatePostMediaPreviewItem(
            file: files[index],
            onRemove: () => onRemove(index),
          );
        },
      ),
    );
  }
}
