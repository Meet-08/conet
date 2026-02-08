import 'package:conet_app/feature/message/domain/entities/message.dart';
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

  final tMessageList = [tMessage];

  group('MessageWatchMessages', () {
    test('should return stream of messages from repository', () {
      when(
        () => mockMessageRepository.watchMessages(any()),
      ).thenAnswer((_) => Stream.value(tMessageList));

      final stream = usecase(tConversationId);

      expect(stream, isA<Stream<List<Message>>>());
      verify(
        () => mockMessageRepository.watchMessages(tConversationId),
      ).called(1);
    });

    test('should emit message updates', () async {
      final tNewMessage = Message(
        id: 'message-456',
        conversationId: tConversationId,
        senderId: 'user-456',
        content: 'New message',
        createdAt: DateTime(2024, 1, 2),
        isRead: false,
      );
      final updatedMessageList = [...tMessageList, tNewMessage];

      when(() => mockMessageRepository.watchMessages(any())).thenAnswer(
        (_) => Stream.fromIterable([tMessageList, updatedMessageList]),
      );

      final stream = usecase(tConversationId);
      final emissions = await stream.toList();

      expect(emissions.length, 2);
      expect(emissions[0].length, 1);
      expect(emissions[1].length, 2);
    });

    test('should emit empty list when no messages', () async {
      when(
        () => mockMessageRepository.watchMessages(any()),
      ).thenAnswer((_) => Stream.value(<Message>[]));

      final stream = usecase(tConversationId);
      final emissions = await stream.toList();

      expect(emissions.length, 1);
      expect(emissions[0].isEmpty, true);
    });

    test('should emit messages with media URLs in stream', () async {
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

      when(
        () => mockMessageRepository.watchMessages(any()),
      ).thenAnswer((_) => Stream.value([tMessageWithMedia]));

      // act
      final stream = usecase(tConversationId);
      final emissions = await stream.toList();

      // assert
      expect(emissions.length, 1);
      expect(emissions[0].first.mediaUrls.length, 1);
      expect(
        emissions[0].first.mediaUrls.first,
        'https://example.com/video.mp4',
      );
    });
  });
}
