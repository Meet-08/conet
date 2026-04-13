import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/widgets/file_download_open_button.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_registration_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventAttendeesPage extends StatefulWidget {
  final String eventId;
  final String? eventTitle;
  final Event? event;

  const EventAttendeesPage({
    super.key,
    required this.eventId,
    this.eventTitle,
    this.event,
  });

  @override
  State<EventAttendeesPage> createState() => _EventAttendeesPageState();
}

class _EventAttendeesPageState extends State<EventAttendeesPage> {
  String _selectedStatus = 'all';

  String _exportFileName() {
    final safeTitle = (widget.eventTitle ?? 'event_participants')
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9-_ ]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return '${safeTitle.isEmpty ? 'event_participants' : safeTitle}_participants.xlsx';
  }

  static const _statusFilters = [
    _StatusFilter(label: 'All', value: 'all'),
    _StatusFilter(label: 'Registered', value: 'registered'),
    _StatusFilter(label: 'Attended', value: 'attended'),
    _StatusFilter(label: 'Cancelled', value: 'cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAttendees();
    });
  }

  void _fetchAttendees() {
    context.read<EventRegistrationBloc>().add(
      EventRegistrationFetchAttendeesEvent(
        eventId: widget.eventId,
        status: _selectedStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventTitle?.isNotEmpty == true
              ? 'Attendees'
              : 'Event Attendees',
        ),
        actions: [
          FileDownloadOpenButton(
            downloadUrl: '/events/${widget.eventId}/participants/export',
            fileName: _exportFileName(),
            allowRedownload: true,
            subDirectory: 'event_exports',
          ),
        ],
      ),
      body: BlocConsumer<EventRegistrationBloc, EventRegistrationState>(
        listener: (context, state) {
          if (state is EventRegistrationFailure) {
            AppToast.showError(context, state.message);
          }
        },
        buildWhen: (_, state) =>
            state is EventRegistrationInitial ||
            state is EventRegistrationAttendeesLoading ||
            state is EventRegistrationAttendeesLoaded ||
            state is EventRegistrationFailure,
        builder: (context, state) {
          if (state is EventRegistrationAttendeesLoading ||
              state is EventRegistrationInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventRegistrationFailure) {
            return _ErrorState(onRetry: _fetchAttendees);
          }

          if (state is! EventRegistrationAttendeesLoaded) {
            return const SizedBox.shrink();
          }

          final attendees = state.attendees;

          return RefreshIndicator(
            onRefresh: () async {
              _fetchAttendees();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (widget.eventTitle?.trim().isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      widget.eventTitle!.trim(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  attendees.isTeamEvent
                      ? 'Team registrations and member roster'
                      : 'Individual attendee registrations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  summary: attendees.summary,
                  isTeam: attendees.isTeamEvent,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _statusFilters[index];
                      final selected = filter.value == _selectedStatus;

                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        label: Text(filter.label),
                        onSelected: (_) {
                          if (_selectedStatus == filter.value) return;
                          setState(() {
                            _selectedStatus = filter.value;
                          });
                          _fetchAttendees();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (attendees.attendees.isEmpty)
                  const _EmptyState()
                else if (attendees.isTeamEvent)
                  ...attendees.attendees.map(
                    (attendee) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TeamAttendeeCard(
                        attendee: attendee,
                        event: widget.event,
                        eventId: widget.eventId,
                        eventTitle: widget.eventTitle,
                      ),
                    ),
                  )
                else
                  ...attendees.attendees.map(
                    (attendee) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _IndividualAttendeeCard(attendee: attendee),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final EventAttendeesSummary summary;
  final bool isTeam;

  const _SummaryCard({required this.summary, required this.isTeam});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cards = [
      _SummaryItem(
        label: isTeam ? 'Teams' : 'Attendees',
        value: isTeam ? summary.totalTeams : summary.totalAttendees,
      ),
      _SummaryItem(label: 'Registered', value: summary.registered),
      _SummaryItem(label: 'Attended', value: summary.attended),
      _SummaryItem(label: 'Cancelled', value: summary.cancelled),
      if (isTeam) _SummaryItem(label: 'Members', value: summary.totalMembers),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: cards
            .map(
              (item) => Container(
                constraints: const BoxConstraints(minWidth: 90),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.value}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _IndividualAttendeeCard extends StatelessWidget {
  final EventAttendee attendee;

  const _IndividualAttendeeCard({required this.attendee});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const FaIcon(FontAwesomeIcons.user, size: 18),
        title: Text(attendee.user?.displayName ?? 'Unknown attendee'),
        subtitle: Text(_subtitle(attendee)),
        trailing: _StatusPill(status: attendee.registrationStatus),
      ),
    );
  }

  String _subtitle(EventAttendee attendee) {
    final username = attendee.user?.username;
    final registered = attendee.registeredAt;

    final lines = <String>[];
    if (username != null && username.trim().isNotEmpty) {
      lines.add('@${username.trim()}');
    }
    if (registered != null) {
      lines.add(
        'Registered ${DateFormat('dd MMM, h:mm a').format(registered)}',
      );
    }

    return lines.isEmpty ? 'No additional details' : lines.join(' · ');
  }
}

class _TeamAttendeeCard extends StatelessWidget {
  final EventAttendee attendee;
  final Event? event;
  final String eventId;
  final String? eventTitle;

  const _TeamAttendeeCard({
    required this.attendee,
    this.event,
    required this.eventId,
    this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final leaderName = attendee.leader?.displayName ?? 'Unknown leader';

    return InkWell(
      onTap: () {
        final encodedTitle = Uri.encodeComponent(eventTitle ?? '');
        context.push(
          '/team-registration-detail/${attendee.registrationId}?eventId=$eventId&title=$encodedTitle',
          extra: {'attendee': attendee, 'event': event},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    attendee.teamName?.trim().isNotEmpty == true
                        ? attendee.teamName!.trim()
                        : 'Unnamed Team',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusPill(status: attendee.registrationStatus),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Leader: $leaderName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(
              '${attendee.memberCount} member${attendee.memberCount == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (attendee.members.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...attendee.members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.userGroup, size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          member.user?.displayName ?? member.userId,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        member.role,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final colorScheme = Theme.of(context).colorScheme;

    Color background;
    Color foreground;

    switch (lower) {
      case 'attended':
        background = Colors.green.withValues(alpha: 0.14);
        foreground = Colors.green.shade700;
        break;
      case 'cancelled':
        background = colorScheme.errorContainer;
        foreground = colorScheme.onErrorContainer;
        break;
      default:
        background = colorScheme.secondaryContainer;
        foreground = colorScheme.onSecondaryContainer;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        lower,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation, size: 24),
            const SizedBox(height: 10),
            const Text('Unable to load attendees right now.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const FaIcon(FontAwesomeIcons.rotateRight, size: 14),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.userSlash,
            size: 26,
            color: style?.color?.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 10),
          Text(
            'No attendees found for this filter.',
            style: style,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final int value;

  const _SummaryItem({required this.label, required this.value});
}

class _StatusFilter {
  final String label;
  final String value;

  const _StatusFilter({required this.label, required this.value});
}
