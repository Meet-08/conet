import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/event/presentation/constants/event_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MyEventsPage extends StatefulWidget {
  final EventType eventType;
  const MyEventsPage({super.key, required this.eventType});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  late EventType _selectedType;
  final Map<EventType, int> _typeCounts = {};
  final _scrollController = ScrollController();

  static const _labelByType = {
    EventType.upcoming: 'Upcoming',
    EventType.past: 'Past',
    EventType.saved: 'Saved',
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.eventType;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchForType(_selectedType);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 180) {
      context.read<EventBloc>().add(const EventFetchMoreMyEventsEvent());
    }
  }

  void _fetchForType(EventType type) {
    context.read<EventBloc>().add(
      EventFetchMyEventsEvent(type: _apiType(type), limit: 20),
    );
  }

  String _apiType(EventType type) => switch (type) {
    EventType.upcoming => 'upcoming',
    EventType.past => 'past',
    EventType.saved => 'saved',
  };

  EventType _eventTypeFromApiType(String type) {
    return switch (type) {
      'upcoming' => EventType.upcoming,
      'past' => EventType.past,
      'saved' => EventType.saved,
      _ => EventType.upcoming,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Scaffold(
      backgroundColor: semantic.backgroundSecondary,
      body: SafeArea(
        child: BlocConsumer<EventBloc, EventState>(
          listenWhen: (_, current) =>
              current is MyEventsFailure || current is MyEventsLoaded,
          listener: (context, state) {
            if (state is MyEventsFailure) {
              AppToast.showError(context, state.message);
            }

            if (state is MyEventsLoaded) {
              final type = _eventTypeFromApiType(state.type);
              _typeCounts[type] = state.events.length;
            }
          },
          buildWhen: (_, current) =>
              current is MyEventsLoading ||
              current is MyEventsLoaded ||
              current is MyEventsFailure ||
              current is EventInitial,
          builder: (context, state) {
            final events = state is MyEventsLoaded
                ? state.events
                : const <EventListItem>[];
            final hasMore = state is MyEventsLoaded ? state.hasMore : false;
            final isLoading = state is MyEventsLoading;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const FaIcon(
                              FontAwesomeIcons.arrowLeft,
                              size: 18,
                            ),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Back',
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'My Events',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: semantic.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: EventType.values.map((type) {
                          final selected = type == _selectedType;
                          final label = _labelByType[type]!;
                          final count = _typeCounts[type];

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: AppRadius.smAll,
                              onTap: () {
                                if (_selectedType == type) return;
                                setState(() {
                                  _selectedType = type;
                                });
                                _fetchForType(type);
                              },
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
                                child: Column(
                                  children: [
                                    Text(
                                      count == null ? label : '$label ($count)',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: selected
                                                ? semantic.textPrimary
                                                : semantic.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      height: 2.5,
                                      width: selected ? 62 : 0,
                                      color: semantic.textPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _fetchForType(_selectedType),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                      itemCount: events.length + (hasMore || isLoading ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= events.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            ),
                          );
                        }
                        return _MyEventCard(
                          event: events[index],
                          type: _selectedType,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MyEventCard extends StatelessWidget {
  final EventListItem event;
  final EventType type;

  const _MyEventCard({required this.event, required this.type});

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('MMM d').format(event.eventStartDate);
    final timeText = DateFormat('h:mm a').format(event.eventStartDate);
    final location = event.venue ?? event.location ?? 'Location TBA';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: event.eventImageUrl == null
                      ? Container(
                          color: const Color(0xFFEDEFF3),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.calendarDays,
                              size: 20,
                              color: Color(0xFF98A2B3),
                            ),
                          ),
                        )
                      : Image.network(
                          event.eventImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFEDEFF3),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.calendarDays,
                                size: 20,
                                color: Color(0xFF98A2B3),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475467),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          event.isPaid
                              ? '₹${event.price?.toStringAsFixed(0) ?? '0'}'
                              : 'FREE',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 25 / 2,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D2939),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MetaLine(
                      icon: FontAwesomeIcons.calendarDay,
                      text: '$dateText • $timeText',
                    ),
                    const SizedBox(height: 3),
                    _MetaLine(
                      icon: FontAwesomeIcons.locationDot,
                      text: location,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (type == EventType.saved) ...[
            const SizedBox(height: 10),
            Text(
              _savedHint(event.eventStartDate),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _savedHintColor(event.eventStartDate),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  filled: true,
                  icon: FontAwesomeIcons.ticket,
                  label: 'View Ticket',
                  onTap: () {
                    context.push('/view-ticket', extra: {'eventId': event.id});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  filled: false,
                  icon: FontAwesomeIcons.users,
                  label: 'Event Group',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _savedHint(DateTime startDate) {
    final days = startDate.difference(DateTime.now()).inDays;
    if (days <= 3) {
      return 'Only ${days < 0 ? 0 : days} days left';
    }
    return 'Upcoming event in $days days';
  }

  Color _savedHintColor(DateTime startDate) {
    final days = startDate.difference(DateTime.now()).inDays;
    return days <= 3 ? const Color(0xFF2563EB) : const Color(0xFFF97316);
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, size: 11, color: const Color(0xFF98A2B3)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final bool filled;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.filled,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: filled ? null : Border.all(color: const Color(0xFFD0D5DD)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 12,
                color: filled ? Colors.white : const Color(0xFF344054),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : const Color(0xFF344054),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

