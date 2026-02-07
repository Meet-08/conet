import 'package:flutter/material.dart';
import 'event_card.dart';

class MyEventsTab extends StatelessWidget {
  const MyEventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Saved Events', count: 17),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              EventCard(),
              EventCard(),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Past Events', count: 6),
        const SizedBox(height: 12),
        const EventCard(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          'See all ($count)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
