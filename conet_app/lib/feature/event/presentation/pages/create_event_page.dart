import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/core/utils/quill_content_utils.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:conet_app/feature/event/domain/entities/event_activity.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_custom_field.dart';
import 'package:conet_app/feature/event/domain/entities/event_faq.dart';
import 'package:conet_app/feature/event/domain/entities/event_prize.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/event/presentation/constants/event_constants.dart';
import 'package:conet_app/feature/event/presentation/widgets/basic_info_step.dart';
import 'package:conet_app/feature/event/presentation/widgets/participation_and_registration_step.dart';
import 'package:conet_app/feature/event/presentation/widgets/preview_step.dart';
import 'package:conet_app/feature/event/presentation/widgets/reward_and_organizer_step.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // ── Form data (single source of truth) ──
  Map<String, dynamic> _formData = {
    'title': '',
    'category': '',
    'event_date': null, // DateTime?
    'start_time': null, // TimeOfDay?
    'end_time': null, // TimeOfDay?
    'location_type': 'OFFLINE', // 'ONLINE' | 'OFFLINE'
    'location': '',
    'venue_name': '',
    'meeting_link': '',
    'ticket_price_type': 'FREE', // 'FREE' | 'PAID'
    'price': null,
    'upi_id': '',
    'registration_deadline': null,
    'participation_type': 'individual',
    'min_team_size': null,
    'max_team_size': null,
    'custom_fields': <Map<String, dynamic>>[],
    'event_image_file': null, // PlatformFile?
    'about': '',
    'eligibility': '',
    'additional_note': '',
    'activities': <Map<String, dynamic>>[], // [{activity_time, activity_title}]
    'max_participant': null,
    'prize_type': 'none', // 'none' | 'certificate' | 'cash' | 'custom'
    'prizes': <Map<String, dynamic>>[], // [{position, prize}]
    'faqs': <Map<String, dynamic>>[], // [{question, answer}]
    'mobile_number': '',
    'co_organizers': <String>[],
    'co_organizer_ids': <String>[],
    'co_organizer_users': <Map<String, dynamic>>[],
    'create_event_conversation': false,
    'event_conversation_id': null,
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFormDataChange(Map<String, dynamic> updated) {
    setState(() => _formData = updated);
  }

  // ── Validation per step ──
  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if ((_formData['title'] as String).trim().isEmpty) {
          return 'Please enter an event title';
        }
        if ((_formData['category'] as String).isEmpty) {
          return 'Please select a category';
        }
        if (_formData['event_date'] == null) {
          return 'Please pick a date';
        }
        if (_formData['start_time'] == null) {
          return 'Please pick a start time';
        }
        if (_formData['end_time'] == null) {
          return 'Please pick an end time';
        }
        final isOnline = _formData['location_type'] == 'ONLINE';
        if (isOnline && (_formData['meeting_link'] as String).trim().isEmpty) {
          return 'Please provide a meeting link';
        }
        if (!isOnline && (_formData['location'] as String).trim().isEmpty) {
          return 'Please provide a location';
        }
        if (quillPlainTextFromString(
          _formData['about'] as String? ?? '',
        ).isEmpty) {
          return 'Please add an event description';
        }
        return null;
      case 1:
        final eventDate = _formData['event_date'] as DateTime?;
        final eventStartTime = _formData['start_time'] as TimeOfDay?;
        final registrationDeadline =
            _formData['registration_deadline'] as DateTime?;

        if (registrationDeadline != null &&
            eventDate != null &&
            eventStartTime != null) {
          final eventStartDateTime = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
            eventStartTime.hour,
            eventStartTime.minute,
          );

          if (!registrationDeadline.isBefore(eventStartDateTime)) {
            return 'Registration deadline must be before event start time';
          }
        }

        final participationType =
            (_formData['participation_type'] as String? ?? 'individual')
                .toLowerCase();
        final minTeam = _formData['min_team_size'] as int?;
        final maxTeam = _formData['max_team_size'] as int?;

        if (participationType == 'team') {
          if (maxTeam == null) {
            return 'Please provide max team size for team events';
          }
          if (minTeam != null && minTeam > maxTeam) {
            return 'Min team size cannot be greater than max team size';
          }
        }

        final ticketPriceType =
            (_formData['ticket_price_type'] as String? ?? 'FREE').toUpperCase();
        if (ticketPriceType == 'PAID') {
          final price = _formData['price'] as double?;
          final upiId = (_formData['upi_id'] as String? ?? '').trim();
          if (price == null || price <= 0) {
            return 'Please provide a valid ticket price for paid events';
          }
          if (upiId.isEmpty) {
            return 'Please provide UPI ID for paid events';
          }
        }

        final rawCustomFields = List<Map<String, dynamic>>.from(
          _formData['custom_fields'] as List? ?? const <Map<String, dynamic>>[],
        );
        for (var i = 0; i < rawCustomFields.length; i++) {
          final field = rawCustomFields[i];
          final label = (field['label'] as String? ?? '').trim();
          final key = (field['key'] as String? ?? '').trim();
          if (label.isEmpty || key.isEmpty) {
            return 'Custom field ${i + 1} must have label and key';
          }

          final type = ((field['type'] as String?) ?? 'text').toLowerCase();
          final options =
              (field['options'] as List?)
                  ?.map((value) => value.toString().trim())
                  .where((value) => value.isNotEmpty)
                  .toList(growable: false) ??
              const <String>[];
          if ((type == 'select' || type == 'multi_select') && options.isEmpty) {
            return 'Custom field ${i + 1} needs options for select types';
          }
        }
        return null;
      default:
        return null; // Steps 2-4 have no mandatory fields
    }
  }

  String? _validateBeforeSubmit() {
    const requiredSteps = <int>[0, 1];
    for (final step in requiredSteps) {
      final validation = _validateStep(step);
      if (validation != null) {
        return validation;
      }
    }
    return null;
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  void _next() {
    final error = _validateStep(_currentStep);
    if (error != null) {
      AppToast.showWarning(context, error);
      return;
    }
    if (_currentStep < totalSteps - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _showStepHelp() {
    final subtitle = stepSubtitles[_currentStep];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(stepTitles[_currentStep]),
        content: Text(subtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  EventCreatePayload _buildPayload() {
    final date = _formData['event_date'] as DateTime;
    final startTod = _formData['start_time'] as TimeOfDay;
    final endTod = _formData['end_time'] as TimeOfDay;

    DateTime todToDateTime(TimeOfDay tod) =>
        DateTime(date.year, date.month, date.day, tod.hour, tod.minute);

    final rawActivities = List<Map<String, dynamic>>.from(
      _formData['activities'] as List? ?? [],
    );
    final activities = rawActivities
        .where(
          (a) =>
              a['activity_time'] != null &&
              (a['activity_title'] as String?)?.isNotEmpty == true,
        )
        .map(
          (a) => EventActivity(
            activityTime: todToDateTime(a['activity_time'] as TimeOfDay),
            activityTitle: a['activity_title'] as String,
          ),
        )
        .toList();

    final rawPrizes = List<Map<String, dynamic>>.from(
      _formData['prizes'] as List? ?? [],
    );
    final prizes = rawPrizes
        .where(
          (p) =>
              (p['position'] as String?)?.isNotEmpty == true &&
              (p['prize'] as String?)?.isNotEmpty == true,
        )
        .map(
          (p) => EventPrize(
            position: p['position'] as String,
            prize: p['prize'] as String,
          ),
        )
        .toList();

    final rawFaqs = List<Map<String, dynamic>>.from(
      _formData['faqs'] as List? ?? [],
    );
    final faqs = rawFaqs
        .where(
          (f) =>
              (f['question'] as String?)?.isNotEmpty == true &&
              (f['answer'] as String?)?.isNotEmpty == true,
        )
        .map(
          (f) => EventFaq(
            question: f['question'] as String,
            answer: f['answer'] as String,
          ),
        )
        .toList();

    final rawCustomFields = List<Map<String, dynamic>>.from(
      _formData['custom_fields'] as List? ?? [],
    );
    final customFields = rawCustomFields
        .map((field) {
          final rawLabel = (field['label'] as String? ?? '').trim();
          final rawKey = (field['key'] as String? ?? '').trim();
          final key = rawKey.isEmpty
              ? _normalizeFieldKeyFromLabel(rawLabel)
              : _normalizeFieldKeyFromLabel(rawKey);
          if (key.isEmpty || rawLabel.isEmpty) {
            return null;
          }

          final type = ((field['type'] as String?) ?? 'text')
              .trim()
              .toLowerCase();
          final options =
              (field['options'] as List?)
                  ?.map((value) => value.toString().trim())
                  .where((value) => value.isNotEmpty)
                  .toSet()
                  .toList(growable: false) ??
              const <String>[];

          return EventCustomField(
            key: key,
            label: rawLabel,
            type: type.isEmpty ? 'text' : type,
            required: field['required'] == true,
            options: options,
          );
        })
        .whereType<EventCustomField>()
        .fold<List<EventCustomField>>([], (acc, field) {
          if (acc.any((existing) => existing.key == field.key)) {
            return acc;
          }
          return [...acc, field];
        });

    final isOnline = _formData['location_type'] == 'ONLINE';
    final cityOrCampus = (_formData['location'] as String? ?? '').trim();
    final venueName = (_formData['venue_name'] as String? ?? '').trim();
    final offlineLocation = [
      if (cityOrCampus.isNotEmpty) cityOrCampus,
      if (venueName.isNotEmpty) venueName,
    ].join(', ');

    final shouldCreateConversation =
        _formData['create_event_conversation'] as bool? ?? false;
    final rawConversationId = shouldCreateConversation
        ? (_formData['event_conversation_id'] as String?)
        : null;
    final normalizedConversationId = rawConversationId?.trim();
    final normalizedUpiId = (_formData['upi_id'] as String? ?? '').trim();
    final ticketPriceType = _formData['ticket_price_type'] as String? ?? 'FREE';

    final participationType =
        (_formData['participation_type'] as String? ?? 'individual')
            .trim()
            .toLowerCase();
    final minTeamSize = _formData['min_team_size'] as int?;
    final maxTeamSize = _formData['max_team_size'] as int?;

    return EventCreatePayload(
      title: _formData['title'] as String,
      category: _formData['category'] as String,
      about: (_formData['about'] as String?)?.trim().isEmpty == true
          ? null
          : (quillPlainTextFromString(
                  _formData['about'] as String? ?? '',
                ).isEmpty
                ? null
                : _formData['about'] as String?),
      eventDate: date,
      startTime: todToDateTime(startTod),
      endTime: todToDateTime(endTod),
      locationType: _formData['location_type'] as String,
      location: isOnline
          ? null
          : (offlineLocation.isEmpty ? null : offlineLocation),
      meetingLink:
          isOnline &&
              (_formData['meeting_link'] as String?)?.trim().isNotEmpty == true
          ? _formData['meeting_link'] as String?
          : null,
      ticketPriceType: ticketPriceType,
      price: _formData['price'] as double?,
      maxParticipant: _formData['max_participant'] as int?,
      registrationDeadline: _formData['registration_deadline'] as DateTime?,
      participationType: participationType,
      minTeamSize: participationType == 'team' ? minTeamSize : null,
      maxTeamSize: participationType == 'team' ? maxTeamSize : null,
      upiId: ticketPriceType == 'PAID' && normalizedUpiId.isNotEmpty
          ? normalizedUpiId
          : null,
      customFields: customFields,
      eligibility: (_formData['eligibility'] as String?)?.trim().isEmpty == true
          ? null
          : _formData['eligibility'] as String?,
      eventImage: _formData['event_image_file'] as PlatformFile?,
      activities: activities,
      prizes: prizes,
      faqs: faqs,
      cohostUserIds: List<String>.from(
        _formData['co_organizer_ids'] as List? ?? const <String>[],
      ).toSet().toList(growable: false),
      conversationId:
          normalizedConversationId == null || normalizedConversationId.isEmpty
          ? null
          : normalizedConversationId,
    );
  }

  String _normalizeFieldKeyFromLabel(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  void _saveDraft() {
    final validation = _validateBeforeSubmit();
    if (validation != null) {
      AppToast.showWarning(context, validation);
      return;
    }

    try {
      final shouldCreateConversation =
          _formData['create_event_conversation'] as bool? ?? false;
      context.read<EventBloc>().add(
        EventSaveDraftEvent(
          _buildPayload(),
          shouldCreateOrganizerConversation: shouldCreateConversation,
        ),
      );
    } catch (e) {
      AppToast.showError(context, 'Failed to build payload: $e');
    }
  }

  void _preview() {
    final error = _validateStep(_currentStep);
    if (error != null) {
      AppToast.showWarning(context, error);
      return;
    }
    _goToStep(totalSteps - 1);
  }

  void _publish() {
    final validation = _validateBeforeSubmit();
    if (validation != null) {
      AppToast.showWarning(context, validation);
      return;
    }

    try {
      final shouldCreateConversation =
          _formData['create_event_conversation'] as bool? ?? false;
      context.read<EventBloc>().add(
        EventPublishEvent(
          _buildPayload(),
          shouldCreateOrganizerConversation: shouldCreateConversation,
        ),
      );
    } catch (e) {
      AppToast.showError(context, 'Failed to build payload: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventBloc, EventState>(
      listenWhen: (_, current) =>
          current is EventCreateSuccess ||
          current is EventCreateFailure ||
          current is EventCreateLoading,
      listener: (context, state) {
        if (state is EventCreateSuccess) {
          final msg = state.isDraft
              ? 'Event saved as draft'
              : 'Event published successfully!';
          AppToast.showSuccess(context, msg);
          context.pop();
        } else if (state is EventCreateFailure) {
          AppToast.showError(context, state.message);
        }
      },
      buildWhen: (_, current) =>
          current is EventCreateLoading ||
          current is EventCreateSuccess ||
          current is EventCreateFailure ||
          current is EventInitial,
      builder: (context, state) {
        final isSubmitting = state is EventCreateLoading;
        return _buildScaffold(context, isSubmitting: isSubmitting);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, {required bool isSubmitting}) {
    return Stack(
      children: [
        _buildForm(context, isSubmitting: isSubmitting),
        if (isSubmitting) ...[
          const ModalBarrier(dismissible: false, color: Colors.black38),
          const Center(child: Loader()),
        ],
      ],
    );
  }

  Widget _buildForm(BuildContext context, {required bool isSubmitting}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLast = _currentStep == totalSteps - 1;
    final isPreview = _currentStep == totalSteps - 2;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
          onPressed: _currentStep > 0 ? _back : () => context.pop(),
        ),
        title: Text(
          stepTitles[_currentStep],
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: _showStepHelp,
            icon: const FaIcon(FontAwesomeIcons.circleQuestion, size: 18),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: _StepProgressBar(
              currentStep: _currentStep,
              totalSteps: totalSteps,
              colorScheme: colorScheme,
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentStep = i),
        children: [
          BasicInfoStep(
            formData: _formData,
            onFormDataChange: _onFormDataChange,
            stepTitle: stepTitles[0],
            stepSubtitle: stepSubtitles[0],
          ),
          ParticipationAndRegistrationStep(
            formData: _formData,
            onFormDataChange: _onFormDataChange,
            stepTitle: stepTitles[1],
            stepSubtitle: stepSubtitles[1],
          ),
          RewardAndOrganizerStep(
            formData: _formData,
            onFormDataChange: _onFormDataChange,
            stepTitle: stepTitles[2],
            stepSubtitle: stepSubtitles[2],
          ),
          PreviewStep(
            formData: _formData,
            stepTitle: stepTitles[3],
            stepSubtitle: stepSubtitles[3],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSubmitting ? null : _saveDraft,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Save as Draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: isSubmitting
                    ? null
                    : (isLast ? _publish : (isPreview ? _preview : _next)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPreview) ...[
                      const FaIcon(FontAwesomeIcons.eye, size: 16),
                      const SizedBox(width: 6),
                    ],
                    if (isLast) ...[
                      const FaIcon(FontAwesomeIcons.rocket, size: 14),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isLast
                          ? 'Publish'
                          : isPreview
                          ? 'Preview'
                          : 'Next',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final ColorScheme colorScheme;

  const _StepProgressBar({
    required this.currentStep,
    required this.totalSteps,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isComplete = index <= currentStep;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 4),
            decoration: BoxDecoration(
              color: isComplete
                  ? colorScheme.onSurface.withValues(alpha: 0.9)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
