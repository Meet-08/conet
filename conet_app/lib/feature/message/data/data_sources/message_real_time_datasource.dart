import 'package:conet_app/feature/message/domain/entities/message.dart';

abstract interface class MessageRealTimeDatasource {
  Stream<List<Message>> watchMessages(String conversationId);
  Stream<void> watchConversationUpdates();
}
