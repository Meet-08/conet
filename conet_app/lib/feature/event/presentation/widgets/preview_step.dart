import 'dart:io';

import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/core/widgets/quill_read_only_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class PreviewStep extends StatefulWidget {
  final Map<String, dynamic> formData;
  final String stepTitle;
  final String stepSubtitle;

  const PreviewStep({
    super.key,
    required this.formData,
    required this.stepTitle,
    required this.stepSubtitle,
  });

  @override
  State<PreviewStep> createState() => _PreviewStepState();
}

class _PreviewStepState extends State<PreviewStep> {
  final Map<int, bool> _expandedFaqs = {};

  String _formatShortDate(DateTime? d) =>
      d == null ? '—' : DateFormat('MMM d').format(d);

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '—';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  String _categoryLabel(String value) {
    const map = {
      'tech': 'Tech',
      'workshop': 'Workshop',
      'webinar': 'Webinar',
      'hackathon': 'Hackathon',
      'seminar': 'Seminar',
      'competition': 'Competition',
      'cultural': 'Cultural',
      'social': 'Social',
      'other': 'Other',
    };
    return map[value] ?? value;
  }

  String _prizeLabel(String value) {
    const map = {
      'none': 'No Prizes',
      'certificate': 'Certificate',
      'cash': 'Cash Prizes',
      'custom': 'Custom',
    };
    return map[value] ?? value;
  }

  String _initialsFromTitle(String title) {
    final clean = title.trim();
    if (clean.isEmpty) return 'EV';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length == 1) {
      final p = parts.first;
      return p.length == 1 ? p.toUpperCase() : p.substring(0, 2).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  List<String> _instructionPoints(String raw) {
    final lines = raw
        .split(RegExp(r'\n|•|-'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const ['Follow organizer updates before the event starts.'];
    }
    return lines;
  }

  String _durationLabel(TimeOfDay? t1, TimeOfDay? t2) {
    if (t1 == null || t2 == null) return '';
    final startMin = t1.hour * 60 + t1.minute;
    final endMin = t2.hour * 60 + t2.minute;
    final diff = endMin - startMin;
    if (diff <= 0) return '';
    return '$diff mins';
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final screenTitleStyle = AppTextStyles.headingH2.copyWith(
      color: semantic.textPrimary,
    );
    final sectionTitleStyle = AppTextStyles.headingH3.copyWith(
      color: semantic.textPrimary,
    );
    final bodyLargeStyle = AppTextStyles.bodyLarge.copyWith(
      color: semantic.textPrimary,
    );

    final title = widget.formData['title'] as String? ?? '';
    final category = widget.formData['category'] as String? ?? '';
    final startDate = widget.formData['start_date'] as DateTime?;
    final startTime = widget.formData['start_time'] as TimeOfDay?;
    final endTime = widget.formData['end_time'] as TimeOfDay?;
    final isOnline = widget.formData['location_type'] == 'ONLINE';
    final location = widget.formData['location'] as String? ?? '';
    final meetingLink = widget.formData['meeting_link'] as String? ?? '';
    final isPaid = widget.formData['ticket_price_type'] == 'PAID';
    final price = widget.formData['price'];
    final imageFile = widget.formData['event_image_file'] as PlatformFile?;
    final aboutDelta = widget.formData['about'] as String? ?? '';
    final eligibility = widget.formData['eligibility'] as String? ?? '';
    final additionalNote = widget.formData['additional_note'] as String? ?? '';
    final prizeType = widget.formData['prize_type'] as String? ?? 'none';
    final minTeamSize = widget.formData['min_team_size'];
    final maxTeamSize = widget.formData['max_team_size'];
    final activities = List<Map<String, dynamic>>.from(
      widget.formData['activities'] as List? ?? [],
    );
    final prizes = List<Map<String, dynamic>>.from(
      widget.formData['prizes'] as List? ?? [],
    );
    final faqs = List<Map<String, dynamic>>.from(
      widget.formData['faqs'] as List? ?? [],
    );
    final mobileNumber = widget.formData['mobile_number'] as String? ?? '';
    final createEventConversation =
        widget.formData['create_event_conversation'] as bool? ?? false;
    final coOrganizers = List<String>.from(
      widget.formData['co_organizers'] as List? ?? [],
    );
    final coOrganizerUsers = List<Map<String, dynamic>>.from(
      widget.formData['co_organizer_users'] as List? ?? [],
    );

    final hasAboutContent = aboutDelta.trim().isNotEmpty;

    final instructionPoints = _instructionPoints(additionalNote);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            label: widget.stepTitle,
            semantic: semantic,
            titleStyle: screenTitleStyle,
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: semantic.backgroundPrimary,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: semantic.borderDefault),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.mdAll,
                      child: SizedBox(
                        width: 78,
                        height: 78,
                        child: imageFile != null
                            ? (kIsWeb && imageFile.bytes != null
                                  ? Image.memory(
                                      imageFile.bytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(imageFile.path!),
                                      fit: BoxFit.cover,
                                    ))
                            : Container(
                                color: semantic.backgroundTertiary,
                                child: Center(
                                  child: Text(
                                    _initialsFromTitle(title),
                                    style: AppTextStyles.headingH3.copyWith(
                                      color: semantic.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: semantic.backgroundTertiary,
                              borderRadius: AppRadius.fullAll,
                            ),
                            child: Text(
                              _categoryLabel(category).toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: semantic.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title.isEmpty ? 'Untitled Event' : title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: sectionTitleStyle.copyWith(height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _QuickInfoRow(
                  icon: FontAwesomeIcons.calendar,
                  title: _formatShortDate(startDate),
                  subtitle:
                      '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                  semantic: semantic,
                ),
                const SizedBox(height: 12),
                _QuickInfoRow(
                  icon: FontAwesomeIcons.locationDot,
                  title: isOnline
                      ? 'Online Event'
                      : (location.isEmpty ? 'Location TBA' : location),
                  subtitle: isOnline
                      ? (meetingLink.isEmpty
                            ? 'Link will be shared later'
                            : meetingLink)
                      : 'Venue details',
                  semantic: semantic,
                ),
                if (minTeamSize != null || maxTeamSize != null) ...[
                  const SizedBox(height: 12),
                  _QuickInfoRow(
                    icon: FontAwesomeIcons.userGroup,
                    title: 'Team Size',
                    subtitle:
                        '${minTeamSize ?? '1'} - ${maxTeamSize ?? '∞'} members',
                    semantic: semantic,
                  ),
                ],
                const SizedBox(height: 12),
                _QuickInfoRow(
                  icon: isPaid
                      ? FontAwesomeIcons.indianRupeeSign
                      : FontAwesomeIcons.sackDollar,
                  title: isPaid ? '₹${price ?? 'Paid'}' : 'Free',
                  subtitle: isPaid
                      ? 'Registration fee applies'
                      : 'No registration fee',
                  semantic: semantic,
                ),

                const SizedBox(height: 18),
                _line(semantic),
                const SizedBox(height: 16),

                Text(
                  'About ${title.isEmpty ? 'this event' : title}',
                  style: sectionTitleStyle,
                ),
                const SizedBox(height: 12),
                if (!hasAboutContent)
                  Text(
                    'No event description provided yet.',
                    style: bodyLargeStyle.copyWith(height: 1.55),
                  )
                else
                  QuillReadOnlyView(deltaJson: aboutDelta),

                if (activities.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _line(semantic),
                  const SizedBox(height: 14),
                  Text('Event Schedule', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  ...List.generate(activities.length, (i) {
                    final a = activities[i];
                    final t1 = a['activity_time'] as TimeOfDay?;
                    final t2 = i + 1 < activities.length
                        ? activities[i + 1]['activity_time'] as TimeOfDay?
                        : null;
                    final title = (a['activity_title'] as String? ?? '').trim();
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i == activities.length - 1 ? 0 : 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: semantic.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                () {
                                  final duration = _durationLabel(t1, t2);
                                  return Row(
                                    children: [
                                      Text(
                                        _formatTime(t1),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: semantic.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (duration.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• $duration',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: semantic.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ],
                                  );
                                }(),
                                const SizedBox(height: 2),
                                Text(
                                  title.isEmpty ? 'Activity' : title,
                                  style: AppTextStyles.label.copyWith(
                                    color: semantic.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 18),
                _line(semantic),
                const SizedBox(height: 14),
                Text('Prizes', style: sectionTitleStyle),
                const SizedBox(height: 10),
                if (prizes.isEmpty)
                  _PrizeTile(
                    position: _prizeLabel(prizeType),
                    value: 'Prize details will be announced by the organizer',
                    semantic: semantic,
                  )
                else
                  ...prizes.map((p) {
                    final pos = (p['position'] as String? ?? '').trim();
                    final val = (p['prize'] as String? ?? '').trim();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PrizeTile(
                        position: pos.isEmpty ? 'Prize' : pos,
                        value: val.isEmpty ? 'Prize details' : val,
                        semantic: semantic,
                      ),
                    );
                  }),

                const SizedBox(height: 18),
                _line(semantic),
                const SizedBox(height: 14),
                Text('Organizer', style: sectionTitleStyle),
                const SizedBox(height: 10),
                BlocBuilder<AppUserCubit, AppUserState>(
                  builder: (context, state) {
                    final organizerName = state is AppUserAuthenticated
                        ? '${state.user.firstName} ${state.user.lastName}'
                              .trim()
                        : 'Event Organizer';
                    final profilePicUrl = state is AppUserAuthenticated
                        ? state.user.profilePicUrl
                        : null;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: semantic.backgroundTertiary,
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(color: semantic.borderDefault),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: semantic.backgroundInfo,
                            backgroundImage: profilePicUrl != null
                                ? NetworkImage(profilePicUrl)
                                : null,
                            child: profilePicUrl == null
                                ? Text(
                                    _initialsFromTitle(organizerName),
                                    style: AppTextStyles.caption.copyWith(
                                      color: semantic.textOnInfo,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  organizerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.label.copyWith(
                                    color: semantic.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  mobileNumber.isEmpty
                                      ? 'Contact will be shared'
                                      : mobileNumber,
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
                  },
                ),
                if (coOrganizerUsers.isNotEmpty || coOrganizers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: coOrganizerUsers.isNotEmpty
                        ? coOrganizerUsers.map((cohost) {
                            final firstName =
                                (cohost['first_name'] as String? ?? '').trim();
                            final lastName =
                                (cohost['last_name'] as String? ?? '').trim();
                            final username =
                                (cohost['username'] as String? ?? '').trim();
                            final displayName =
                                '$firstName $lastName'.trim().isNotEmpty
                                ? '$firstName $lastName'.trim()
                                : (username.isNotEmpty
                                      ? '@$username'
                                      : 'Co-host');

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: semantic.backgroundTertiary,
                                borderRadius: AppRadius.fullAll,
                              ),
                              child: Text(
                                displayName,
                                style: AppTextStyles.caption.copyWith(
                                  color: semantic.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList()
                        : coOrganizers.map((u) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: semantic.backgroundTertiary,
                                borderRadius: AppRadius.fullAll,
                              ),
                              child: Text(
                                '@$u',
                                style: AppTextStyles.caption.copyWith(
                                  color: semantic.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                ],

                const SizedBox(height: 18),
                _line(semantic),
                const SizedBox(height: 14),
                Text('Instructions', style: sectionTitleStyle),
                const SizedBox(height: 10),
                _InfoCallout(items: instructionPoints, semantic: semantic),

                if (eligibility.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Eligibility', style: sectionTitleStyle),
                  const SizedBox(height: 10),
                  _InfoCallout(
                    items: eligibility
                        .split(RegExp(r'\n|•|-'))
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(growable: false),
                    semantic: semantic,
                  ),
                ],

                if (faqs.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _line(semantic),
                  const SizedBox(height: 14),
                  Text('Frequently Asked Questions', style: sectionTitleStyle),
                  const SizedBox(height: 10),
                  ...List.generate(faqs.length, (i) {
                    final f = faqs[i];
                    final q = (f['question'] as String? ?? '').trim();
                    final a = (f['answer'] as String? ?? '').trim();
                    final expanded = _expandedFaqs[i] ?? i == 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: semantic.backgroundTertiary,
                          borderRadius: AppRadius.smAll,
                          border: Border.all(color: semantic.borderDefault),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: AppRadius.smAll,
                              onTap: () {
                                setState(() {
                                  _expandedFaqs[i] = !expanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        q.isEmpty ? 'FAQ ${i + 1}' : q,
                                        style: AppTextStyles.label.copyWith(
                                          color: semantic.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    FaIcon(
                                      expanded
                                          ? FontAwesomeIcons.chevronUp
                                          : FontAwesomeIcons.chevronDown,
                                      size: 12,
                                      color: semantic.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (expanded)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                child: Text(
                                  a.isEmpty
                                      ? 'Answer will be shared by organizer.'
                                      : a,
                                  style: AppTextStyles.bodyDefault.copyWith(
                                    color: semantic.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                if (createEventConversation) ...[
                  const SizedBox(height: 18),
                  _line(semantic),
                  const SizedBox(height: 14),
                  Text('Discussion', style: sectionTitleStyle),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: semantic.backgroundInfo,
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: semantic.borderInfo),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: semantic.backgroundPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: semantic.borderDefault),
                          ),
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.message,
                              size: 16,
                              color: semantic.iconSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${title.isEmpty ? 'Event' : title} Group',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.label.copyWith(
                                  color: semantic.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Register to auto-join this group',
                                style: AppTextStyles.bodyDefault.copyWith(
                                  color: semantic.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(AppSemanticColors semantic) {
    return Container(height: 1, color: semantic.borderDefault);
  }
}

class _InfoCallout extends StatelessWidget {
  final List<String> items;
  final AppSemanticColors semantic;

  const _InfoCallout({required this.items, required this.semantic});

  Widget _bulletItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: semantic.iconInfo,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item,
              style: AppTextStyles.bodyDefault.copyWith(
                height: 1.45,
                color: semantic.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s10),
      decoration: BoxDecoration(
        color: semantic.backgroundInfo,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: semantic.borderInfo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Details will be shared by the organizer.',
              style: AppTextStyles.bodyDefault.copyWith(
                height: 1.45,
                color: semantic.textPrimary,
              ),
            )
          else
            ...items.map(_bulletItem),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final AppSemanticColors semantic;
  final TextStyle titleStyle;

  const _SectionTitle({
    required this.label,
    required this.semantic,
    required this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text(label, style: titleStyle);
  }
}

class _QuickInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AppSemanticColors semantic;

  const _QuickInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: semantic.backgroundTertiary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(icon, size: 14, color: semantic.iconSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: semantic.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyDefault.copyWith(
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

class _PrizeTile extends StatelessWidget {
  final String position;
  final String value;
  final AppSemanticColors semantic;

  const _PrizeTile({
    required this.position,
    required this.value,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: semantic.backgroundTertiary,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: semantic.backgroundPrimary,
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.award,
                size: 13,
                color: semantic.iconInfo,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position,
                  style: AppTextStyles.bodyDefault.copyWith(
                    color: semantic.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.label.copyWith(
                    color: semantic.textPrimary,
                    fontWeight: FontWeight.w700,
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
