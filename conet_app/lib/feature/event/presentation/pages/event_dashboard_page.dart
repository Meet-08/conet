import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/event/presentation/pages/create_event_page.dart';
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
    _DashboardFilter(label: 'Active', status: 'published', timeline: 'active'),
    _DashboardFilter(
      label: 'Upcoming',
      status: 'published',
      timeline: 'upcoming',
    ),
    _DashboardFilter(label: 'Past', status: 'published', timeline: 'past'),
    _DashboardFilter(label: 'Drafts', status: 'draft'),
  ];

  _DashboardFilter get _selectedFilter => _filters[_selectedFilterIndex];

  late final EventBloc _eventBloc;

  @override
  void initState() {
    super.initState();
    _eventBloc = context.read<EventBloc>();
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
      _eventBloc.add(
        const EventFetchMoreMyOrganizedEventsEvent(),
      );
    }
  }

  void _fetchForSelectedFilter() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    _eventBloc.add(
      EventFetchMyOrganizedEventsEvent(
        status: _selectedFilter.status,
        timeline: _selectedFilter.timeline,
        dateFrom: _selectedFilter.label == 'Upcoming' ? startOfToday : null,
        dateTo: _selectedFilter.label == 'Past' ? startOfToday : null,
        limit: 20,
      ),
    );
  }

  Future<void> _onRefresh() async {
    _fetchForSelectedFilter();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Scaffold(
      backgroundColor: semantic.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: semantic.backgroundPrimary,
        foregroundColor: semantic.iconPrimary,
        title: Text(
          'Events',
          style: AppTextStyles.headingH2.copyWith(color: semantic.textPrimary),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () async {
              final created = await context.push<bool>('/create-event');
              if (!mounted) return;
              if (created == true) {
                _fetchForSelectedFilter();
              }
            },
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
          final events = state is MyOrganizedEventsLoaded
              ? state.events
              : const <EventListItem>[];
          final hasMore = state is MyOrganizedEventsLoaded
              ? state.hasMore
              : false;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s16,
                AppSpace.s8,
                AppSpace.s16,
                AppSpace.s20,
              ),
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
                const SizedBox(height: AppSpace.s12),
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
                      padding: const EdgeInsets.only(bottom: AppSpace.s12),
                      child: _EventDashboardCard(
                        event: event,
                        filterLabel: _selectedFilter.label,
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
    final semantic = context.semanticColors;

    return SizedBox(
      height: AppSpace.s40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Text(
              filters[index].label,
              style: AppTextStyles.label.copyWith(
                color: selected ? semantic.textOnBrand : semantic.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onSelected: (_) => onSelected(index),
            selectedColor: semantic.backgroundBrand,
            side: BorderSide(color: semantic.borderDefault),
            backgroundColor: semantic.backgroundPrimary,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.fullAll,
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

  const _EventDashboardCard({required this.event, required this.filterLabel});

  String _priceLabel() {
    if (!event.isPaid) return 'FREE';
    final value = event.price;
    if (value == null) return 'PAID';
    if (value == value.roundToDouble()) {
      return '\u20B9${value.toInt()}';
    }
    return '\u20B9${value.toStringAsFixed(2)}';
  }

  Future<void> _openEditableFlow(BuildContext context) async {
    final isDraft = filterLabel == 'Drafts';
    final mode = isDraft
        ? CreateEventMode.completeDraftSetup
        : CreateEventMode.editUpcoming;

    final changed = await context.push<bool>(
      '/create-event',
      extra: CreateEventLaunchData(eventId: event.id, mode: mode),
    );

    if (changed == true && context.mounted) {
      context.read<EventBloc>().add(
        EventFetchMyOrganizedEventsEvent(
          status: isDraft ? 'draft' : 'published',
          timeline: isDraft ? null : 'upcoming',
          dateFrom: isDraft
              ? null
              : DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final dateText = DateFormat('MMM d').format(event.eventStartDate);
    final timeText = DateFormat('h:mm a').format(event.eventStartDate);
    final location = event.venue ?? event.location ?? 'Location TBA';
    final isDraft = filterLabel == 'Drafts';
    final isUpcoming = filterLabel == 'Upcoming';

    return Container(
      decoration: BoxDecoration(
        color: semantic.surfaceBase,
        border: Border.all(color: semantic.borderDefault),
        borderRadius: AppRadius.lgAll,
      ),
      padding: const EdgeInsets.all(AppSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverImage(imageUrl: event.eventImageUrl),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s8,
                            vertical: AppSpace.s4,
                          ),
                          decoration: BoxDecoration(
                            color: semantic.surfaceOverlay,
                            borderRadius: AppRadius.smAll,
                          ),
                          child: Text(
                            event.category.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: semantic.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _priceLabel(),
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w700,
                            color: semantic.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s10),
                    Text(
                      event.title,
                      style: AppTextStyles.headingH3.copyWith(
                        color: semantic.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s8),
                    _MetaRow(
                      icon: FontAwesomeIcons.calendarDay,
                      text: '$dateText - $timeText',
                    ),
                    const SizedBox(height: AppSpace.s4),
                    _MetaRow(
                      icon: FontAwesomeIcons.locationDot,
                      text: location,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          Divider(color: semantic.borderSubtle, height: 1),
          const SizedBox(height: AppSpace.s12),
          if (isDraft)
            OutlinedButton(
              onPressed: () => _openEditableFlow(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                side: BorderSide(color: semantic.borderDefault),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.xlAll,
                ),
              ),
              child: const Text('Complete Setup'),
            )
          else
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              children: [
                _ActionPill(
                  label: 'Analytics',
                  onTap: () {
                    context.push('/event-analytics/${event.id}');
                  },
                ),
                _ActionPill(
                  label: 'Attendees',
                  onTap: () {
                    final encodedTitle = Uri.encodeComponent(event.title);
                    context.push(
                      '/event-attendees/${event.id}?title=$encodedTitle',
                      extra: {'event': event},
                    );
                  },
                ),
                if (isUpcoming)
                  _ActionPill(
                    iconOnly: true,
                    icon: FontAwesomeIcons.penToSquare,
                    onTap: () => _openEditableFlow(context),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final FaIconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Row(
      children: [
        FaIcon(icon, size: 12, color: semantic.iconSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: semantic.textSecondary,
            ),
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
  final bool iconOnly;
  final FaIconData? icon;
  final VoidCallback? onTap;

  const _ActionPill({
    this.label = '',
    this.iconOnly = false,
    this.icon,
    this.onTap,
  });

  FaIconData _iconForLabel() {
    if (icon != null) return icon!;
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
    final semantic = context.semanticColors;

    return InkWell(
      borderRadius: AppRadius.xlAll,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: semantic.borderDefault),
          borderRadius: AppRadius.xlAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(_iconForLabel(), size: 12, color: semantic.iconPrimary),
            if (!iconOnly) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: semantic.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String? imageUrl;

  const _CoverImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: SizedBox(
        width: 92,
        height: 92,
        child: imageUrl != null && imageUrl!.trim().isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(semantic),
              )
            : _fallback(semantic),
      ),
    );
  }

  Widget _fallback(AppSemanticColors semantic) {
    return Container(
      color: semantic.surfaceOverlay,
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.image,
          size: 16,
          color: semantic.iconSecondary,
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
    final semantic = context.semanticColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 52, 8, 16),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.calendarXmark,
            size: 32,
            color: semantic.iconSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No $label events yet.',
            style: AppTextStyles.headingH3.copyWith(
              fontWeight: FontWeight.w700,
              color: semantic.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Events in this section will appear here once available.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyDefault.copyWith(
              color: semantic.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardFilter {
  final String label;
  final String? status;
  final String? timeline;

  const _DashboardFilter({
    required this.label,
    required this.status,
    this.timeline,
  });
}
