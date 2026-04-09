import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventDashboardPage extends StatefulWidget {
  const EventDashboardPage({super.key});

  @override
  State<EventDashboardPage> createState() => _EventDashboardPageState();
}

class _EventDashboardPageState extends State<EventDashboardPage> {
  final _scrollController = ScrollController();
  int _selectedFilterIndex = 0;

  static const _filters = [
    _DashboardFilter(label: 'Active', status: 'published'),
    _DashboardFilter(label: 'Upcoming', status: 'published'),
    _DashboardFilter(label: 'Past', status: 'published'),
    _DashboardFilter(label: 'Drafts', status: 'draft'),
  ];

  _DashboardFilter get _selectedFilter => _filters[_selectedFilterIndex];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchForSelectedFilter();
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
      context.read<EventBloc>().add(
        const EventFetchMoreMyOrganizedEventsEvent(),
      );
    }
  }

  void _fetchForSelectedFilter() {
    context.read<EventBloc>().add(
      EventFetchMyOrganizedEventsEvent(
        status: _selectedFilter.status,
        limit: 20,
      ),
    );
  }

  Future<void> _onRefresh() async {
    _fetchForSelectedFilter();
  }

  List<EventListItem> _filterByTab(List<EventListItem> events, String label) {
    if (label != 'Upcoming' && label != 'Past') {
      return events;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (label == 'Upcoming') {
      return events
          .where((event) => !event.eventStartDate.isBefore(today))
          .toList();
    }

    return events
        .where((event) => event.eventStartDate.isBefore(today))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.push('/create-event'),
            icon: const FaIcon(FontAwesomeIcons.plus),
          ),
        ],
      ),
      body: BlocConsumer<EventBloc, EventState>(
        listenWhen: (_, state) => state is MyOrganizedEventsFailure,
        listener: (context, state) {
          if (state is MyOrganizedEventsFailure) {
            AppToast.showError(context, state.message);
          }
        },
        buildWhen: (_, state) =>
            state is MyOrganizedEventsLoading ||
            state is MyOrganizedEventsLoaded ||
            state is MyOrganizedEventsFailure ||
            state is EventInitial,
        builder: (context, state) {
          final isLoading = state is MyOrganizedEventsLoading;
          final rawEvents = state is MyOrganizedEventsLoaded
              ? state.events
              : const <EventListItem>[];
          final events = _filterByTab(rawEvents, _selectedFilter.label);
          final hasMore = state is MyOrganizedEventsLoaded
              ? state.hasMore
              : false;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                _FilterRow(
                  filters: _filters,
                  selectedIndex: _selectedFilterIndex,
                  onSelected: (index) {
                    if (_selectedFilterIndex == index) return;
                    setState(() {
                      _selectedFilterIndex = index;
                    });
                    _fetchForSelectedFilter();
                  },
                ),
                const SizedBox(height: 12),
                if (isLoading && events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (events.isEmpty)
                  _EmptyState(label: _selectedFilter.label)
                else
                  ...events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _EventDashboardCard(
                        event: event,
                        filterLabel: _selectedFilter.label,
                        theme: theme,
                      ),
                    ),
                  ),
                if (hasMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final List<_DashboardFilter> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _FilterRow({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Text(filters[index].label),
            onSelected: (_) => onSelected(index),
            selectedColor: colorScheme.onSurface,
            labelStyle: TextStyle(
              color: selected ? colorScheme.surface : colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            side: BorderSide(color: colorScheme.outlineVariant),
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          );
        },
      ),
    );
  }
}

class _EventDashboardCard extends StatelessWidget {
  final EventListItem event;
  final String filterLabel;
  final ThemeData theme;

  const _EventDashboardCard({
    required this.event,
    required this.filterLabel,
    required this.theme,
  });

  List<String> _actionLabels() {
    if (filterLabel == 'Drafts') return const ['Edit'];
    return const ['Analytics', 'Attendees'];
  }

  String _priceLabel() {
    if (!event.isPaid) return 'Free';
    final value = event.price;
    if (value == null) return 'Paid';
    if (value == value.roundToDouble()) {
      return 'Rs ${value.toInt()}';
    }
    return 'Rs ${value.toStringAsFixed(2)}';
  }

  void _handleActionTap(BuildContext context, String action) {
    switch (action) {
      case 'Attendees':
        context.push(
          '/event-attendees',
          extra: {'eventId': event.id, 'eventTitle': event.title},
        );
        return;
      case 'Analytics':
        AppToast.showInfo(context, 'Analytics dashboard is coming soon.');
        return;
      case 'Edit':
        AppToast.showInfo(context, 'Draft editing flow is not available yet.');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final actions = _actionLabels();
    final dateText = DateFormat('MMM d').format(event.eventStartDate);
    final timeText = DateFormat('h:mm a').format(event.eventStartDate);
    final location = event.venue ?? event.location ?? 'Location TBA';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${event.category.toUpperCase()} - ${filterLabel.toUpperCase()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _priceLabel(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: FontAwesomeIcons.calendarDay,
            text: '$dateText - $timeText',
          ),
          const SizedBox(height: 4),
          _MetaRow(icon: FontAwesomeIcons.locationDot, text: location),
          const SizedBox(height: 12),
          if (filterLabel == 'Active' || filterLabel == 'Drafts') ...[
            OutlinedButton(
              onPressed: filterLabel == 'Drafts'
                  ? null
                  : () {
                      context.push(
                        '/event-attendance-scan',
                        extra: {'eventId': event.id, 'eventTitle': event.title},
                      );
                    },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                filterLabel == 'Drafts' ? 'Complete Setup' : 'Scan Tickets',
              ),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions
                .map(
                  (action) => _ActionPill(
                    label: action,
                    onTap: () => _handleActionTap(context, action),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;

    return Row(
      children: [
        FaIcon(icon, size: 12, color: style?.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ActionPill({required this.label, this.onTap});

  IconData _iconForLabel() {
    switch (label) {
      case 'Analytics':
        return FontAwesomeIcons.chartLine;
      case 'Attendees':
        return FontAwesomeIcons.userGroup;
      case 'Edit':
        return FontAwesomeIcons.penToSquare;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(_iconForLabel(), size: 12),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;

  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 52, 8, 16),
      child: Column(
        children: [
          const FaIcon(FontAwesomeIcons.calendarXmark, size: 32),
          const SizedBox(height: 12),
          Text(
            'No $label events yet.',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Events in this section will appear here once available.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DashboardFilter {
  final String label;
  final String? status;

  const _DashboardFilter({required this.label, required this.status});
}
