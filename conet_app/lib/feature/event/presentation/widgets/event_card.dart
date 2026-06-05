import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventCard extends StatefulWidget {
  final EventListItem event;
  final bool showActionRow;

  const EventCard({super.key, required this.event, this.showActionRow = false});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isSaving = false;
  bool? _optimisticIsBookmarked;
  bool? _bookmarkBeforeSave;

  bool get _displayIsBookmarked =>
      _optimisticIsBookmarked ?? widget.event.isBookmarked;

  @override
  void didUpdateWidget(covariant EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSaving &&
        oldWidget.event.isBookmarked != widget.event.isBookmarked) {
      _optimisticIsBookmarked = null;
      _bookmarkBeforeSave = null;
    }
  }

  void _onSavePressed() {
    if (_isSaving) return;
    setState(() {
      _bookmarkBeforeSave = _displayIsBookmarked;
      _optimisticIsBookmarked = !_displayIsBookmarked;
      _isSaving = true;
    });
    context.read<EventBloc>().add(EventSaveEvent(widget.event.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final dateLabel = DateFormat(
      'MMM d - h:mm a',
    ).format(widget.event.eventStartDate);
    final locationLabel =
        widget.event.venue ?? widget.event.location ?? 'Location TBA';
    final ticketLabel = _ticketLabel(widget.event);
    final indicator = _EventUrgencyIndicator.fromEvent(widget.event, semantic);

    return BlocListener<EventBloc, EventState>(
      listenWhen: (_, current) {
        if (current is EventSaveSuccess) {
          return current.eventId == widget.event.id;
        }
        if (current is EventSaveFailure) {
          return current.eventId == widget.event.id;
        }
        return false;
      },
      listener: (_, state) {
        if (!_isSaving || !mounted) return;

        setState(() {
          _isSaving = false;

          if (state is EventSaveFailure) {
            _optimisticIsBookmarked = _bookmarkBeforeSave;
          }

          _bookmarkBeforeSave = null;
        });
      },
      child: Card(
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
            context.push('/event-detail/${widget.event.id}');
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
                                  widget.event.category,
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
                            widget.event.title,
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
                if (widget.showActionRow) ...[
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
                        icon: _displayIsBookmarked
                            ? FontAwesomeIcons.solidBookmark
                            : FontAwesomeIcons.bookmark,
                        onTap: _isSaving ? null : _onSavePressed,
                        isLoading: _isSaving,
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () =>
                            context.push('/event-detail/${widget.event.id}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
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
                        icon: _displayIsBookmarked
                            ? FontAwesomeIcons.solidBookmark
                            : FontAwesomeIcons.bookmark,
                        onTap: _isSaving ? null : _onSavePressed,
                        isLoading: _isSaving,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverImage(ColorScheme colorScheme) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: 96,
      height: 96,
      child: widget.event.eventImageUrl != null
          ? Image.network(
              widget.event.eventImageUrl!,
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
    required FaIconData icon,
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
    required FaIconData icon,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outlineVariant),
            color: colorScheme.surface,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : FaIcon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          ),
        ),
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
  final FaIconData icon;
  final String text;
  final Color color;

  const _EventUrgencyIndicator({
    required this.icon,
    required this.text,
    required this.color,
  });

  factory _EventUrgencyIndicator.fromEvent(
    EventListItem event,
    AppSemanticColors semantic,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      event.eventStartDate.year,
      event.eventStartDate.month,
      event.eventStartDate.day,
    );
    final daysLeft = eventDay.difference(today).inDays;

    // Priority 1: time urgency - use warning color for time-sensitive events
    if (daysLeft >= 0 && daysLeft <= 3) {
      return _EventUrgencyIndicator(
        icon: FontAwesomeIcons.circleExclamation,
        text: 'Only $daysLeft days left',
        color: semantic.textWarning,
      );
    }

    final maxParticipant = event.maxParticipant;
    final canComputeSpots = maxParticipant != null && maxParticipant > 0;
    if (canComputeSpots) {
      final spotsLeft = maxParticipant - event.registrationCount;

      // Priority 2: spots urgency - use info/primary color
      if (spotsLeft >= 0 && spotsLeft < 50) {
        return _EventUrgencyIndicator(
          icon: FontAwesomeIcons.users,
          text: '$spotsLeft spots left',
          color: semantic.textInfo,
        );
      }
    }

    // Priority 3: default attendance - use secondary color
    return _EventUrgencyIndicator(
      icon: FontAwesomeIcons.users,
      text: '${event.registrationCount}+ attending',
      color: semantic.iconSecondary,
    );
  }
}
