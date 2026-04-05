import 'dart:async';

import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventSearchPage extends StatefulWidget {
  const EventSearchPage({super.key});

  @override
  State<EventSearchPage> createState() => _EventSearchPageState();
}

class _EventSearchPageState extends State<EventSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = value.trim();
      context.read<EventBloc>().add(
        EventFetchPublishedEventsEvent(search: query.isEmpty ? null : query),
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<EventBloc>().add(const EventFetchPublishedEventsEvent());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Search Events'), centerTitle: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    cursorColor: colorScheme.primary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by title, category, location...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FaIcon(
                            FontAwesomeIcons.magnifyingGlass,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: _clearSearch,
                              icon: FaIcon(
                                FontAwesomeIcons.circleXmark,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              tooltip: 'Clear search',
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: IconButton(
                    onPressed: () {
                      AppToast.showInfo(
                        context,
                        'Filters will be available soon',
                      );
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.sliders,
                      size: 16,
                      color: colorScheme.onSurface,
                    ),
                    tooltip: 'Filter events',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<EventBloc, EventState>(
              listenWhen: (_, current) => current is EventFailure,
              listener: (context, state) {
                if (state is EventFailure) {
                  AppToast.showError(context, state.message);
                }
              },
              buildWhen: (_, current) =>
                  current is EventLoading ||
                  current is EventLoaded ||
                  current is EventFailure ||
                  current is EventInitial,
              builder: (context, state) {
                if (state is EventLoading) {
                  return const Center(child: Loader());
                }

                final events = state is EventLoaded
                    ? state.events
                    : <EventListItem>[];

                if (events.isEmpty) {
                  return _SearchEmptyState(
                    query: _searchController.text.trim(),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) =>
                      _SearchEventCard(event: events[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEventCard extends StatelessWidget {
  final EventListItem event;

  const _SearchEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateText = DateFormat('MMM d').format(event.eventStartDate);
    final location = event.venue ?? event.location ?? 'Location TBA';

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/event-detail/${event.id}'),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 78,
                    height: 78,
                    child: event.eventImageUrl != null
                        ? Image.network(
                            event.eventImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _imagePlaceholder(colorScheme),
                          )
                        : _imagePlaceholder(colorScheme),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _metaLine(
                        context: context,
                        icon: FontAwesomeIcons.calendarDay,
                        text: dateText,
                      ),
                      const SizedBox(height: 4),
                      _metaLine(
                        context: context,
                        icon: FontAwesomeIcons.locationDot,
                        text: location,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              context.push('/event-detail/${event.id}'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Text('View Details'),
                          label: FaIcon(
                            FontAwesomeIcons.chevronRight,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaLine({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        FaIcon(icon, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.image,
          size: 20,
          color: colorScheme.outline,
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final String query;

  const _SearchEmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasQuery = query.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.calendarXmark,
              size: 42,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 14),
            Text(
              hasQuery ? 'No matching events found' : 'No events available',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try a different keyword, category, or location.'
                  : 'Check back later for newly published events.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
