import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/event/presentation/widgets/event_card.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventBloc>().add(const EventFetchPublishedEventsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _EventAppBar(
        isGridView: _isGridView,
        onToggleView: () => setState(() => _isGridView = !_isGridView),
      ),
      body: BlocConsumer<EventBloc, EventState>(
        listenWhen: (_, current) => current is EventFailure,
        listener: (context, state) {
          if (state is EventFailure) {
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
              isGridView: _isGridView,
              onRefresh: () async {
                context.read<EventBloc>().add(
                  const EventFetchPublishedEventsEvent(),
                );
              },
              onLoadMore: () {
                context.read<EventBloc>().add(
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

// ─── App Bar ─────────────────────────────────────────────────────────────────

class _EventAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isGridView;
  final VoidCallback onToggleView;

  const _EventAppBar({required this.isGridView, required this.onToggleView});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      title: const Text('Events'),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () {},
          // TODO: open search
          icon: FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            size: 17,
            color: colorScheme.onSurface,
          ),
          tooltip: 'Search events',
        ),
        IconButton(
          onPressed: onToggleView,
          icon: FaIcon(
            isGridView
                ? FontAwesomeIcons.listUl
                : FontAwesomeIcons.tableCellsLarge,
            size: 17,
            color: colorScheme.onSurface,
          ),
          tooltip: isGridView ? 'List view' : 'Grid view',
        ),
        IconButton(
          onPressed: () {},
          // TODO: open calendar view
          icon: FaIcon(
            FontAwesomeIcons.calendarDays,
            size: 17,
            color: colorScheme.onSurface,
          ),
          tooltip: 'Calendar view',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Loaded Body ─────────────────────────────────────────────────────────────

class _EventBody extends StatefulWidget {
  final List<EventListItem> events;
  final bool hasMore;
  final bool isGridView;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  const _EventBody({
    required this.events,
    required this.hasMore,
    required this.isGridView,
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
          const _CampusSection(),
          const SizedBox(height: 28),
          _DiscoverSection(
            events: widget.events,
            isGridView: widget.isGridView,
          ),
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

// ─── Empty Body ───────────────────────────────────────────────────────────────

class _EventEmptyBody extends StatelessWidget {
  const _EventEmptyBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      children: const [
        _CampusSection(),
        SizedBox(height: 28),
        _DiscoverSection(events: []),
      ],
    );
  }
}

// ─── From Your Campus Section ─────────────────────────────────────────────────

class _CampusSection extends StatelessWidget {
  const _CampusSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () {
              // TODO: navigate to campus events list
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'From Your Campus',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 13,
                  color: colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Dashed card — full width
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions(
              radius: const .circular(16),
              color: colorScheme.outlineVariant,
              strokeWidth: 1.5,
              dashPattern: const [6, 4],
            ),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    // Graduation cap in circle
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.graduationCap,
                          size: 26,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No upcoming campus events yet!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/create-event'),
                      icon: const FaIcon(FontAwesomeIcons.circlePlus, size: 15),
                      label: const Text('Host Event'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 10,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Discover Section ─────────────────────────────────────────────────────────

class _DiscoverSection extends StatelessWidget {
  final List<EventListItem> events;
  final bool isGridView;

  const _DiscoverSection({required this.events, this.isGridView = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discover',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: open filter sheet
                },
                icon: FaIcon(
                  FontAwesomeIcons.sliders,
                  size: 18,
                  color: colorScheme.onSurface,
                ),
                tooltip: 'Filter events',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (events.isNotEmpty)
          isGridView
              ? _buildGrid(context, theme, colorScheme)
              : _buildList(context, theme, colorScheme)
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
                      onPressed: () {
                        // TODO: refresh discover feed
                      },
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
      itemBuilder: (_, i) => EventCard(event: events[i]),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: events.length,
        itemBuilder: (_, i) => EventCard(event: events[i], compact: true),
      ),
    );
  }
}
