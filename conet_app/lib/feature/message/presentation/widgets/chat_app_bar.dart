import 'package:conet_app/core/common/cubit/presence_cubit.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/widgets/online_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User otherUser;

  const ChatAppBar({super.key, required this.otherUser});

  String _displayName() {
    final name = '${otherUser.firstName} ${otherUser.lastName}'.trim();
    if (name.isNotEmpty) return name;
    if (otherUser.username.isNotEmpty) return otherUser.username;
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName();
    final initials = displayName
        .split(RegExp(r'\s+'))
        .map((part) => part.isNotEmpty ? part[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return AppBar(
      leadingWidth: 40,
      leading: IconButton(
        icon: const FaIcon(FontAwesomeIcons.arrowLeft),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar with online indicator
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
                    backgroundImage:
                        (otherUser.profilePicUrl != null &&
                            otherUser.profilePicUrl!.isNotEmpty)
                        ? NetworkImage(otherUser.profilePicUrl!)
                        : null,
                    child:
                        (otherUser.profilePicUrl == null ||
                            otherUser.profilePicUrl!.isEmpty)
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
          ),
          const SizedBox(width: 8),
          // Name and online status text
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
