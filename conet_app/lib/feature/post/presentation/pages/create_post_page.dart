import 'dart:io';

import 'package:conet_app/core/common/utils/app_toast.dart';
import 'package:conet_app/core/utils/pick_files.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_actions_row.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_add_tags_section.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_app_bar.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_popular_tags.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  List<PlatformFile> _selectedFiles = [];
  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onPost() {
    if (_contentController.text.trim().isEmpty && _selectedFiles.isEmpty) {
      AppToast.showWarning(context, 'Please enter some content or add media');
      return;
    }

    final content = _contentController.text;
    // You might want to append tags to content or handle them separately in backend
    // For now, let's append them to content if your API expects that, or just keep them as is.
    // Based on previous code, it seems only content and media are sent.
    // If tags are part of content (hashtags), we can append them.
    // If there is a separate field for tags, we need to check PostCreatePostEvent.

    // Assuming tags are part of content for now as implied by "hashtags" usage.
    final fullContent = _selectedTags.isEmpty
        ? content
        : '$content\n\n${_selectedTags.map((t) => '#$t').join(' ')}';

    context.read<PostBloc>().add(
      PostCreatePostEvent(content: fullContent, media: _selectedFiles),
    );
  }

  Future<void> _pickFiles() async {
    final files = await pickFiles();
    if (files != null) {
      setState(() {
        _selectedFiles = files;
      });
    }
  }

  void _addTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostBloc, PostState>(
      listener: (context, state) {
        if (state is PostLoaded && state.recentlyCreated) {
          AppToast.showSuccess(context, 'Post created successfully!');
          context.pop();
        } else if (state is PostFailure) {
          AppToast.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is PostLoading;

        return Scaffold(
          appBar: CreatePostAppBar(onPost: _onPost, isLoading: isLoading),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreatePostTextField(controller: _contentController),
                const SizedBox(height: 12),
                if (_selectedFiles.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return Stack(
                          children: [
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: file.bytes != null
                                      ? MemoryImage(file.bytes!)
                                      : FileImage(File(file.path!))
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFiles.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                CreatePostActionsRow(onMediaTap: _pickFiles),
                const SizedBox(height: 20),
                CreatePostAddTagsSection(
                  tags: _selectedTags,
                  onAddTag: _addTag,
                  onRemoveTag: _removeTag,
                  controller: _tagController,
                ),
                const SizedBox(height: 12),
                CreatePostPopularTags(onTagSelected: _addTag),
              ],
            ),
          ),
        );
      },
    );
  }
}
