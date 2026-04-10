import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TeamRegistrationDetailPage extends StatelessWidget {
  final EventAttendee attendee;
  final Event? event;

  const TeamRegistrationDetailPage({
    super.key,
    required this.attendee,
    this.event,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Team Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attendee.teamName?.trim().isNotEmpty == true
                        ? attendee.teamName!.trim()
                        : 'Unnamed Team',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registration Status: ${attendee.registrationStatus}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (attendee.registeredAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Registered ${DateFormat('dd MMM, h:mm a').format(attendee.registeredAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Team Leader Section
            Text(
              'Team Leader',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _UserProfileCard(
              user: attendee.leader,
              onTap: attendee.leader?.id != null
                  ? () {
                      context.push(
                        '/user-profile/${attendee.leader!.id!}',
                        extra: attendee.leader,
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 20),

            // Team Members Section
            if (attendee.members.isNotEmpty) ...[
              Text(
                'Team Members (${attendee.members.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...attendee.members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _UserProfileCard(
                    user: member.user,
                    role: member.role,
                    onTap: member.user?.id != null
                        ? () {
                            context.push(
                              '/user-profile/${member.user!.id!}',
                              extra: member.user,
                            );
                          }
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Custom Field Responses Section
            if (attendee.customFieldResponses.isNotEmpty) ...[
              Text(
                'Registration Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ..._buildCustomFieldCards(),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCustomFieldCards() {
    final responses = attendee.customFieldResponses;
    if (responses.isEmpty) return const [];

    final fields = event?.customFields ?? const [];
    final labelsByKey = <String, String>{
      for (final field in fields) field.key: field.label,
    };

    final orderedKeys = <String>[];
    for (final field in fields) {
      if (responses.containsKey(field.key) && responses[field.key] != null) {
        orderedKeys.add(field.key);
      }
    }

    for (final entry in responses.entries) {
      if (entry.value == null) continue;
      if (!orderedKeys.contains(entry.key)) {
        orderedKeys.add(entry.key);
      }
    }

    return orderedKeys
        .map(
          (key) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CustomFieldResponseCard(
              label: labelsByKey[key] ?? _humanizeKey(key),
              value: responses[key],
            ),
          ),
        )
        .toList(growable: false);
  }

  String _humanizeKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1) : ''}',
        )
        .join(' ');
  }
}

class _UserProfileCard extends StatelessWidget {
  final EventAttendeeUser? user;
  final String? role;
  final VoidCallback? onTap;

  const _UserProfileCard({this.user, this.role, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final username = user?.username;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: user?.profilePicUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        user!.profilePicUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const FaIcon(FontAwesomeIcons.user, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Unknown user',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (username != null && username.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '@${username.trim()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (role != null && role!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        role!.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomFieldResponseCard extends StatelessWidget {
  final String label;
  final dynamic value;

  const _CustomFieldResponseCard({required this.label, required this.value});

  String _formatValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(_formatValue(value), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
