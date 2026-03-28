import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final EventListItem event;
  final bool showActionRow;

  const EventCard({super.key, required this.event, this.showActionRow = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = DateFormat('MMM d - h:mm a').format(event.eventStartDate);
    final locationLabel = event.venue ?? event.location ?? 'Location TBA';
    final ticketLabel = _ticketLabel(event);
    final indicator = _EventUrgencyIndicator.fromEvent(event);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: .5),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/event-detail/${event.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _coverImage(colorScheme),
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
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event.category,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              ticketLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        _metaLine(
                          theme: theme,
                          colorScheme: colorScheme,
                          icon: FontAwesomeIcons.calendarDay,
                          text: dateLabel,
                        ),
                        const SizedBox(height: 3),
                        _metaLine(
                          theme: theme,
                          colorScheme: colorScheme,
                          icon: FontAwesomeIcons.locationDot,
                          text: locationLabel,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showActionRow) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    FaIcon(indicator.icon, size: 12, color: indicator.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        indicator.text,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: indicator.color,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _iconActionButton(
                      colorScheme: colorScheme,
                      icon: FontAwesomeIcons.bookmark,
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          context.push('/event-detail/${event.id}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1D2939),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(96, 40),
                        shape: const StadiumBorder(),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: .45),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FaIcon(indicator.icon, size: 12, color: indicator.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        indicator.text,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: indicator.color,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _iconActionButton(
                      colorScheme: colorScheme,
                      icon: FontAwesomeIcons.bookmark,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverImage(ColorScheme colorScheme) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: 82,
      height: 82,
      child: event.eventImageUrl != null
          ? Image.network(
              event.eventImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _coverPlaceholder(colorScheme),
            )
          : _coverPlaceholder(colorScheme),
    ),
  );

  Widget _coverPlaceholder(ColorScheme colorScheme) => Container(
    color: colorScheme.surfaceContainerHighest,
    child: Center(
      child: FaIcon(
        FontAwesomeIcons.calendar,
        size: 24,
        color: colorScheme.outlineVariant,
      ),
    ),
  );

  Widget _metaLine({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        FaIcon(icon, size: 11, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _iconActionButton({
    required ColorScheme colorScheme,
    required IconData icon,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surface,
      ),
      child: Center(
        child: FaIcon(icon, size: 14, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  String _ticketLabel(EventListItem item) {
    if (!item.isPaid) return 'FREE';
    if (item.price == null) return 'PAID';

    final priceNumber = item.price!;
    if (priceNumber == priceNumber.roundToDouble()) {
      return '\u20B9${priceNumber.toInt()}';
    }
    return '\u20B9${priceNumber.toStringAsFixed(2)}';
  }
}

class _EventUrgencyIndicator {
  final IconData icon;
  final String text;
  final Color color;

  const _EventUrgencyIndicator({
    required this.icon,
    required this.text,
    required this.color,
  });

  static const Color _timeUrgencyColor = Color(0xFFF97316);
  static const Color _spotsUrgencyColor = Color(0xFF344054);
  static const Color _attendanceColor = Color(0xFF98A2B3);

  factory _EventUrgencyIndicator.fromEvent(EventListItem event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      event.eventStartDate.year,
      event.eventStartDate.month,
      event.eventStartDate.day,
    );
    final daysLeft = eventDay.difference(today).inDays;

    // Priority 1: time urgency
    if (daysLeft >= 0 && daysLeft <= 3) {
      return _EventUrgencyIndicator(
        icon: FontAwesomeIcons.circleExclamation,
        text: 'Only $daysLeft days left',
        color: _timeUrgencyColor,
      );
    }

    final maxParticipant = event.maxParticipant;
    final canComputeSpots = maxParticipant != null && maxParticipant > 0;
    if (canComputeSpots) {
      final spotsLeft = maxParticipant - event.registrationCount;

      // Priority 2: spots urgency
      if (spotsLeft >= 0 && spotsLeft < 50) {
        return _EventUrgencyIndicator(
          icon: FontAwesomeIcons.users,
          text: '$spotsLeft spots left',
          color: _spotsUrgencyColor,
        );
      }
    }

    // Priority 3: default attendance
    return _EventUrgencyIndicator(
      icon: FontAwesomeIcons.users,
      text: '${event.registrationCount}+ attending',
      color: _attendanceColor,
    );
  }
}
