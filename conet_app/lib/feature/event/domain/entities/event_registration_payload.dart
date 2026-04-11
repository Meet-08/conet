import 'package:equatable/equatable.dart';

class EventRegistrationPayload extends Equatable {
  final String? teamId;
  final String? teamName;
  final int? teamSize;
  final Map<String, dynamic> customFieldResponses;
  final List<String> memberUserIds;

  const EventRegistrationPayload({
    this.teamId,
    this.teamName,
    this.teamSize,
    this.customFieldResponses = const {},
    this.memberUserIds = const [],
  });

  Map<String, dynamic> toJson() {
    String? normalizeText(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final normalizedResponses = <String, dynamic>{};
    customFieldResponses.forEach((key, value) {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          normalizedResponses[key] = trimmed;
        }
        return;
      }

      if (value is List) {
        if (value.isNotEmpty) {
          normalizedResponses[key] = value;
        }
        return;
      }

      if (value != null) {
        normalizedResponses[key] = value;
      }
    });

    final normalizedMemberIds = memberUserIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return {
      if (normalizeText(teamId) != null) 'team_id': normalizeText(teamId),
      if (normalizeText(teamName) != null) 'team_name': normalizeText(teamName),
      if (teamSize != null) 'team_size': teamSize,
      if (normalizedResponses.isNotEmpty)
        'custom_field_responses': normalizedResponses,
      if (normalizedMemberIds.isNotEmpty)
        'member_user_ids': normalizedMemberIds,
    };
  }

  @override
  List<Object?> get props => [
    teamId,
    teamName,
    teamSize,
    customFieldResponses,
    memberUserIds,
  ];
}
