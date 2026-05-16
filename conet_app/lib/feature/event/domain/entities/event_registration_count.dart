import 'package:equatable/equatable.dart';

class EventRegistrationCount extends Equatable {
  final String label;
  final int count;

  const EventRegistrationCount({required this.label, required this.count});

  @override
  List<Object?> get props => [label, count];
}
