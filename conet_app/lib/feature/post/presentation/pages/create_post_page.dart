import 'dart:convert';

import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/utils/pick_files.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_actions_row.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_add_tags_section.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_app_bar.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_media_preview_list.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_popular_tags.dart';
import 'package:conet_app/feature/post/presentation/widgets/create_post_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  static const int _maxMediaCount = 10;
  final QuillController _contentController = QuillController.basic();
  final TextEditingController _tagController = TextEditingController();
  List<PlatformFile> _selectedFiles = [];
  final List<String> _selectedTags = [];
  bool _isSubmittingPost = false;

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onPost() {
    if (_isSubmittingPost) return;

    if (_contentController.document.toPlainText().trim().isEmpty &&
        _selectedFiles.isEmpty) {
      AppToast.showWarning(context, 'Please enter some content or add media');
      return;
    }

    final fullContent = jsonEncode({
      'ops': _contentController.document.toDelta().toJson(),
      'tags': _selectedTags,
    });

    setState(() {
      _isSubmittingPost = true;
    });

    context.read<PostBloc>().add(
      PostCreatePostEvent(content: fullContent, media: _selectedFiles),
    );
  }

  void _toggleInlineStyle(Attribute attribute) {
    final style = _contentController.getSelectionStyle();
    if (style.attributes.containsKey(attribute.key)) {
      _contentController.formatSelection(Attribute.clone(attribute, null));
      return;
    }
    _contentController.formatSelection(attribute);
  }

  void _toggleBulletList() {
    final style = _contentController.getSelectionStyle();
    final currentList = style.attributes[Attribute.list.key];
    if (currentList?.value == Attribute.ul.value) {
      _contentController.formatSelection(Attribute.clone(Attribute.ul, null));
      return;
    }
    _contentController.formatSelection(Attribute.ul);
  }

  Future<void> _pickFiles() async {
    final remainingSlots = _maxMediaCount - _selectedFiles.length;
    if (remainingSlots <= 0) {
      AppToast.showWarning(
        context,
        'You can attach up to $_maxMediaCount files per post',
      );
      return;
    }

    final files = await pickFiles(limit: remainingSlots);
    if (files == null || files.isEmpty) return;

    setState(() {
      _selectedFiles = [..._selectedFiles, ...files];
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _clearAllFiles() {
    if (_selectedFiles.isEmpty) return;
    setState(() {
      _selectedFiles = [];
    });
  }

  Widget _selectedMediaHeader() {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Attached media (${_selectedFiles.length}/$_maxMediaCount)',
          style: textTheme.labelLarge?.copyWith(color: semantic.textPrimary),
        ),
        TextButton(onPressed: _clearAllFiles, child: const Text('Clear all')),
      ],
    );
  }

  Widget _selectedMediaSection() {
    if (_selectedFiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _selectedMediaHeader(),
        const SizedBox(height: 8),
        CreatePostMediaPreviewList(
          files: _selectedFiles,
          onRemove: _removeFile,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostBloc, PostState>(
      listener: (context, state) {
        if (state is PostLoaded && state.recentlyCreated) {
          AppToast.showSuccess(context, 'Post created successfully!');
          context.pop();
        } else if (state is PostFailure) {
          if (_isSubmittingPost && mounted) {
            setState(() {
              _isSubmittingPost = false;
            });
          }
          AppToast.showError(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is PostLoading || _isSubmittingPost;

        return Scaffold(
          appBar: CreatePostAppBar(onPost: _onPost, isLoading: isLoading),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreatePostTextField(controller: _contentController),
                const SizedBox(height: 12),
                _selectedMediaSection(),
                AnimatedBuilder(
                  animation: _contentController,
                  builder: (context, _) {
                    final style = _contentController.getSelectionStyle();
                    final currentList = style.attributes[Attribute.list.key];
                    return CreatePostActionsRow(
                      onMediaTap: _pickFiles,
                      onBoldTap: () => _toggleInlineStyle(Attribute.bold),
                      onItalicTap: () => _toggleInlineStyle(Attribute.italic),
                      onListTap: _toggleBulletList,
                      isBoldActive: style.attributes.containsKey(
                        Attribute.bold.key,
                      ),
                      isItalicActive: style.attributes.containsKey(
                        Attribute.italic.key,
                      ),
                      isListActive: currentList?.value == Attribute.ul.value,
                    );
                  },
                ),
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
}
