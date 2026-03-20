import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class PreviewStep extends StatelessWidget {
  final Map<String, dynamic> formData;
  final String stepTitle;
  final String stepSubtitle;

  const PreviewStep({
    super.key,
    required this.formData,
    required this.stepTitle,
    required this.stepSubtitle,
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime? d) =>
      d == null ? '—' : DateFormat('EEEE, MMMM d, yyyy').format(d);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title = formData['title'] as String? ?? '';
    final category = formData['category'] as String? ?? '';
    final eventDate = formData['event_date'] as DateTime?;
    final startTime = formData['start_time'] as TimeOfDay?;
    final endTime = formData['end_time'] as TimeOfDay?;
    final isOnline = formData['location_type'] == 'ONLINE';
    final location = formData['location'] as String? ?? '';
    final meetingLink = formData['meeting_link'] as String? ?? '';
    final isPaid = formData['ticket_price_type'] == 'PAID';
    final price = formData['price'];
    final imageFile = formData['event_image_file'] as PlatformFile?;
    final about = formData['about'] as String? ?? '';
    final eligibility = formData['eligibility'] as String? ?? '';
    final additionalNote = formData['additional_note'] as String? ?? '';
    final maxParticipant = formData['max_participant'];
    final prizeType = formData['prize_type'] as String? ?? 'none';
    final activities = List<Map<String, dynamic>>.from(
      formData['activities'] as List? ?? [],
    );
    final faqs = List<Map<String, dynamic>>.from(
      formData['faqs'] as List? ?? [],
    );
    final mobileNumber = formData['mobile_number'] as String? ?? '';
    final coOrganizers = List<String>.from(
      formData['co_organizers'] as List? ?? [],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Step Header ──────────────────────────────────────────────────
          Text(
            stepTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stepSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // ── Event Image ──────────────────────────────────────────────────
          if (imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: kIsWeb && imageFile.bytes != null
                    ? Image.memory(imageFile.bytes!, fit: BoxFit.cover)
                    : Image.file(File(imageFile.path!), fit: BoxFit.cover),
              ),
            )
          else
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.image,
                      size: 28,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No image selected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ── Basic Info ───────────────────────────────────────────────────
          _SectionHeader(
            icon: FontAwesomeIcons.circleInfo,
            label: 'Basic Info',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _PreviewCard(
            colorScheme: colorScheme,
            children: [
              _InfoRow(
                icon: FontAwesomeIcons.calendarCheck,
                label: 'Title',
                value: title.isEmpty ? '—' : title,
                theme: theme,
                colorScheme: colorScheme,
              ),
              _Divider(colorScheme: colorScheme),
              _InfoRow(
                icon: FontAwesomeIcons.tag,
                label: 'Category',
                value: category.isEmpty ? '—' : _categoryLabel(category),
                theme: theme,
                colorScheme: colorScheme,
              ),
              _Divider(colorScheme: colorScheme),
              _InfoRow(
                icon: FontAwesomeIcons.calendarDay,
                label: 'Date',
                value: _formatDate(eventDate),
                theme: theme,
                colorScheme: colorScheme,
              ),
              _Divider(colorScheme: colorScheme),
              _InfoRow(
                icon: FontAwesomeIcons.clock,
                label: 'Time',
                value: '${_formatTime(startTime)}  →  ${_formatTime(endTime)}',
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Location & Ticket ────────────────────────────────────────────
          _SectionHeader(
            icon: FontAwesomeIcons.locationDot,
            label: 'Location & Ticket',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _PreviewCard(
            colorScheme: colorScheme,
            children: [
              _InfoRow(
                icon: isOnline
                    ? FontAwesomeIcons.wifi
                    : FontAwesomeIcons.buildingColumns,
                label: 'Type',
                value: isOnline ? 'Online' : 'Offline',
                theme: theme,
                colorScheme: colorScheme,
              ),
              _Divider(colorScheme: colorScheme),
              _InfoRow(
                icon: isOnline
                    ? FontAwesomeIcons.link
                    : FontAwesomeIcons.mapPin,
                label: isOnline ? 'Link' : 'Venue',
                value: isOnline
                    ? (meetingLink.isEmpty ? '—' : meetingLink)
                    : (location.isEmpty ? '—' : location),
                theme: theme,
                colorScheme: colorScheme,
              ),
              _Divider(colorScheme: colorScheme),
              _InfoRow(
                icon: isPaid
                    ? FontAwesomeIcons.indianRupeeSign
                    : FontAwesomeIcons.ticketSimple,
                label: 'Ticket',
                value: isPaid ? (price != null ? '₹$price' : 'Paid') : 'Free',
                theme: theme,
                colorScheme: colorScheme,
              ),
              if (maxParticipant != null) ...[
                _Divider(colorScheme: colorScheme),
                _InfoRow(
                  icon: FontAwesomeIcons.userGroup,
                  label: 'Max Participants',
                  value: '$maxParticipant',
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // ── Event Details ────────────────────────────────────────────────
          _SectionHeader(
            icon: FontAwesomeIcons.alignLeft,
            label: 'Event Details',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _PreviewCard(
            colorScheme: colorScheme,
            children: [
              _TextBlock(
                label: 'About',
                value: about.isEmpty ? '—' : about,
                theme: theme,
                colorScheme: colorScheme,
              ),
              if (eligibility.isNotEmpty) ...[
                _Divider(colorScheme: colorScheme),
                _TextBlock(
                  label: 'Eligibility',
                  value: eligibility,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ],
              if (additionalNote.isNotEmpty) ...[
                _Divider(colorScheme: colorScheme),
                _TextBlock(
                  label: 'Additional Note',
                  value: additionalNote,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ],
              _Divider(colorScheme: colorScheme),
              _InfoRow(
                icon: FontAwesomeIcons.trophy,
                label: 'Prize',
                value: _prizeLabel(prizeType),
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
          ),

          // ── Schedule ─────────────────────────────────────────────────────
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(
              icon: FontAwesomeIcons.listCheck,
              label: 'Schedule',
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: List.generate(activities.length, (i) {
                  final a = activities[i];
                  final actTimeTod = a['activity_time'] as TimeOfDay?;
                  final actTime = actTimeTod?.format(context) ?? '';
                  final actTitle = (a['activity_title'] as String? ?? '')
                      .trim();
                  final isLast = i == activities.length - 1;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timeline line + dot
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 1.5,
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 14,
                              bottom: isLast ? 18 : 14,
                              right: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (actTime.isNotEmpty)
                                  Text(
                                    actTime,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (actTime.isNotEmpty)
                                  const SizedBox(height: 2),
                                Text(
                                  actTitle.isEmpty ? '—' : actTitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],

          // ── FAQs ─────────────────────────────────────────────────────────
          if (faqs.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(
              icon: FontAwesomeIcons.circleQuestion,
              label: 'FAQs',
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: List.generate(faqs.length, (i) {
                  final faq = faqs[i];
                  final q = (faq['question'] as String? ?? '').trim();
                  final a = (faq['answer'] as String? ?? '').trim();
                  final isLast = i == faqs.length - 1;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          a.isEmpty ? 14 : 4,
                        ),
                        child: Text(
                          q.isEmpty ? '—' : q,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (a.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Text(
                            a,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (!isLast) _Divider(colorScheme: colorScheme),
                    ],
                  );
                }),
              ),
            ),
          ],

          // ── Organizer ────────────────────────────────────────────────────
          const SizedBox(height: 16),
          _SectionHeader(
            icon: FontAwesomeIcons.userTie,
            label: 'Organizer',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _PreviewCard(
            colorScheme: colorScheme,
            children: [
              _InfoRow(
                icon: FontAwesomeIcons.phone,
                label: 'Mobile',
                value: mobileNumber.isEmpty ? '—' : mobileNumber,
                theme: theme,
                colorScheme: colorScheme,
              ),
              if (coOrganizers.isNotEmpty) ...[
                _Divider(colorScheme: colorScheme),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Co-organizers',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: coOrganizers
                            .map(
                              (u) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.at,
                                      size: 11,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      u,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Preview Card ─────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final List<Widget> children;
  final ColorScheme colorScheme;

  const _PreviewCard({required this.children, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
          FaIcon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
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

// ─── Text Block (multi-line) ──────────────────────────────────────────────────

class _TextBlock extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _TextBlock({
    required this.label,
    required this.value,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Subtle Divider ───────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Divider({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}
