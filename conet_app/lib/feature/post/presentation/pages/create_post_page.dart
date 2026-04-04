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
import 'package:go_router/go_router.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  static const int _maxMediaCount = 10;
  final TextEditingController _contentController = TextEditingController();
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

    if (_contentController.text.trim().isEmpty && _selectedFiles.isEmpty) {
      AppToast.showWarning(context, 'Please enter some content or add media');
      return;
    }

    final content = _contentController.text;
    final fullContent = _selectedTags.isEmpty
        ? content
        : '$content\n\n${_selectedTags.map((t) => '#$t').join(' ')}';

    setState(() {
      _isSubmittingPost = true;
    });

    context.read<PostBloc>().add(
      PostCreatePostEvent(content: fullContent, media: _selectedFiles),
    );
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
