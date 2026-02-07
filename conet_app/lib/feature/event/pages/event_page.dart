import 'package:flutter/material.dart';
import '../widgets/event_app_bar.dart';
import '../widgets/event_tabs.dart';
import '../widgets/discover_tab.dart';
import '../widgets/my_events_tab.dart';
import '../widgets/organized_tab.dart';

class EventPage extends StatelessWidget {
  const EventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const EventAppBar(),
        body: Column(
          children: [
            const EventTabs(),
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(), // 👈 sliding effect
                children: const [
                  DiscoverTab(),
                  MyEventsTab(),
                  OrganizedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
