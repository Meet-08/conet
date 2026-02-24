import 'package:conet_app/feature/message/domain/entities/message_realtime_event.dart';

abstract interface class MessageRealTimeDatasource {
  Stream<MessageRealtimeEvent> watchMessages(String conversationId);
  Stream<void> watchConversationUpdates();
}
