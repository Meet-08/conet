import 'package:conet_app/core/widgets/custom_circle_avatar.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EventRegistrationDetailPage extends StatelessWidget {
  final EventAttendee attendee;
  final Event? event;

  const EventRegistrationDetailPage({
    super.key,
    required this.attendee,
    this.event,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final leaderId = attendee.leader?.id?.trim();
    final teamMembers = attendee.members
        .where((member) {
          final memberId = member.user?.id?.trim();
          if (leaderId != null && leaderId.isNotEmpty && memberId == leaderId) {
            return false;
          }
          return member.role.trim().toLowerCase() != 'leader';
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Registration Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    attendee.isTeam
                        ? attendee.teamName?.trim().isNotEmpty == true
                              ? attendee.teamName!.trim()
                              : 'Unnamed Team'
                        : attendee.user?.displayName ?? 'Unknown attendee',
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
                  if (attendee.isTeam)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${attendee.memberCount} member${attendee.memberCount == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (attendee.isTeam) ...[
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
                          '/user-profile',
                          extra: attendee.leader?.id,
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 20),
              if (teamMembers.isNotEmpty) ...[
                Text(
                  'Team Members (${teamMembers.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...teamMembers.map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _UserProfileCard(
                      user: member.user,
                      role: member.role,
                      onTap: member.user?.id != null
                          ? () {
                              context.push(
                                '/user-profile',
                                extra: member.user?.id,
                              );
                            }
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ] else ...[
              Text(
                'Attendee',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _UserProfileCard(
                user: attendee.user,
                onTap: attendee.user?.id != null
                    ? () {
                        context.push('/user-profile', extra: attendee.user?.id);
                      }
                    : null,
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Registration Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (attendee.customFieldResponses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No custom field responses submitted for this registration.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ..._buildCustomFieldCards(),
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
            CustomCircleAvatar(
              radius: 24,
              imageUrl: user?.profilePicUrl,
              displayName: user?.displayName,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Unknown attendee',
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
      width: double.infinity,
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
          Text(
            _formatValue(value),
            style: theme.textTheme.bodyMedium,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
