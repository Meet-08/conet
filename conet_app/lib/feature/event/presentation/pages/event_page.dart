import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/event/presentation/widgets/event_app_bar.dart';
import 'package:conet_app/feature/event/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late final EventBloc _eventBloc;

  @override
  void initState() {
    super.initState();
    _eventBloc = context.read<EventBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _eventBloc.add(const EventFetchPublishedEventsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EventAppBar(),
      body: BlocConsumer<EventBloc, EventState>(
        listenWhen: (_, current) =>
            current is EventFailure || current is EventSaveFailure,
        listener: (context, state) {
          if (state is EventFailure) {
            AppToast.showError(context, state.message);
          }
          if (state is EventSaveFailure) {
            AppToast.showError(context, state.message);
          }
        },
        buildWhen: (previous, current) =>
            current is EventLoading ||
            current is EventLoaded ||
            current is EventFailure ||
            current is EventInitial,
        builder: (context, state) {
          if (state is EventLoading) {
            return const Center(child: Loader());
          }
          if (state is EventLoaded) {
            return _EventBody(
              events: state.events,
              hasMore: state.hasMore,
              onRefresh: () async {
                _eventBloc.add(
                  const EventFetchPublishedEventsEvent(),
                );
              },
              onLoadMore: () {
                _eventBloc.add(
                  const EventFetchMorePublishedEventsEvent(),
                );
              },
            );
          }
          return const _EventEmptyBody();
        },
      ),
    );
  }
}

// ─── Loaded Body ─────────────────────────────────────────────────────────────

class _EventBody extends StatefulWidget {
  final List<EventListItem> events;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  const _EventBody({
    required this.events,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
  });

  @override
  State<_EventBody> createState() => _EventBodyState();
}

class _EventBodyState extends State<_EventBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.hasMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
        children: [
          _DiscoverSection(events: widget.events),
          if (widget.hasMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Loader(size: 24)),
            ),
        ],
      ),
    );
  }
}

class _EventEmptyBody extends StatelessWidget {
  const _EventEmptyBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      children: const [
        SizedBox(height: 28),
        _DiscoverSection(events: []),
      ],
    );
  }
}

class _DiscoverSection extends StatelessWidget {
  final List<EventListItem> events;

  const _DiscoverSection({required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        const SizedBox(height: 12),
        if (events.isNotEmpty)
          _buildList(context, theme, colorScheme)
        else
          // Empty state
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Calendar + magnifying glass stacked icon
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.calendarDays,
                        size: 56,
                        color: colorScheme.outlineVariant,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.magnifyingGlass,
                              size: 15,
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No events to discover right now.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Check back later or try exploring with different filters to find exciting events happening around you.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // TODO: clear filters
                      },
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Clear Filters'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => context.read<EventBloc>().add(
                        const EventFetchPublishedEventsEvent(),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Refresh Feed'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) =>
          EventCard(key: ValueKey(events[i].id), event: events[i]),
    );
  }
}
