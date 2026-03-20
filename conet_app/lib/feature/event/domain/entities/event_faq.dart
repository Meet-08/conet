import 'package:equatable/equatable.dart';

class EventFaq extends Equatable {
  final String question;
  final String answer;

  const EventFaq({required this.question, required this.answer});

  EventFaq copyWith({String? question, String? answer}) {
    return EventFaq(
      question: question ?? this.question,
      answer: answer ?? this.answer,
    );
  }

  @override
  List<Object?> get props => [question, answer];
}
