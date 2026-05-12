import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/file_download_open_button.dart';
import 'package:conet_app/feature/message/domain/entities/shared_media_item.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SharedMediaPage extends StatefulWidget {
  final String conversationId;
  final String type; // 'media' | 'post' | 'docs'

  const SharedMediaPage({
    super.key,
    required this.conversationId,
    required this.type,
  });

  @override
  State<SharedMediaPage> createState() => _SharedMediaPageState();
}

class _SharedMediaPageState extends State<SharedMediaPage> {
  late String _selectedType;
  final Map<String, Future<int?>> _fileSizeRequests = {};

  @override
  void initState() {
    super.initState();
    _selectedType = widget.type;
    // Trigger initial fetch
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      context.read<MessageBloc>().add(
        MessageFetchSharedContentRequested(
          conversationId: widget.conversationId,
          type: _selectedType,
        ),
      );
    });
  }

  void _onTypeSelected(String type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    context.read<MessageBloc>().add(
      MessageFetchSharedContentRequested(
        conversationId: widget.conversationId,
        type: _selectedType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      backgroundColor: colors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: colors.backgroundSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _titleForType(_selectedType),
          style: AppTextStyles.headingH3.copyWith(color: colors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Media'),
                    selected: _selectedType == 'media',
                    onSelected: (_) => _onTypeSelected('media'),
                    selectedColor: colors.surfaceRaised,
                    backgroundColor: colors.surfaceBase,
                    labelStyle: AppTextStyles.bodyDefault.copyWith(
                      color: _selectedType == 'media'
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Posts'),
                    selected: _selectedType == 'post',
                    onSelected: (_) => _onTypeSelected('post'),
                    selectedColor: colors.surfaceRaised,
                    backgroundColor: colors.surfaceBase,
                    labelStyle: AppTextStyles.bodyDefault.copyWith(
                      color: _selectedType == 'post'
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Docs'),
                    selected: _selectedType == 'docs',
                    onSelected: (_) => _onTypeSelected('docs'),
                    selectedColor: colors.surfaceRaised,
                    backgroundColor: colors.surfaceBase,
                    labelStyle: AppTextStyles.bodyDefault.copyWith(
                      color: _selectedType == 'docs'
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<MessageBloc, MessageState>(
              buildWhen: (prev, cur) =>
                  prev.sharedContentStatus != cur.sharedContentStatus ||
                  prev.sharedContentType != cur.sharedContentType,
              builder: (context, state) {
                if (state.sharedContentStatus == MessageStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.sharedContentStatus == MessageStatus.failure) {
                  return Center(
                    child: Text(state.errorMessage ?? 'Failed to load items'),
                  );
                }

                final items = state.sharedContent;

                if (items.isEmpty) {
                  // Show placeholders matching selected type
                  if (_selectedType == 'media') {
                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                      itemCount: 6,
                      itemBuilder: (ctx, idx) => Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceBase,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.file,
                            color: colors.iconSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.file,
                          size: 48,
                          color: colors.iconSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items found',
                          style: AppTextStyles.bodyDefault.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_selectedType == 'media') {
                  return _buildMediaGrid(context, items, colors);
                }

                if (_selectedType == 'post') {
                  return _buildPostList(context, items, colors);
                }

                return _buildDocsList(context, items, colors);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _titleForType(String type) {
    switch (type) {
      case 'media':
        return 'Media';
      case 'docs':
        return 'Docs';
      default:
        return 'Posts';
    }
  }

  Widget _buildMediaGrid(
    BuildContext context,
    List<SharedMediaItem> items,
    AppSemanticColors colors,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final thumb =
            item.thumbnailUrl ??
            item.contentUrl ??
            (item.mediaUrls.isNotEmpty ? item.mediaUrls.first : null);
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceBase,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: thumb != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: thumb,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) =>
                        Container(color: colors.surfaceRaised),
                    errorWidget: (ctx, url, error) => Center(
                      child: FaIcon(
                        FontAwesomeIcons.file,
                        color: colors.iconSecondary,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: FaIcon(
                    FontAwesomeIcons.file,
                    color: colors.iconSecondary,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPostList(
    BuildContext context,
    List<SharedMediaItem> items,
    AppSemanticColors colors,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final post = item.post;
        final contentPreview = _plainTextFromQuill(
          post?.content ?? item.description ?? item.title ?? '',
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceBase,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.surfaceRaised,
                    child: FaIcon(
                      FontAwesomeIcons.user,
                      size: 18,
                      color: colors.iconSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post != null
                              ? ((post.user.firstName.trim().isNotEmpty)
                                    ? '${post.user.firstName} ${post.user.lastName}'
                                          .trim()
                                    : post.user.username)
                              : (item.senderName ?? 'Unknown'),
                          style: AppTextStyles.bodyDefault.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.createdAt != null
                              ? item.createdAt!
                                    .toLocal()
                                    .toString()
                                    .split('.')
                                    .first
                              : '',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                contentPreview,
                style: AppTextStyles.bodyDefault.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if ((item.mediaUrls).isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: item.mediaUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.mediaUrls[i],
                        width: 160,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          width: 160,
                          height: 120,
                          color: colors.surfaceRaised,
                        ),
                        errorWidget: (ctx, url, err) => Container(
                          width: 160,
                          height: 120,
                          color: colors.surfaceBase,
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.file,
                              color: colors.iconSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocsList(
    BuildContext context,
    List<SharedMediaItem> items,
    AppSemanticColors colors,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final url =
            item.contentUrl ??
            (item.mediaUrls.isNotEmpty ? item.mediaUrls.first : null);
        final filename = _filenameFromUrl(url);
        final fileSizeFuture = url == null ? null : _fileSizeForUrl(url);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceBase,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              FaIcon(FontAwesomeIcons.fileLines, color: colors.iconSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename ?? url ?? 'Unknown file',
                      style: AppTextStyles.bodyDefault.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (fileSizeFuture != null)
                      FutureBuilder<int?>(
                        future: fileSizeFuture,
                        builder: (context, snapshot) {
                          final sizeText =
                              snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? 'Checking size...'
                              : _formatFileSize(snapshot.data);

                          return Text(
                            sizeText,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              if (url != null)
                FileDownloadOpenButton(
                  downloadUrl: url,
                  fileName: filename ?? 'file',
                  allowRedownload: false,
                  usePublicDownloads: true,
                ),
            ],
          ),
        );
      },
    );
  }

  String _plainTextFromQuill(String raw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map && decoded['ops'] is List) {
        return (decoded['ops'] as List)
            .map((op) => op['insert']?.toString() ?? '')
            .join()
            .trim();
      }
    } catch (_) {}
    return raw;
  }

  String? _filenameFromUrl(String? url) {
    if (url == null) return null;
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
    } catch (_) {}
    final idx = url.lastIndexOf('/');
    if (idx != -1 && idx + 1 < url.length) return url.substring(idx + 1);
    return url;
  }

  Future<int?> _fileSizeForUrl(String url) {
    return _fileSizeRequests.putIfAbsent(url, () async {
      try {
        final response = await serviceLocator<DioClient>().dio.head(url);
        final headers = response.headers.map;
        final contentLength = headers['content-length']?.first;
        if (contentLength != null) {
          return int.tryParse(contentLength);
        }
      } catch (_) {}
      return null;
    });
  }

  String _formatFileSize(int? bytes) {
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
