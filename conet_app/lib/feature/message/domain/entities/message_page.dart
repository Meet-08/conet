import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:equatable/equatable.dart';

class MessagePage extends Equatable {
  final List<Message> messages;
  final bool hasMore;
  final DateTime? nextBefore;

  const MessagePage({
    required this.messages,
    required this.hasMore,
    this.nextBefore,
  });

  @override
  List<Object?> get props => [messages, hasMore, nextBefore];
}
