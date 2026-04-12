import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/utils/quill_content_utils.dart';
import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/core/widgets/quill_read_only_view.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_activity.dart';
import 'package:conet_app/feature/event/domain/entities/event_faq.dart';
import 'package:conet_app/feature/event/domain/entities/event_prize.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/event/presentation/pages/event_registration_page.dart';
import 'package:conet_app/feature/payment/domain/entities/payment_initiate_response.dart';
import 'package:conet_app/feature/payment/presentation/bloc/payment_bloc.dart';
import 'package:conet_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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
  String? _pendingPaymentRegistrationId;
  bool _isInitiatePaymentPending = false;
  bool _isRollbackInFlight = false;
  late final Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventBloc>().add(EventFetchByIdEvent(widget.eventId));
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _onRegisterPressed(Event event) async {
    final payload = await Navigator.of(context).push<EventRegistrationPayload>(
      MaterialPageRoute(builder: (_) => EventRegistrationPage(event: event)),
    );

    if (!mounted || payload == null) return;

    context.read<EventBloc>().add(EventRegisterEvent(event.id, payload));
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    _pendingPaymentRegistrationId = null;
    _isInitiatePaymentPending = false;
    _isRollbackInFlight = false;
    AppToast.showSuccess(context, 'Payment completed successfully');
    context.read<EventBloc>().add(EventFetchByIdEvent(widget.eventId));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    final message = (response.message ?? 'Payment failed').trim();
    _triggerRegistrationRollback(
      reason: 'payment_failed',
      failureMessage: message.isEmpty ? 'Payment failed' : message,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    final wallet = (response.walletName ?? '').trim();
    if (wallet.isEmpty) return;
    AppToast.showSuccess(context, 'Continue payment in $wallet');
  }

  void _openRazorpayCheckout(PaymentInitiateResponse payment) {
    final razorpayKey = (dotenv.env['RAZORPAY_KEY_ID'] ?? '').trim();
    if (razorpayKey.isEmpty) {
      _triggerRegistrationRollback(
        reason: 'checkout_not_opened_missing_key',
        failureMessage: 'RAZORPAY_KEY_ID is missing in .env',
      );
      return;
    }

    final event = _event;
    if (event == null) {
      _triggerRegistrationRollback(
        reason: 'checkout_not_opened_event_missing',
        failureMessage: 'Event details not available for checkout',
      );
      return;
    }

    final appUserState = context.read<AppUserCubit>().state;
    String? email;
    String? contact;
    String fullName = 'Conet User';

    if (appUserState is AppUserAuthenticated) {
      final user = appUserState.user;
      email = user.email.trim();
      contact = user.phone?.trim();
      final name = '${user.firstName} ${user.lastName}'.trim();
      if (name.isNotEmpty) {
        fullName = name;
      } else if (user.username.trim().isNotEmpty) {
        fullName = user.username.trim();
      }
    }

    final imageUrl = event.eventImageUrl?.trim();
    logger.d(
      'Opening Razorpay checkout with options: key=$razorpayKey, order_id=${payment.razorpayOrderId}, amount=${payment.amount}, currency=${payment.currency}, name=${event.title}, description=Event registration payment, image=$imageUrl, prefill_name=$fullName, prefill_email=$email, prefill_contact=$contact, notes_event_id=${event.id}, notes_payment_id=${payment.paymentId}',
    );
    final options = <String, dynamic>{
      'key': razorpayKey,
      'order_id': payment.razorpayOrderId,
      'amount': (payment.amount * 100).round(),
      'currency': payment.currency,
      'name': event.title,
      'description': 'Event registration payment',
      if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
      'prefill': {
        'name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (contact != null && contact.isNotEmpty) 'contact': contact,
      },
      'notes': {'event_id': event.id, 'payment_id': payment.paymentId},
      'theme': {'color': '#0A7EA4'},
    };

    try {
      _razorpay.open(options);
    } catch (_) {
      _triggerRegistrationRollback(
        reason: 'checkout_open_exception',
        failureMessage: 'Unable to open Razorpay checkout',
      );
    }
  }

  void _triggerRegistrationRollback({
    required String reason,
    String? failureMessage,
  }) {
    if (!mounted) return;

    final registrationId = _pendingPaymentRegistrationId?.trim();
    if (registrationId == null || registrationId.isEmpty) {
      return;
    }

    if (_isRollbackInFlight) return;

    _isInitiatePaymentPending = false;
    _isRollbackInFlight = true;
    context.read<PaymentBloc>().add(
      PaymentRevertRegistrationEvent(registrationId, reason: reason),
    );
  }

  bool _shouldRollbackOnInitiateFailure(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    if (normalized.contains('payment already completed')) return false;
    if (normalized.contains('event is not a paid event')) return false;
    if (normalized.contains('registration not found')) return false;
    if (normalized.contains('unauthorized')) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MultiBlocListener(
      listeners: [
        BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentInitiateSuccess) {
              _isInitiatePaymentPending = false;
              _openRazorpayCheckout(state.response);
            } else if (state is PaymentRevertRegistrationSuccess) {
              _pendingPaymentRegistrationId = null;
              _isInitiatePaymentPending = false;
              _isRollbackInFlight = false;
              AppToast.showError(
                context,
                'Payment failed. Registration has been reverted.',
              );
              context.read<EventBloc>().add(
                EventFetchByIdEvent(widget.eventId),
              );
            } else if (state is PaymentFailure) {
              if (_isInitiatePaymentPending) {
                if (_shouldRollbackOnInitiateFailure(state.message)) {
                  _triggerRegistrationRollback(
                    reason: 'payment_initiation_failed',
                    failureMessage: state.message,
                  );
                  return;
                }

                _isInitiatePaymentPending = false;
                _isRollbackInFlight = false;

                final normalized = state.message.trim().toLowerCase();
                if (normalized.contains('event is not a paid event')) {
                  _pendingPaymentRegistrationId = null;
                  AppToast.showSuccess(
                    context,
                    'Registered successfully (payment not required).',
                  );
                  context.read<EventBloc>().add(
                    EventFetchByIdEvent(widget.eventId),
                  );
                  return;
                }

                if (normalized.contains('payment already completed')) {
                  _pendingPaymentRegistrationId = null;
                  AppToast.showSuccess(context, 'Payment already completed.');
                  context.read<EventBloc>().add(
                    EventFetchByIdEvent(widget.eventId),
                  );
                  return;
                }

                AppToast.showError(context, state.message);
                return;
              }

              if (_isRollbackInFlight) {
                _isRollbackInFlight = false;
                AppToast.showError(
                  context,
                  'Payment failed and registration rollback failed: ${state.message}',
                );
                return;
              }

              AppToast.showError(context, state.message);
            }
          },
        ),
      ],
      child: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventDetailLoaded) {
            setState(() {
              _event = state.event;
            });
          }

          if (state is EventRegistrationSuccess) {
            setState(() {
              _event = state.response.event;
            });

            if (_event?.isPaid == true) {
              // Wait for payment initiate API
              _pendingPaymentRegistrationId = state.response.registrationId;
              _isInitiatePaymentPending = true;
              _isRollbackInFlight = false;
              context.read<PaymentBloc>().add(
                PaymentInitiateEvent(state.response.registrationId),
              );
            } else {
              _pendingPaymentRegistrationId = null;
              _isInitiatePaymentPending = false;
              _isRollbackInFlight = false;
              AppToast.showSuccess(context, 'Registered successfully');
            }
          }

          if (state is EventRegistrationFailure) {
            AppToast.showError(context, state.message);
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
                              colorScheme.onSurface,
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
              loading: isRegistering,
              onRegister: () {
                _onRegisterPressed(event);
              },
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCard(event: event),
                  const SizedBox(height: 16),
                  _AboutSection(event: event),
                  if (event.activities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _ScheduleSection(activities: event.activities),
                  ],
                  if (event.prizes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _PrizeSection(prizes: event.prizes),
                  ],
                  const SizedBox(height: 20),
                  _OrganizerSection(event: event),
                  if ((event.eligibility ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _EligibilitySection(eligibility: event.eligibility!.trim()),
                  ],
                  if (event.faqs.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _FaqSection(
                      faqs: event.faqs,
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
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.isRegistered
                          ? 'You are registered for this event.'
                          : 'Register to secure your participation.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Event event;

  const _HeaderCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateLabel = DateFormat('MMM d').format(event.eventDate);
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: event.eventImageUrl != null
                        ? Image.network(
                            event.eventImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _imageFallback(colorScheme),
                          )
                        : _imageFallback(colorScheme),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryChip(category: event.category),
                      const SizedBox(height: 8),
                      Text(
                        event.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoTile(
              icon: FontAwesomeIcons.calendarDay,
              title: dateLabel,
              subtitle: timeLabel,
            ),
            _InfoTile(
              icon: FontAwesomeIcons.locationDot,
              title: locationLabel,
              subtitle: event.locationType == 'ONLINE'
                  ? 'Online event'
                  : 'Offline event',
            ),
            _InfoTile(
              icon: FontAwesomeIcons.userGroup,
              title: '${event.registrationCount} Registered',
              subtitle: remaining == null
                  ? 'Unlimited spots'
                  : '$remaining spots remaining',
            ),
            if (teamSizeText != null)
              _InfoTile(
                icon: FontAwesomeIcons.users,
                title: 'Team Size',
                subtitle: teamSizeText,
              ),
            _InfoTile(
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

  Widget _imageFallback(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.calendar,
          size: 30,
          color: colorScheme.outline,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
        style: theme.textTheme.labelSmall?.copyWith(
          letterSpacing: 0.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(
                icon,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

  const _AboutSection({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aboutDelta = event.about ?? '';
    final aboutText = quillPlainTextFromString(aboutDelta);

    if (aboutText.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About ${event.title}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        QuillReadOnlyView(deltaJson: aboutDelta),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final List<EventActivity> activities;

  const _ScheduleSection({required this.activities});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Schedule',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...activities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle, size: 6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatClock(activity.activityTime),
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activity.activityTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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

class _PrizeSection extends StatelessWidget {
  final List<EventPrize> prizes;

  const _PrizeSection({required this.prizes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prizes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...prizes.map(
          (prize) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.award, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prize.position, style: theme.textTheme.bodyMedium),
                      Text(
                        prize.prize,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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

  const _OrganizerSection({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final organizer = event.organizer;

    final organizerName = organizer == null
        ? 'Organizer'
        : '${organizer.firstName} ${organizer.lastName}'.trim().isEmpty
        ? organizer.username
        : '${organizer.firstName} ${organizer.lastName}'.trim();
    final canOpenProfile =
        context.read<AppUserCubit>().state is AppUserAuthenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organizer',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
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
                      backgroundColor: colorScheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      organizerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (event.cohosts.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: event.cohosts.take(5).map((cohost) {
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
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EligibilitySection extends StatelessWidget {
  final String eligibility;

  const _EligibilitySection({required this.eligibility});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eligibility',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.25),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(eligibility, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _FaqSection extends StatelessWidget {
  final List<EventFaq> faqs;
  final int? expandedFaqIndex;
  final ValueChanged<int> onToggle;

  const _FaqSection({
    required this.faqs,
    required this.expandedFaqIndex,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...faqs.asMap().entries.map((entry) {
          final index = entry.key;
          final faq = entry.value;
          final expanded = expandedFaqIndex == index;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              initiallyExpanded: expanded,
              onExpansionChanged: (_) => onToggle(index),
              title: Text(
                faq.question,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(faq.answer, style: theme.textTheme.bodyMedium),
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
  final VoidCallback onRegister;

  const _RegisterBar({
    required this.event,
    required this.loading,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRegister =
        !loading && !event.isRegistered && event.eventStatus == 'published';

    final buttonLabel = event.isRegistered
        ? 'Registered'
        : event.eventStatus != 'published'
        ? 'Unavailable'
        : 'Register Now';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                event.isPaid ? _formatPrice(event.price) : 'Free',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: canRegister ? onRegister : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: loading
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
