import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/entities/message_realtime_event.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:conet_app/feature/message/domain/usecases/message_watch_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MessageWatchMessages usecase;
  late MockMessageRepository mockMessageRepository;

  setUp(() {
    mockMessageRepository = MockMessageRepository();
    usecase = MessageWatchMessages(messageRepository: mockMessageRepository);
  });

  const tConversationId = 'conversation-123';
  final tMessage = Message(
    id: 'message-123',
    conversationId: tConversationId,
    senderId: 'user-123',
    content: 'Hello, this is a test message',
    createdAt: DateTime(2024, 1, 1),
    isRead: false,
  );

  final tMessageRealtimeEvent = MessageRealtimeEvent(
    type: MessageRealtimeEventType.inserted,
    conversationId: tConversationId,
    messageId: 'message-123',
    message: tMessage,
  );

  group('MessageWatchMessages', () {
    test('should return stream of MessageRealtimeEvent from repository', () {
      when(
        () => mockMessageRepository.watchMessages(any()),
      ).thenAnswer((_) => Stream.value(tMessageRealtimeEvent));

      final stream = usecase(tConversationId);

      expect(stream, isA<Stream<MessageRealtimeEvent>>());
      verify(
        () => mockMessageRepository.watchMessages(tConversationId),
      ).called(1);
    });

    test('should emit MessageRealtimeEvent updates', () async {
      final tNewMessage = Message(
        id: 'message-456',
        conversationId: tConversationId,
        senderId: 'user-456',
        content: 'New message',
        createdAt: DateTime(2024, 1, 2),
        isRead: false,
      );
      final tUpdateEvent = MessageRealtimeEvent(
        type: MessageRealtimeEventType.inserted,
        conversationId: tConversationId,
        messageId: 'message-456',
        message: tNewMessage,
      );

      when(() => mockMessageRepository.watchMessages(any())).thenAnswer(
        (_) => Stream.fromIterable([tMessageRealtimeEvent, tUpdateEvent]),
      );

      final stream = usecase(tConversationId);
      final emissions = await stream.toList();

      expect(emissions.length, 2);
      expect(emissions[0].messageId, 'message-123');
      expect(emissions[1].messageId, 'message-456');
    });

    test('should emit MessageRealtimeEvent with deleted type', () async {
      final tDeleteEvent = const MessageRealtimeEvent(
        type: MessageRealtimeEventType.deleted,
        conversationId: tConversationId,
        messageId: 'message-123',
      );
      when(
        () => mockMessageRepository.watchMessages(any()),
      ).thenAnswer((_) => Stream.value(tDeleteEvent));

      final stream = usecase(tConversationId);
      final emissions = await stream.toList();

      expect(emissions.length, 1);
      expect(emissions[0].type, MessageRealtimeEventType.deleted);
    });

    test(
      'should emit MessageRealtimeEvent with media URLs in stream',
      () async {
        // arrange
        final tMessageWithMedia = Message(
          id: 'message-789',
          conversationId: tConversationId,
          senderId: 'user-789',
          content: 'Message with media',
          createdAt: DateTime(2024, 1, 3),
          isRead: false,
          mediaUrls: const ['https://example.com/video.mp4'],
        );
        final tEventWithMedia = MessageRealtimeEvent(
          type: MessageRealtimeEventType.inserted,
          conversationId: tConversationId,
          messageId: 'message-789',
          message: tMessageWithMedia,
        );

        when(
          () => mockMessageRepository.watchMessages(any()),
        ).thenAnswer((_) => Stream.value(tEventWithMedia));

        // act
        final stream = usecase(tConversationId);
        final emissions = await stream.toList();

        // assert
        expect(emissions.length, 1);
        expect(emissions[0].message!.mediaUrls.length, 1);
        expect(
          emissions[0].message!.mediaUrls.first,
          'https://example.com/video.mp4',
        );
      },
    );
  });
}
