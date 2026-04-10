import 'package:equatable/equatable.dart';

class EventAttendees extends Equatable {
  final String eventId;
  final String participationType;
  final List<EventAttendee> attendees;
  final EventAttendeesSummary summary;

  const EventAttendees({
    required this.eventId,
    required this.participationType,
    required this.attendees,
    required this.summary,
  });

  bool get isTeamEvent => participationType.toLowerCase() == 'team';

  @override
  List<Object?> get props => [eventId, participationType, attendees, summary];
}

class EventAttendee extends Equatable {
  final String registrationId;
  final String registrationStatus;
  final DateTime? registeredAt;
  final String? userId;
  final EventAttendeeUser? user;
  final String? teamId;
  final String? teamName;
  final String? leaderUserId;
  final EventAttendeeUser? leader;
  final int memberCount;
  final List<EventAttendeeMember> members;
  final Map<String, dynamic> customFieldResponses;

  const EventAttendee({
    required this.registrationId,
    required this.registrationStatus,
    required this.registeredAt,
    this.userId,
    this.user,
    this.teamId,
    this.teamName,
    this.leaderUserId,
    this.leader,
    this.memberCount = 0,
    this.members = const [],
    this.customFieldResponses = const {},
  });

  bool get isTeam => teamId != null && teamId!.isNotEmpty;

  @override
  List<Object?> get props => [
    registrationId,
    registrationStatus,
    registeredAt,
    userId,
    user,
    teamId,
    teamName,
    leaderUserId,
    leader,
    memberCount,
    members,
    customFieldResponses,
  ];
}

class EventAttendeeMember extends Equatable {
  final String userId;
  final String role;
  final DateTime? joinedAt;
  final EventAttendeeUser? user;

  const EventAttendeeMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.user,
  });

  @override
  List<Object?> get props => [userId, role, joinedAt, user];
}

class EventAttendeeUser extends Equatable {
  final String? id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? profilePicUrl;

  const EventAttendeeUser({
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.profilePicUrl,
  });

  String get displayName {
    final fullName = [
      firstName,
      lastName,
    ].where((name) => name != null && name.trim().isNotEmpty).join(' ').trim();

    if (fullName.isNotEmpty) return fullName;
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    return 'Unknown attendee';
  }

  @override
  List<Object?> get props => [id, username, firstName, lastName, profilePicUrl];
}

class EventAttendeesSummary extends Equatable {
  final int registered;
  final int attended;
  final int cancelled;
  final int totalAttendees;
  final int totalTeams;
  final int totalMembers;

  const EventAttendeesSummary({
    this.registered = 0,
    this.attended = 0,
    this.cancelled = 0,
    this.totalAttendees = 0,
    this.totalTeams = 0,
    this.totalMembers = 0,
  });

  @override
  List<Object?> get props => [
    registered,
    attended,
    cancelled,
    totalAttendees,
    totalTeams,
    totalMembers,
  ];
}
