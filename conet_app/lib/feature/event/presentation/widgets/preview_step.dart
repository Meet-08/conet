import 'dart:io';

import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
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
  bool _showFullAbout = false;

  // ── Helpers ──────────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title = widget.formData['title'] as String? ?? '';
    final category = widget.formData['category'] as String? ?? '';
    final eventDate = widget.formData['event_date'] as DateTime?;
    final startTime = widget.formData['start_time'] as TimeOfDay?;
    final endTime = widget.formData['end_time'] as TimeOfDay?;
    final isOnline = widget.formData['location_type'] == 'ONLINE';
    final location = widget.formData['location'] as String? ?? '';
    final meetingLink = widget.formData['meeting_link'] as String? ?? '';
    final isPaid = widget.formData['ticket_price_type'] == 'PAID';
    final price = widget.formData['price'];
    final imageFile = widget.formData['event_image_file'] as PlatformFile?;
    final about = widget.formData['about'] as String? ?? '';
    final eligibility = widget.formData['eligibility'] as String? ?? '';
    final additionalNote = widget.formData['additional_note'] as String? ?? '';
    final maxParticipant = widget.formData['max_participant'];
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
    final coOrganizers = List<String>.from(
      widget.formData['co_organizers'] as List? ?? [],
    );
    final coOrganizerUsers = List<Map<String, dynamic>>.from(
      widget.formData['co_organizer_users'] as List? ?? [],
    );

    final registrationCount = maxParticipant is int
        ? (maxParticipant * 0.6).round().clamp(1, maxParticipant)
        : 1847;

    final aboutTrimmed = about.trim();
    final canExpandAbout = aboutTrimmed.length > 180;
    final aboutPreview = canExpandAbout
        ? '${aboutTrimmed.substring(0, 180)}...'
        : (aboutTrimmed.isEmpty
              ? 'No event description provided yet.'
              : aboutTrimmed);

    final instructionPoints = _instructionPoints(additionalNote);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            label: widget.stepTitle,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
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
                                color: colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Text(
                                    _initialsFromTitle(title),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
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
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: AppRadius.fullAll,
                            ),
                            child: Text(
                              _categoryLabel(category).toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
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
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _QuickInfoRow(
                  icon: FontAwesomeIcons.calendar,
                  title: _formatShortDate(eventDate),
                  subtitle:
                      '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                  theme: theme,
                  colorScheme: colorScheme,
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
                  theme: theme,
                  colorScheme: colorScheme,
                ),
                if (minTeamSize != null || maxTeamSize != null) ...[
                  const SizedBox(height: 12),
                  _QuickInfoRow(
                    icon: FontAwesomeIcons.userGroup,
                    title: 'Team Size',
                    subtitle:
                        '${minTeamSize ?? '1'} - ${maxTeamSize ?? '∞'} members',
                    theme: theme,
                    colorScheme: colorScheme,
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
                  theme: theme,
                  colorScheme: colorScheme,
                ),

                const SizedBox(height: 18),
                _line(colorScheme),
                const SizedBox(height: 16),

                Text(
                  'About ${title.isEmpty ? 'this event' : title}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _showFullAbout
                      ? (aboutTrimmed.isEmpty
                            ? 'No event description provided yet.'
                            : aboutTrimmed)
                      : aboutPreview,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                ),
                if (canExpandAbout)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showFullAbout = !_showFullAbout),
                      child: Text(
                        _showFullAbout ? 'Read less' : 'Read more',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                if (activities.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _line(colorScheme),
                  const SizedBox(height: 14),
                  Text(
                    'Event Schedule',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                                color: colorScheme.onSurface,
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
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (duration.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• $duration',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ],
                                  );
                                }(),
                                const SizedBox(height: 2),
                                Text(
                                  title.isEmpty ? 'Activity' : title,
                                  style: theme.textTheme.titleMedium?.copyWith(
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
                _line(colorScheme),
                const SizedBox(height: 14),
                Text(
                  'Prizes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (prizes.isEmpty)
                  _PrizeTile(
                    position: _prizeLabel(prizeType),
                    value: 'Prize details will be announced by the organizer',
                    theme: theme,
                    colorScheme: colorScheme,
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
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    );
                  }),

                const SizedBox(height: 18),
                _line(colorScheme),
                const SizedBox(height: 14),
                Text(
                  'Organizer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage: profilePicUrl != null
                                ? NetworkImage(profilePicUrl)
                                : null,
                            child: profilePicUrl == null
                                ? Text(
                                    _initialsFromTitle(organizerName),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onPrimaryContainer,
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
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  mobileNumber.isEmpty
                                      ? 'Contact will be shared'
                                      : mobileNumber,
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
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: AppRadius.fullAll,
                              ),
                              child: Text(
                                displayName,
                                style: theme.textTheme.labelSmall?.copyWith(
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
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: AppRadius.fullAll,
                              ),
                              child: Text(
                                '@$u',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                  ),
                ],

                const SizedBox(height: 18),
                _line(colorScheme),
                const SizedBox(height: 14),
                Text(
                  'Instructions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: AppRadius.smAll,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: instructionPoints.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                if (eligibility.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Eligibility',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppRadius.smAll,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(eligibility, style: theme.textTheme.bodyMedium),
                  ),
                ],

                if (faqs.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _line(colorScheme),
                  const SizedBox(height: 14),
                  Text(
                    'Frequently Asked Questions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: AppRadius.smAll,
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
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
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    FaIcon(
                                      expanded
                                          ? FontAwesomeIcons.chevronUp
                                          : FontAwesomeIcons.chevronDown,
                                      size: 12,
                                      color: colorScheme.onSurfaceVariant,
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
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
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

                const SizedBox(height: 18),
                _line(colorScheme),
                const SizedBox(height: 14),
                Text(
                  'Discussion',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: FaIcon(
                          FontAwesomeIcons.message,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${title.isEmpty ? 'Event' : title} Group',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$registrationCount members',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Register to auto join this group',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(ColorScheme colorScheme) {
    return Container(
      height: 1,
      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _SectionTitle({
    required this.label,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class _QuickInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _QuickInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
    required this.colorScheme,
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
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(icon, size: 14, color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

class _PrizeTile extends StatelessWidget {
  final String position;
  final String value;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _PrizeTile({
    required this.position,
    required this.value,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.award,
                size: 13,
                color: colorScheme.primary,
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
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
