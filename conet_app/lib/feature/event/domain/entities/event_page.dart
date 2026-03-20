import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';

class EventPage {
  final List<EventListItem> events;
  final String? nextCursor;
  final bool hasMore;
  final int pageSize;

  const EventPage({
    required this.events,
    required this.nextCursor,
    required this.hasMore,
    required this.pageSize,
  });
}
