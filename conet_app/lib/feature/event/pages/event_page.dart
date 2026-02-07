import 'package:conet_app/feature/event/widgets/discover_tab.dart';
import 'package:conet_app/feature/event/widgets/event_app_bar.dart';
import 'package:conet_app/feature/event/widgets/event_tabs.dart';
import 'package:conet_app/feature/event/widgets/my_events_tab.dart';
import 'package:conet_app/feature/event/widgets/organized_tab.dart';
import 'package:flutter/material.dart';

class EventPage extends StatelessWidget {
  const EventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: EventAppBar(),
        body: Column(
          children: [
            EventTabs(),
            Expanded(
              child: TabBarView(
                physics: BouncingScrollPhysics(), // 👈 sliding effect
                children: [DiscoverTab(), MyEventsTab(), OrganizedTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
