import 'package:equatable/equatable.dart';

class UserAcademics extends Equatable {
  final String id;
  final String userId;
  final String collegeName;
  final String course;
  final String? major;
  final int? startYear;
  final int? endYear;
  final DateTime createdAt;

  const UserAcademics({
    required this.id,
    required this.userId,
    required this.collegeName,
    required this.course,
    this.major,
    this.startYear,
    this.endYear,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    collegeName,
    course,
    major,
    startYear,
    endYear,
    createdAt,
  ];
}
