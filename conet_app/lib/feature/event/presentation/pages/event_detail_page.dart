import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/utils/quill_content_utils.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/core/widgets/quill_read_only_view.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_activity.dart';
import 'package:conet_app/feature/event/domain/entities/event_cohost.dart';
import 'package:conet_app/feature/event/domain/entities/event_faq.dart';
import 'package:conet_app/feature/event/domain/entities/event_prize.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/event/presentation/pages/event_registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Event? _event;
  int? _expandedFaqIndex;
  bool _isSaveInFlight = false;
  bool? _bookmarkBeforeSave;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventBloc>().add(EventFetchByIdEvent(widget.eventId));
    });
  }

  Future<void> _onRegisterPressed(Event event) async {
    final didCompleteRegistration = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventRegistrationPage(event: event)),
    );

    if (!mounted) return;
    if (didCompleteRegistration == true) {
      context.read<EventBloc>().add(EventFetchByIdEvent(widget.eventId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return BlocConsumer<EventBloc, EventState>(
      listener: (context, state) {
        if (state is EventDetailLoaded) {
          setState(() {
            _event = state.event;
          });
        }

        if (state is EventSaveFailure) {
          if (state.eventId == widget.eventId) {
            setState(() {
              _isSaveInFlight = false;
              if (_event != null && _bookmarkBeforeSave != null) {
                _event = _event!.copyWith(isBookmarked: _bookmarkBeforeSave);
              }
              _bookmarkBeforeSave = null;
            });
            AppToast.showError(context, state.message);
          }
        }

        if (state is EventSaveSuccess && state.eventId == widget.eventId) {
          setState(() {
            _isSaveInFlight = false;
            _bookmarkBeforeSave = null;
          });
        }

        if (state is EventDetailFailure) {
          AppToast.showError(context, state.message);
        }
      },
      builder: (context, state) {
        if (_event == null &&
            (state is EventDetailLoading || state is EventInitial)) {
          return const Scaffold(body: Center(child: Loader()));
        }

        if (_event == null && state is EventDetailFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Event')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      context.read<EventBloc>().add(
                        EventFetchByIdEvent(widget.eventId),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final event = _event;
        if (event == null) {
          return const Scaffold(body: Center(child: Loader()));
        }

        final appUserState = context.read<AppUserCubit>().state;
        final currentUserId = appUserState is AppUserAuthenticated
            ? appUserState.user.id
            : null;
        final isOrganizerOrCohost =
            currentUserId != null &&
            (event.organizerId == currentUserId ||
                event.cohosts.any(
                  (cohost) => cohost.userId.trim() == currentUserId,
                ));

        final isRegistering = state is EventRegistrationLoading;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 18),
              ),
              IconButton(
                onPressed: _isSaveInFlight
                    ? null
                    : () {
                        final currentEvent = _event;
                        if (currentEvent == null) return;

                        setState(() {
                          _bookmarkBeforeSave = currentEvent.isBookmarked;
                          _event = currentEvent.copyWith(
                            isBookmarked: !currentEvent.isBookmarked,
                          );
                          _isSaveInFlight = true;
                        });
                        context.read<EventBloc>().add(
                          EventSaveEvent(currentEvent.id),
                        );
                      },
                icon: _isSaveInFlight
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            semantic.iconPrimary,
                          ),
                        ),
                      )
                    : FaIcon(
                        event.isBookmarked
                            ? FontAwesomeIcons.solidBookmark
                            : FontAwesomeIcons.bookmark,
                        size: 18,
                      ),
              ),
            ],
          ),
          bottomNavigationBar: _RegisterBar(
            event: event,
            semantic: semantic,
            loading: isRegistering,
            showDashboardAction: isOrganizerOrCohost,
            onRegister: () {
              _onRegisterPressed(event);
            },
            onGoToDashboard: () {
              context.push('/event-dashboard');
            },
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s16,
              AppSpace.s12,
              AppSpace.s16,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(event: event, semantic: semantic),
                const SizedBox(height: AppSpace.s16),
                _AboutSection(event: event, semantic: semantic),
                if (event.activities.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s20),
                  _ScheduleSection(
                    activities: event.activities,
                    semantic: semantic,
                  ),
                ],
                if (event.prizes.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s20),
                  _PrizeSection(prizes: event.prizes, semantic: semantic),
                ],
                const SizedBox(height: AppSpace.s20),
                _OrganizerSection(event: event, semantic: semantic),
                if ((event.instructions ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s20),
                  _InstructionsSection(
                    instructions: event.instructions!.trim(),
                    semantic: semantic,
                  ),
                ],
                if ((event.eligibility ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s20),
                  _EligibilitySection(
                    eligibility: event.eligibility!.trim(),
                    semantic: semantic,
                  ),
                ],
                if (event.faqs.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s20),
                  _FaqSection(
                    faqs: event.faqs,
                    semantic: semantic,
                    expandedFaqIndex: _expandedFaqIndex,
                    onToggle: (index) {
                      setState(() {
                        _expandedFaqIndex = _expandedFaqIndex == index
                            ? null
                            : index;
                      });
                    },
                  ),
                ],
                const SizedBox(height: AppSpace.s20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpace.s12),
                  decoration: BoxDecoration(
                    color: semantic.surfaceRaised,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Text(
                    event.isRegistered
                        ? 'You are registered for this event.'
                        : 'Register to secure your participation.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: semantic.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Event event;
  final AppSemanticColors semantic;

  const _HeaderCard({required this.event, required this.semantic});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d').format(event.startDate);
    final timeLabel =
        '${_formatClock(event.startTime)} - ${_formatClock(event.endTime)}';
    final locationLabel = event.venue ?? event.location ?? 'Location TBA';

    final remaining = event.maxParticipant > -1
        ? (event.maxParticipant - event.registrationCount).clamp(
            0,
            event.maxParticipant,
          )
        : null;

    final teamSizeText = _teamSizeLabel(event);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: semantic.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: event.eventImageUrl != null
                        ? Image.network(
                            event.eventImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _imageFallback(semantic),
                          )
                        : _imageFallback(semantic),
                  ),
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryChip(
                        category: event.category,
                        semantic: semantic,
                      ),
                      const SizedBox(height: AppSpace.s8),
                      Text(
                        event.title,
                        style: AppTextStyles.headingH3.copyWith(
                          color: semantic.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s12),
            _InfoTile(
              semantic: semantic,
              icon: FontAwesomeIcons.calendarDay,
              title: dateLabel,
              subtitle: timeLabel,
            ),
            _InfoTile(
              semantic: semantic,
              icon: FontAwesomeIcons.locationDot,
              title: locationLabel,
              subtitle: event.locationType == 'ONLINE'
                  ? 'Online event'
                  : 'Offline event',
            ),
            _InfoTile(
              semantic: semantic,
              icon: FontAwesomeIcons.userGroup,
              title: '${event.registrationCount} Registered',
              subtitle: remaining == null
                  ? 'Unlimited spots'
                  : '$remaining spots remaining',
            ),
            if (teamSizeText != null)
              _InfoTile(
                semantic: semantic,
                icon: FontAwesomeIcons.users,
                title: 'Team Size',
                subtitle: teamSizeText,
              ),
            _InfoTile(
              semantic: semantic,
              icon: FontAwesomeIcons.indianRupeeSign,
              title: event.isPaid ? _formatPrice(event.price) : 'Free',
              subtitle: event.isPaid
                  ? 'Registration fee applies'
                  : 'No registration fee',
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(AppSemanticColors semantic) {
    return Container(
      color: semantic.surfaceRaised,
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.calendar,
          size: 30,
          color: semantic.iconTertiary,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final AppSemanticColors semantic;

  const _CategoryChip({required this.category, required this.semantic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: semantic.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 0.2,
          fontWeight: FontWeight.w700,
          color: semantic.textPrimary,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AppSemanticColors semantic;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: semantic.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(icon, size: 14, color: semantic.iconTertiary),
            ),
          ),
          const SizedBox(width: AppSpace.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: semantic.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: semantic.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final Event event;
  final AppSemanticColors semantic;

  const _AboutSection({required this.event, required this.semantic});

  @override
  Widget build(BuildContext context) {
    final aboutDelta = event.about ?? '';
    final aboutText = quillPlainTextFromString(aboutDelta);

    if (aboutText.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About ${event.title}',
          style: AppTextStyles.headingH3.copyWith(color: semantic.textPrimary),
        ),
        const SizedBox(height: AppSpace.s8),
        QuillReadOnlyView(deltaJson: aboutDelta),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final List<EventActivity> activities;
  final AppSemanticColors semantic;

  const _ScheduleSection({required this.activities, required this.semantic});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Schedule',
          style: AppTextStyles.headingH3.copyWith(color: semantic.textPrimary),
        ),
        const SizedBox(height: AppSpace.s10),
        ...activities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.s8),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: semantic.iconPrimary,
                  ),
                ),
                const SizedBox(width: AppSpace.s10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatClock(activity.activityTime),
                        style: AppTextStyles.caption.copyWith(
                          color: semantic.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        activity.activityTitle,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: semantic.textPrimary,
                        ),
                      ),
                      if (activity.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.s6),
                        Text(
                          activity.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: semantic.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrizeSection extends StatelessWidget {
  final List<EventPrize> prizes;
  final AppSemanticColors semantic;

  const _PrizeSection({required this.prizes, required this.semantic});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prizes',
          style: AppTextStyles.headingH3.copyWith(color: semantic.textPrimary),
        ),
        const SizedBox(height: AppSpace.s10),
        ...prizes.map(
          (prize) => Container(
            margin: const EdgeInsets.only(bottom: AppSpace.s10),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s12,
              vertical: AppSpace.s10,
            ),
            decoration: BoxDecoration(
              color: semantic.surfaceRaised,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.award,
                  size: 16,
                  color: semantic.iconPrimary,
                ),
                const SizedBox(width: AppSpace.s10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prize.position,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: semantic.textSecondary,
                        ),
                      ),
                      Text(
                        prize.prize,
                        style: AppTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: semantic.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrganizerSection extends StatelessWidget {
  final Event event;
  final AppSemanticColors semantic;

  const _OrganizerSection({required this.event, required this.semantic});

  void _showAllCohosts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) =>
          _CoHostsListBottomSheet(cohosts: event.cohosts, semantic: semantic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final organizer = event.organizer;

    final organizerName = organizer == null
        ? 'Organizer'
        : '${organizer.firstName} ${organizer.lastName}'.trim().isEmpty
        ? organizer.username
        : '${organizer.firstName} ${organizer.lastName}'.trim();
    final canOpenProfile =
        context.read<AppUserCubit>().state is AppUserAuthenticated;

    final displayedCohosts = event.cohosts.take(3).toList();
    final hasMoreCohosts = event.cohosts.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organizer',
          style: AppTextStyles.headingH3.copyWith(color: semantic.textPrimary),
        ),
        const SizedBox(height: AppSpace.s10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.s12),
          decoration: BoxDecoration(
            border: Border.all(color: semantic.borderDefault),
            borderRadius: AppRadius.mdAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap:
                        context.read<AppUserCubit>().state
                            is AppUserAuthenticated
                        ? () {
                            final userId = organizer?.id;
                            if (userId != null) {
                              context.push('/user-profile', extra: userId);
                            }
                          }
                        : null,
                    child: CustomCircleAvatar(
                      size: CustomCircleAvatarSize.small,
                      imageUrl: organizer?.profilePicUrl,
                      displayName: organizerName,
                      userId: organizer?.id,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organizerName,
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w700,
                            color: semantic.textPrimary,
                          ),
                        ),
                        if (event.cohosts.isNotEmpty)
                          Text(
                            'Event organizer',
                            style: AppTextStyles.caption.copyWith(
                              color: semantic.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (event.cohosts.isNotEmpty) ...[
                const SizedBox(height: AppSpace.s12),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: AppSpace.s6,
                        runSpacing: AppSpace.s6,
                        children: displayedCohosts.map((cohost) {
                          final cohostUserId = cohost.userId.trim();

                          return InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: canOpenProfile && cohostUserId.isNotEmpty
                                ? () {
                                    context.push(
                                      '/user-profile',
                                      extra: cohostUserId,
                                    );
                                  }
                                : null,
                            child: Chip(
                              avatar: CustomCircleAvatar(
                                size: CustomCircleAvatarSize.small,
                                imageUrl: cohost.profilePicUrl,
                                displayName: cohost.displayName,
                                userId: cohostUserId,
                              ),
                              label: Text(cohost.displayName),
                              visualDensity: VisualDensity.compact,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (hasMoreCohosts)
                      GestureDetector(
                        onTap: () => _showAllCohosts(context),
                        child: Padding(
                          padding: const EdgeInsets.only(left: AppSpace.s8),
                          child: Text(
                            '+${event.cohosts.length - 3} more',
                            style: AppTextStyles.label.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CoHostsListBottomSheet extends StatelessWidget {
  final List<EventCohost> cohosts;
  final AppSemanticColors semantic;

  const _CoHostsListBottomSheet({
    required this.cohosts,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    final canOpenProfile =
        context.read<AppUserCubit>().state is AppUserAuthenticated;

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s16,
              AppSpace.s16,
              AppSpace.s16,
              AppSpace.s12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Co-Organizers',
                  style: AppTextStyles.headingH3.copyWith(
                    color: semantic.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: semantic.iconPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s16,
                0,
                AppSpace.s16,
                AppSpace.s16,
              ),
              itemCount: cohosts.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpace.s12),
              itemBuilder: (context, index) {
                final cohost = cohosts[index];
                final cohostUserId = cohost.userId.trim();

                return GestureDetector(
                  onTap: canOpenProfile && cohostUserId.isNotEmpty
                      ? () {
                          Navigator.pop(context);
                          context.push('/user-profile', extra: cohostUserId);
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpace.s12),
                    decoration: BoxDecoration(
                      color: semantic.surfaceRaised,
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: semantic.borderDefault),
                    ),
                    child: Row(
                      children: [
                        CustomCircleAvatar(
                          size: CustomCircleAvatarSize.small,
                          imageUrl: cohost.profilePicUrl,
                          displayName: cohost.displayName,
                          userId: cohostUserId,
                        ),
                        const SizedBox(width: AppSpace.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cohost.displayName,
                                style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: semantic.textPrimary,
                                ),
                              ),
                              if (cohostUserId.isNotEmpty)
                                Text(
                                  '@$cohostUserId',
                                  style: AppTextStyles.caption.copyWith(
                                    color: semantic.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (canOpenProfile && cohostUserId.isNotEmpty)
                          Icon(
                            Icons.chevron_right,
                            color: semantic.iconSecondary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionsSection extends StatelessWidget {
  final String instructions;
  final AppSemanticColors semantic;

  const _InstructionsSection({
    required this.instructions,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCalloutSection(
      title: 'Instructions',
      content: instructions,
      semantic: semantic,
    );
  }
}

class _EligibilitySection extends StatelessWidget {
  final String eligibility;
  final AppSemanticColors semantic;

  const _EligibilitySection({
    required this.eligibility,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCalloutSection(
      title: 'Eligibility',
      content: eligibility,
      semantic: semantic,
    );
  }
}

class _InfoCalloutSection extends StatelessWidget {
  final String title;
  final String content;
  final AppSemanticColors semantic;

  const _InfoCalloutSection({
    required this.title,
    required this.content,
    required this.semantic,
  });

  List<String> _contentItems() {
    return content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map(_stripBulletPrefix)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  String _stripBulletPrefix(String line) {
    return line.replaceFirst(RegExp(r'^[•\-–—]+\s*'), '').trim();
  }

  Widget _buildBulletItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s8, left: AppSpace.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: semantic.iconInfo,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: Text(
              item,
              style: AppTextStyles.bodyDefault.copyWith(
                color: semantic.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _contentItems();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpace.s16,
        horizontal: AppSpace.s12,
      ),
      decoration: BoxDecoration(
        color: semantic.backgroundInfo,
        border: Border.all(color: semantic.borderInfo),
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: semantic.backgroundPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: semantic.iconInfo,
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headingH3.copyWith(
                    color: semantic.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          if (items.isEmpty)
            Text(
              content.trim(),
              style: AppTextStyles.bodyDefault.copyWith(
                color: semantic.textPrimary,
                height: 1.45,
              ),
            )
          else
            ...items.map(_buildBulletItem),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final List<EventFaq> faqs;
  final int? expandedFaqIndex;
  final ValueChanged<int> onToggle;
  final AppSemanticColors semantic;

  const _FaqSection({
    required this.faqs,
    required this.expandedFaqIndex,
    required this.onToggle,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: AppTextStyles.headingH3.copyWith(color: semantic.textPrimary),
        ),
        const SizedBox(height: AppSpace.s10),
        ...faqs.asMap().entries.map((entry) {
          final index = entry.key;
          final faq = entry.value;
          final expanded = expandedFaqIndex == index;

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpace.s8),
            child: ExpansionTile(
              initiallyExpanded: expanded,
              onExpansionChanged: (_) => onToggle(index),
              title: Text(
                faq.question,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: semantic.textPrimary,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s16,
                    0,
                    AppSpace.s16,
                    AppSpace.s12,
                  ),
                  child: Text(
                    faq.answer,
                    style: AppTextStyles.bodyDefault.copyWith(
                      color: semantic.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _RegisterBar extends StatelessWidget {
  final Event event;
  final bool loading;
  final bool showDashboardAction;
  final AppSemanticColors semantic;
  final VoidCallback onRegister;
  final VoidCallback onGoToDashboard;

  const _RegisterBar({
    required this.event,
    required this.loading,
    required this.showDashboardAction,
    required this.semantic,
    required this.onRegister,
    required this.onGoToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final canRegister =
        !showDashboardAction &&
        !loading &&
        !event.isRegistered &&
        event.eventStatus == 'published';

    final buttonLabel = showDashboardAction
        ? 'Go to Dashboard'
        : event.isRegistered
        ? 'Registered'
        : event.eventStatus != 'published'
        ? 'Unavailable'
        : 'Register Now';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s12,
          AppSpace.s8,
          AppSpace.s12,
          AppSpace.s12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: semantic.borderDefault)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s12,
                vertical: AppSpace.s12,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdAll,
                color: semantic.surfaceRaised,
              ),
              child: Text(
                event.isPaid ? _formatPrice(event.price) : 'Free',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w800,
                  color: semantic.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s10),
            Expanded(
              child: FilledButton(
                onPressed: showDashboardAction
                    ? onGoToDashboard
                    : (canRegister ? onRegister : null),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
                ),
                child: (!showDashboardAction && loading)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatClock(DateTime time) {
  return DateFormat('h:mm a').format(time.toUtc());
}

String _formatPrice(double? price) {
  if (price == null) return 'Free';
  final number = price % 1 == 0
      ? price.toInt().toString()
      : price.toStringAsFixed(2);
  return 'Rs $number';
}

String? _teamSizeLabel(Event event) {
  if (event.participationType != 'team') {
    return null;
  }

  final min = event.minTeamSize;
  final max = event.maxTeamSize;

  if (min == null && max == null) return null;
  if (min != null && max != null) return '$min-$max members';
  if (min != null) return 'Minimum $min members';
  return 'Up to $max members';
}
