import 'package:cached_network_image/cached_network_image.dart';
import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/document_card.dart';
import 'package:conet_app/feature/message/domain/entities/shared_media_item.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:conet_app/feature/post/presentation/widgets/post_card.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class SharedMediaPage extends StatefulWidget {
  final String conversationId;
  final String type;

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
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.type;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 180) {
      final state = context.read<MessageBloc>().state;
      if (state.hasMoreSharedContent && !state.isFetchingMoreSharedContent) {
        context.read<MessageBloc>().add(
          MessageFetchMoreSharedContentRequested(
            conversationId: widget.conversationId,
            type: _selectedType,
          ),
        );
      }
    }
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          _titleForType(_selectedType),
          style: AppTextStyles.headingH3.copyWith(color: colors.textPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Column(
          children: [
            _buildTypeTabs(colors),
            Expanded(
              child: BlocBuilder<MessageBloc, MessageState>(
                buildWhen: (prev, cur) =>
                    prev.sharedContentStatus != cur.sharedContentStatus ||
                    prev.sharedContentType != cur.sharedContentType ||
                    prev.sharedContent != cur.sharedContent ||
                    prev.isFetchingMoreSharedContent !=
                        cur.isFetchingMoreSharedContent,
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
                    return _buildEmptyState(colors);
                  }

                  if (_selectedType == 'media') {
                    return _buildMediaGrid(context, items, colors);
                  }

                  if (_selectedType == 'post') {
                    return _buildPostList(context, items, colors, state);
                  }

                  return _buildDocsList(context, items, colors);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTabs(AppSemanticColors colors) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderStrong)),
      ),
      child: Row(
        children: [
          _buildTypeTab(colors, label: 'Media', type: 'media'),
          const SizedBox(width: 28),
          _buildTypeTab(colors, label: 'Posts', type: 'post'),
          const SizedBox(width: 28),
          _buildTypeTab(colors, label: 'Docs', type: 'docs'),
        ],
      ),
    );
  }

  Widget _buildTypeTab(
    AppSemanticColors colors, {
    required String label,
    required String type,
  }) {
    final isSelected = _selectedType == type;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => _onTypeSelected(type),
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? colors.borderFocus : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isSelected ? colors.textPrimary : colors.textSecondary,
              fontWeight: AppTypographyTokens.weightMedium,
            ),
          ),
        ),
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

  Widget _buildEmptyState(AppSemanticColors colors) {
    final icon = switch (_selectedType) {
      'media' => FontAwesomeIcons.photoFilm,
      'docs' => FontAwesomeIcons.fileLines,
      _ => FontAwesomeIcons.rectangleList,
    };
    final message = switch (_selectedType) {
      'media' => 'No photos or videos found',
      'docs' => 'No documents found',
      _ => 'No posts found',
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 48, color: colors.iconSecondary),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyDefault.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
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
    MessageState state,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      itemCount: items.length + (state.isFetchingMoreSharedContent ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final item = items[index];
        final post = item.post;

        if (post == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          child: PostCard(post: post),
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

        return DocumentCard(
          downloadUrl: url,
          filename: filename,
          fileSizeFuture: fileSizeFuture,
        );
      },
    );
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
}
