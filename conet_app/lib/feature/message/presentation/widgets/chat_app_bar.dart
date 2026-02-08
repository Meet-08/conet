import 'package:conet_app/core/common/entities/user.dart';
import 'package:flutter/material.dart';

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
    return AppBar(
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            child: Text(_displayName().substring(0, 1).toUpperCase()),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Online',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
        IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
