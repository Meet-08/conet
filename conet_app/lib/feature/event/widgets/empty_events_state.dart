import 'package:flutter/material.dart';

class EmptyEventsState extends StatelessWidget {
  const EmptyEventsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.event_available_outlined, size: 48),
          SizedBox(height: 12),
          Text(
            'No events found',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Try adjusting your filters or check back later\nfor new events',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
