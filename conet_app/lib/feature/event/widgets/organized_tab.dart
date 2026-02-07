import 'package:flutter/material.dart';
import 'event_card.dart';

class OrganizedTab extends StatelessWidget {
  const OrganizedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        EventCard(showAnalytics: true),
      ],
    );
  }
}
