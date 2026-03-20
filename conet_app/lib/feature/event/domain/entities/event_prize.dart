import 'package:equatable/equatable.dart';

class EventPrize extends Equatable {
  final String position;
  final String prize;

  const EventPrize({required this.position, required this.prize});

  EventPrize copyWith({String? position, String? prize}) {
    return EventPrize(
      position: position ?? this.position,
      prize: prize ?? this.prize,
    );
  }

  @override
  List<Object?> get props => [position, prize];
}
