import 'package:conet_app/core/common/cubit/presence_cubit.dart';
import 'package:conet_app/core/widgets/online_indicator.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Conversation conversation;

  const ChatAppBar({super.key, required this.conversation});

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = conversation.displayName;
    final imageUrl = conversation.displayImageUrl;
    final initials = _getInitials(displayName);

    if (conversation.isGroup) {
      return _buildGroupAppBar(context, displayName, imageUrl, initials);
    }

    return _buildDirectAppBar(context, displayName, imageUrl, initials);
  }

  AppBar _buildGroupAppBar(
    BuildContext context,
    String displayName,
    String? imageUrl,
    String initials,
  ) {
    final memberCount = conversation.members.length;
    final subtitle = memberCount > 0 ? '$memberCount members' : 'Group';

    return AppBar(
      leadingWidth: 40,
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors
                .primaries[displayName.hashCode % Colors.primaries.length]
                .shade100,
            backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                ? NetworkImage(imageUrl)
                : null,
            child: (imageUrl == null || imageUrl.isEmpty)
                ? Icon(
                    Icons.group,
                    color: Colors
                        .primaries[displayName.hashCode %
                            Colors.primaries.length]
                        .shade800,
                    size: 20,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
          onPressed: () {},
        ),
      ],
    );
  }

  AppBar _buildDirectAppBar(
    BuildContext context,
    String displayName,
    String? imageUrl,
    String initials,
  ) {
    final otherUser = conversation.otherUser;

    return AppBar(
      leadingWidth: 40,
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar with online indicator
          if (otherUser != null)
            BlocSelector<PresenceCubit, Set<String>, bool>(
              selector: (onlineIds) => onlineIds.contains(otherUser.id),
              builder: (context, isOnline) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors
                          .primaries[displayName.hashCode %
                              Colors.primaries.length]
                          .shade100,
                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                          ? NetworkImage(imageUrl)
                          : null,
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? Text(
                              initials,
                              style: TextStyle(
                                color: Colors
                                    .primaries[displayName.hashCode %
                                        Colors.primaries.length]
                                    .shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: OnlineIndicator(isOnline: isOnline),
                    ),
                  ],
                );
              },
            )
          else
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors
                  .primaries[displayName.hashCode % Colors.primaries.length]
                  .shade100,
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors
                      .primaries[displayName.hashCode % Colors.primaries.length]
                      .shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Name and online status text
          if (otherUser != null)
            BlocSelector<PresenceCubit, Set<String>, bool>(
              selector: (onlineIds) => onlineIds.contains(otherUser.id),
              builder: (context, isOnline) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            )
          else
            Text(
              displayName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
