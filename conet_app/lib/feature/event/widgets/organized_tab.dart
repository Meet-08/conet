import 'package:conet_app/feature/event/widgets/event_card.dart';
import 'package:flutter/material.dart';

class OrganizedTab extends StatelessWidget {
  const OrganizedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [EventCard(showAnalytics: true)],
    );
  }
}
