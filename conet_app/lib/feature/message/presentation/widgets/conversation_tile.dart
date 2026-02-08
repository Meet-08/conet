import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const ConversationTile({super.key, required this.conversation});

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = conversation.otherUser;
    final displayName =
        (otherUser.firstName.trim().isNotEmpty ||
            otherUser.lastName.trim().isNotEmpty)
        ? '${otherUser.firstName} ${otherUser.lastName}'.trim()
        : (otherUser.username.isNotEmpty ? otherUser.username : 'User');
    final initials = _getInitials(displayName);

    return InkWell(
      onTap: () {
        context.push('/chat-detail', extra: conversation);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors
                    .primaries[displayName.hashCode % Colors.primaries.length]
                    .shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Colors
                        .primaries[displayName.hashCode %
                            Colors.primaries.length]
                        .shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Now',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tap to open chat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
