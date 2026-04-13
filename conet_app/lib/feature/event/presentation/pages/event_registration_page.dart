import 'package:cached_network_image/cached_network_image.dart';
import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/utils/media_cache_manager.dart';
import 'package:conet_app/core/widgets/user_selector_bottom_sheet.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_custom_field.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/message/domain/usecases/message_search_users.dart';
import 'package:conet_app/feature/message/presentation/pages/image_viewer_page.dart';
import 'package:conet_app/feature/payment/domain/entities/payment_initiate_response.dart';
import 'package:conet_app/feature/payment/presentation/bloc/payment_bloc.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class EventRegistrationPage extends StatefulWidget {
  final Event event;

  const EventRegistrationPage({super.key, required this.event});

  @override
  State<EventRegistrationPage> createState() => _EventRegistrationPageState();
}

class _EventRegistrationPageState extends State<EventRegistrationPage> {
  final _teamNameController = TextEditingController();

  final Map<String, TextEditingController> _customTextControllers = {};
  final Map<String, String?> _customSelectValues = {};
  final Map<String, List<String>> _customMultiSelectValues = {};

  final List<User> _selectedMembers = [];

  late int _teamSize;
  bool _submitting = false;
  String? _pendingPaymentRegistrationId;
  bool _isInitiatePaymentPending = false;
  bool _isRollbackInFlight = false;
  late final Razorpay _razorpay;

  bool get _isTeamEvent =>
      (widget.event.participationType ?? '').trim().toLowerCase() == 'team';

  int get _minTeamSize => widget.event.minTeamSize ?? 1;
  int get _maxTeamSize => widget.event.maxTeamSize ?? (_minTeamSize + 10);

  double get _perMemberAmount =>
      widget.event.isPaid ? (widget.event.price ?? 0) : 0;

  int get _paymentMemberCount => _isTeamEvent ? _teamSize : 1;

  double get _totalAmount => _perMemberAmount * _paymentMemberCount;

  String _normalizedImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null) return uri.toString();
    return Uri.encodeFull(trimmed);
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _teamSize = _isTeamEvent ? _minTeamSize : 1;

    for (final field in widget.event.customFields) {
      if (field.normalizedType == 'image') {
        continue;
      }

      if (field.normalizedType == 'select' && field.options.isNotEmpty) {
        _customSelectValues[field.key] = null;
      } else if (field.normalizedType == 'multi_select' &&
          field.options.isNotEmpty) {
        _customMultiSelectValues[field.key] = [];
      } else {
        _customTextControllers[field.key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _teamNameController.dispose();

    for (final controller in _customTextControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    _pendingPaymentRegistrationId = null;
    _isInitiatePaymentPending = false;
    _isRollbackInFlight = false;
    AppToast.showSuccess(context, 'Payment completed successfully');
    _navigateToDetail();
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

    final imageUrl = widget.event.eventImageUrl?.trim();
    final options = <String, dynamic>{
      'key': razorpayKey,
      'order_id': payment.razorpayOrderId,
      'amount': (payment.amount * 100).round(),
      'currency': payment.currency,
      'name': widget.event.title,
      'description': 'Event registration payment',
      if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
      'prefill': {
        'name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (contact != null && contact.isNotEmpty) 'contact': contact,
      },
      'notes': {'event_id': widget.event.id, 'payment_id': payment.paymentId},
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

  void _navigateToDetail() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }
    context.go('/event-detail/${widget.event.id}');
  }

  Future<void> _pickTeamMembers() async {
    final appUserState = context.read<AppUserCubit>().state;
    final currentUserId = appUserState is AppUserAuthenticated
        ? appUserState.user.id
        : null;

    final searchUsers = serviceLocator<MessageSearchUsers>();
    final selected = await showUserSelectorBottomSheet(
      context: context,
      title: 'Add Team Members',
      searchHint: 'Search users to add in team',
      emptyMessage: 'Search by name or username',
      noResultsMessage: 'No matching users found',
      actionLabel: 'Done',
      excludedUserId: currentUserId,
      initialSelectedUsers: _selectedMembers,
      searchUsers: (query, limit) async {
        final result = await searchUsers(query: query, limit: limit);
        return result.fold((failure) => throw Exception(failure.message), (
          users,
        ) {
          return users;
        });
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedMembers
        ..clear()
        ..addAll(selected);

      final minRequired = _selectedMembers.length + 1;
      if (_teamSize < minRequired) {
        _teamSize = minRequired;
      }
      if (_teamSize > _maxTeamSize) {
        _teamSize = _maxTeamSize;
      }
    });
  }

  String? _validate() {
    if (_isTeamEvent) {
      if (_teamNameController.text.trim().isEmpty) {
        return 'Team name is required for team events';
      }
      if (_teamSize < _minTeamSize) {
        return 'Team size must be at least $_minTeamSize';
      }
      if (_teamSize > _maxTeamSize) {
        return 'Team size cannot exceed $_maxTeamSize';
      }
      if (_teamSize < _selectedMembers.length + 1) {
        return 'Team size must include captain and selected members';
      }
      final requiredMembers = _teamSize - 1;
      if (_selectedMembers.length != requiredMembers) {
        return 'Add exactly $requiredMembers team members to continue';
      }
    }

    for (final field in widget.event.customFields) {
      if (field.normalizedType == 'image') {
        continue;
      }

      if (!field.required) continue;

      final type = field.normalizedType;
      if (type == 'select') {
        final selected = (_customSelectValues[field.key] ?? '').trim();
        if (selected.isEmpty) {
          return '${field.label} is required';
        }
        continue;
      }

      if (type == 'multi_select') {
        final selected =
            _customMultiSelectValues[field.key] ?? const <String>[];
        if (selected.isEmpty) {
          return '${field.label} is required';
        }
        continue;
      }

      final value = (_customTextControllers[field.key]?.text ?? '').trim();
      if (value.isEmpty) {
        return '${field.label} is required';
      }
    }

    return null;
  }

  EventRegistrationPayload _buildPayload() {
    final customResponses = <String, dynamic>{};

    for (final field in widget.event.customFields) {
      final type = field.normalizedType;
      if (type == 'image') {
        continue;
      }

      if (type == 'select') {
        final selected = (_customSelectValues[field.key] ?? '').trim();
        if (selected.isNotEmpty) {
          customResponses[field.key] = selected;
        }
        continue;
      }

      if (type == 'multi_select') {
        final selected =
            (_customMultiSelectValues[field.key] ?? const <String>[])
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toSet()
                .toList(growable: false);
        if (selected.isNotEmpty) {
          customResponses[field.key] = selected;
        }
        continue;
      }

      final value = (_customTextControllers[field.key]?.text ?? '').trim();
      if (value.isNotEmpty) {
        customResponses[field.key] = value;
      }
    }

    return EventRegistrationPayload(
      teamName: _isTeamEvent ? _teamNameController.text.trim() : null,
      teamSize: _isTeamEvent ? _teamSize : null,
      customFieldResponses: customResponses,
      memberUserIds: _selectedMembers
          .map((member) => member.id)
          .toList(growable: false),
    );
  }

  Future<void> _submit() async {
    final validation = _validate();
    if (validation != null) {
      AppToast.showWarning(context, validation);
      return;
    }

    final payload = _buildPayload();

    if (!mounted) return;
    setState(() {
      _submitting = true;
    });
    context.read<EventBloc>().add(EventRegisterEvent(widget.event.id, payload));
  }

  Widget _buildReadOnlyImageField(EventCustomField field) {
    final imageUrl = field.imageUrl?.trim();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    void openViewer() {
      if (imageUrl == null || imageUrl.isEmpty) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageViewerPage(
            imageUrls: [_normalizedImageUrl(imageUrl)],
            initialIndex: 0,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: imageUrl == null || imageUrl.isEmpty ? null : openViewer,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.image,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    field.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if ((field.helperText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                field.helperText!.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 1,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: _normalizedImageUrl(imageUrl),
                            cacheManager: MediaCacheManager.instance,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                _buildImageLoadingPlaceholder(),
                            errorWidget: (context, url, error) =>
                                _buildImageUnavailablePlaceholder(),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.42),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 12,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Organizer image',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : _buildImageUnavailablePlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLoadingPlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildImageUnavailablePlaceholder() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.image,
            size: 24,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Image unavailable',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MultiBlocListener(
      listeners: [
        BlocListener<EventBloc, EventState>(
          listener: (context, state) {
            if (state is EventRegistrationLoading) {
              setState(() {
                _submitting = true;
              });
              return;
            }

            if (state is EventRegistrationSuccess &&
                state.response.event.id == widget.event.id) {
              if (state.response.event.isPaid) {
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
                _navigateToDetail();
              }
              return;
            }

            if (state is EventRegistrationFailure) {
              setState(() {
                _submitting = false;
              });
              AppToast.showError(context, state.message);
            }
          },
        ),
        BlocListener<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentInitiateSuccess) {
              _isInitiatePaymentPending = false;
              _openRazorpayCheckout(state.response);
              return;
            }

            if (state is PaymentRevertRegistrationSuccess) {
              _pendingPaymentRegistrationId = null;
              _isInitiatePaymentPending = false;
              _isRollbackInFlight = false;
              setState(() {
                _submitting = false;
              });
              AppToast.showError(
                context,
                'Payment failed. Registration has been reverted.',
              );
              return;
            }

            if (state is PaymentFailure) {
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
                setState(() {
                  _submitting = false;
                });

                final normalized = state.message.trim().toLowerCase();
                if (normalized.contains('event is not a paid event')) {
                  _pendingPaymentRegistrationId = null;
                  AppToast.showSuccess(
                    context,
                    'Registered successfully (payment not required).',
                  );
                  _navigateToDetail();
                  return;
                }

                if (normalized.contains('payment already completed')) {
                  _pendingPaymentRegistrationId = null;
                  AppToast.showSuccess(context, 'Payment already completed.');
                  _navigateToDetail();
                  return;
                }

                AppToast.showError(context, state.message);
                return;
              }

              if (_isRollbackInFlight) {
                _isRollbackInFlight = false;
                setState(() {
                  _submitting = false;
                });
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
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('Event Registration')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isTeamEvent) ...[
                    Text(
                      'Team Registration',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _teamNameController,
                      label: 'Team Name *',
                      icon: FontAwesomeIcons.users,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _teamSize > _minTeamSize
                                ? () => setState(() => _teamSize--)
                                : null,
                            icon: const FaIcon(
                              FontAwesomeIcons.minus,
                              size: 14,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$_teamSize Members',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Allowed: $_minTeamSize - $_maxTeamSize',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _teamSize < _maxTeamSize
                                ? () => setState(() => _teamSize++)
                                : null,
                            icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedMembers.length == (_teamSize - 1)
                          ? 'Team is complete. You can submit now.'
                          : 'Add ${(_teamSize - 1) - _selectedMembers.length} more member(s) to continue',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _selectedMembers.length == (_teamSize - 1)
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Team Members (${_selectedMembers.length})',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _pickTeamMembers,
                          child: const Text('Search & Add'),
                        ),
                      ],
                    ),
                    if (_selectedMembers.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedMembers
                            .map(
                              (member) => Chip(
                                label: Text(_displayName(member)),
                                onDeleted: () {
                                  setState(() {
                                    _selectedMembers.removeWhere(
                                      (u) => u.id == member.id,
                                    );
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      )
                    else
                      Text(
                        'Add members to match selected team size',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 14),
                  ],
                  if (widget.event.customFields.isNotEmpty) ...[
                    Text(
                      'Registration Fields',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.event.customFields.map((field) {
                      final normalizedType = field.normalizedType;
                      if (normalizedType == 'image') {
                        return _buildReadOnlyImageField(field);
                      }

                      final requiredMark = field.required ? ' *' : '';

                      if (normalizedType == 'select' &&
                          field.options.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DropdownButtonFormField<String>(
                            initialValue: _customSelectValues[field.key],
                            decoration: _decoration(
                              context,
                              label: '${field.label}$requiredMark',
                              icon: FontAwesomeIcons.list,
                              helperText: field.helperText,
                            ),
                            items: field.options
                                .map(
                                  (option) => DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              setState(() {
                                _customSelectValues[field.key] = value;
                              });
                            },
                          ),
                        );
                      }

                      if (normalizedType == 'multi_select' &&
                          field.options.isNotEmpty) {
                        final selectedValues =
                            _customMultiSelectValues[field.key] ??
                            const <String>[];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InputDecorator(
                            decoration: _decoration(
                              context,
                              label: '${field.label}$requiredMark',
                              icon: FontAwesomeIcons.listCheck,
                              helperText: field.helperText,
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: field.options
                                  .map((option) {
                                    final isSelected = selectedValues.contains(
                                      option,
                                    );
                                    return FilterChip(
                                      label: Text(option),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        final nextValues = List<String>.from(
                                          selectedValues,
                                        );
                                        if (selected) {
                                          nextValues.add(option);
                                        } else {
                                          nextValues.remove(option);
                                        }

                                        setState(() {
                                          _customMultiSelectValues[field.key] =
                                              nextValues.toSet().toList(
                                                growable: false,
                                              );
                                        });
                                      },
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                          ),
                        );
                      }

                      return _InputField(
                        controller: _customTextControllers[field.key]!,
                        label: '${field.label}$requiredMark',
                        icon: normalizedType == 'number'
                            ? FontAwesomeIcons.hashtag
                            : FontAwesomeIcons.pen,
                        helperText: field.helperText,
                        keyboardType: normalizedType == 'number'
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
                            : TextInputType.text,
                        maxLines: normalizedType == 'textarea' ? 3 : 1,
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  if (widget.event.isPaid) ...[
                    Text(
                      'Payment',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price per member: Rs ${_perMemberAmount.toStringAsFixed(2)}',
                          ),
                          Text('Members: $_paymentMemberCount'),
                          Text(
                            'Total: Rs ${_totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'After registration, you will be redirected to Razorpay to complete payment.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit Registration'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _displayName(User user) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (user.username.isNotEmpty) return user.username;
    return 'User';
  }
}

InputDecoration _decoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  String? helperText,
}) {
  return InputDecoration(
    labelText: label,
    helperText: helperText?.trim().isEmpty == true ? null : helperText?.trim(),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: FaIcon(icon, size: 14),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? helperText;
  final TextInputType keyboardType;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.helperText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: _decoration(
          context,
          label: label,
          icon: icon,
          helperText: helperText,
        ),
      ),
    );
  }
}
