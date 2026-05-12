import 'dart:async';

import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/utils/post_share_helper.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/feature/message/presentation/bloc/message_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class PostShareSheet extends StatefulWidget {
  final BuildContext parentContext;
  final String postId;
  final String username;
  final String contentPreview;

  const PostShareSheet({
    super.key,
    required this.parentContext,
    required this.postId,
    required this.username,
    required this.contentPreview,
  });

  @override
  State<PostShareSheet> createState() => _PostShareSheetState();
}

class _PostShareSheetState extends State<PostShareSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MessageBloc>().add(MessageConversationsRequested());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _buildShareText() {
    final deepLink = PostShareHelper.buildPostDeepLink(widget.postId);
    return 'Post by @${widget.username}\n$deepLink';
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    setState(() => _searchQuery = query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<MessageBloc>().add(
        MessageConversationsRequested(searchQuery: query),
      );
    });
  }

  Future<void> _copyLink() async {
    final deepLink = PostShareHelper.buildPostDeepLink(
      widget.postId,
    ).toString();
    await Clipboard.setData(ClipboardData(text: deepLink));
    if (!mounted) return;
    context.pop();
    AppToast.showSuccess(widget.parentContext, 'Post link copied');
  }

  Future<void> _shareVia() async {
    context.pop();
    await PostShareHelper.sharePost(
      postId: widget.postId,
      username: widget.username,
      content: widget.contentPreview,
    );
  }

  void _sendToConversation(String conversationId, String displayName) {
    context.read<MessageBloc>().add(
      MessageSent(
        conversationId: conversationId,
        content: _buildShareText(),
        isPost: true,
        postId: widget.postId,
      ),
    );
    context.pop();
    AppToast.showSuccess(widget.parentContext, 'Sent to $displayName');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: semantic.surfaceOverlay,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            child: Column(
              children: [
                // ── Scrollable section — Expanded forces it to fill remaining
                //    space after the pinned buttons, so it scrolls instead of
                //    overflowing when the sheet is dragged to a small size. ──
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: semantic.borderStrong.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Share post',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: semantic.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: semantic.borderSubtle),
                        const SizedBox(height: 20),
                        Text(
                          'Send as message',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: semantic.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Search field
                        TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search conversations',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: FaIcon(
                                FontAwesomeIcons.magnifyingGlass,
                                size: 16,
                                color: semantic.iconSecondary,
                              ),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                    icon: FaIcon(
                                      FontAwesomeIcons.xmark,
                                      size: 16,
                                      color: semantic.iconSecondary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ── Horizontal conversations list ──
                        SizedBox(
                          height: 96,
                          child: BlocBuilder<MessageBloc, MessageState>(
                            builder: (context, state) {
                              final conversations = state.conversations;

                              if (state.conversationStatus ==
                                      MessageStatus.loading &&
                                  conversations.isEmpty) {
                                return const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                );
                              }

                              if (conversations.isEmpty) {
                                return Center(
                                  child: Text(
                                    _searchQuery.isEmpty
                                        ? 'No conversations available'
                                        : 'No matching conversations found',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: semantic.textSecondary,
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: conversations.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  final conversation = conversations[index];
                                  return GestureDetector(
                                    onTap: () => _sendToConversation(
                                      conversation.id,
                                      conversation.displayName,
                                    ),
                                    child: SizedBox(
                                      width: 64,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CustomCircleAvatar(
                                            radius: 28,
                                            imageUrl:
                                                conversation.displayImageUrl,
                                            displayName:
                                                conversation.displayName,
                                            backgroundColor: Colors
                                                .primaries[conversation
                                                        .displayName
                                                        .hashCode %
                                                    Colors.primaries.length]
                                                .shade100,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            conversation.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: semantic.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                Divider(height: 1, color: semantic.borderSubtle),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PostShareActionButton(
                      icon: FontAwesomeIcons.link,
                      label: 'Copy link',
                      onTap: _copyLink,
                    ),
                    _PostShareActionButton(
                      icon: FontAwesomeIcons.shareNodes,
                      label: 'Share via',
                      onTap: _shareVia,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostShareActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PostShareActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: semantic.surfaceRaised,
                shape: BoxShape.circle,
                border: Border.all(color: semantic.borderSubtle),
              ),
              alignment: Alignment.center,
              child: FaIcon(icon, size: 20, color: semantic.iconPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: semantic.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
