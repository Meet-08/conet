import 'package:flutter/material.dart';
import 'conversation_tile.dart';

class ConversationList extends StatelessWidget {
  const ConversationList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ConversationTile(
          initials: 'PS',
          name: 'Priya Sharma',
          message: 'Hey! Did you check out the ML workshop?',
          time: '44m',
          unreadCount: 2,
        ),
        ConversationTile(
          initials: 'CFYP',
          name: 'CS Final Year Project',
          message: 'Alex Chen: Meeting tomorrow at 3 PM',
          time: '59m',
          unreadCount: 3,
        ),
        ConversationTile(
          initials: 'IBS',
          name: 'IIT Bombay Students',
          message: '#placements: Placement drive starts soon',
          time: '1h',
          unreadCount: 27,
        ),
        ConversationTile(
          initials: 'ASG',
          name: 'AI/ML Study Group',
          message: 'Dr. Sharma: Check out this amazing resource',
          time: '1h',
          unreadCount: 7,
        ),
        ConversationTile(
          initials: 'CSH',
          name: 'Computer Science Hub',
          message: '#projects: Check out this amazing opportunity',
          time: '2h',
          unreadCount: 45,
        ),
        ConversationTile(
          initials: 'RK',
          name: 'Rahul Kumar',
          message: "You: Great! Let's finalize the team",
          time: '2h',
        ),
      ],
    );
  }
}
