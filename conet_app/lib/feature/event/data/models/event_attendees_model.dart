import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';

class EventAttendeesModel extends EventAttendees {
  const EventAttendeesModel({
    required super.eventId,
    required super.participationType,
    required super.attendees,
    required super.summary,
  });

  factory EventAttendeesModel.fromJson(Map<String, dynamic> json) {
    final attendeesJson = (json['attendees'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    return EventAttendeesModel(
      eventId: json['event_id']?.toString() ?? '',
      participationType: json['participation_type']?.toString() ?? 'individual',
      attendees: attendeesJson.map(EventAttendeesModel._parseAttendee).toList(),
      summary: EventAttendeesModel._parseSummary(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  static EventAttendee _parseAttendee(Map<String, dynamic> json) {
    final membersJson = (json['members'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    return EventAttendee(
      registrationId: json['registration_id']?.toString() ?? '',
      registrationStatus:
          json['registration_status']?.toString() ?? 'registered',
      registeredAt: DateTime.tryParse(json['registered_at']?.toString() ?? ''),
      userId: json['user_id']?.toString(),
      user: EventAttendeesModel._parseUser(
        json['user'] as Map<String, dynamic>?,
      ),
      teamId: json['team_id']?.toString(),
      teamName: json['team_name']?.toString(),
      leaderUserId: json['leader_user_id']?.toString(),
      leader: EventAttendeesModel._parseUser(
        json['leader'] as Map<String, dynamic>?,
      ),
      memberCount:
          (json['member_count'] as num?)?.toInt() ?? membersJson.length,
      members: membersJson.map(EventAttendeesModel._parseMember).toList(),
    );
  }

  static EventAttendeeMember _parseMember(Map<String, dynamic> json) {
    return EventAttendeeMember(
      userId: json['user_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'member',
      joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? ''),
      user: EventAttendeesModel._parseUser(
        json['user'] as Map<String, dynamic>?,
      ),
    );
  }

  static EventAttendeeUser? _parseUser(Map<String, dynamic>? json) {
    if (json == null) return null;

    return EventAttendeeUser(
      id: json['id']?.toString(),
      username: json['username']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      profilePicUrl: json['profile_pic_url']?.toString(),
    );
  }

  static EventAttendeesSummary _parseSummary(Map<String, dynamic> json) {
    return EventAttendeesSummary(
      registered: (json['registered'] as num?)?.toInt() ?? 0,
      attended: (json['attended'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
      totalAttendees: (json['total_attendees'] as num?)?.toInt() ?? 0,
      totalTeams: (json['total_teams'] as num?)?.toInt() ?? 0,
      totalMembers: (json['total_members'] as num?)?.toInt() ?? 0,
    );
  }
}
