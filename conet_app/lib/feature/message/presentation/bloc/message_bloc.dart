import 'dart:async';

import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/usecases/message_create_conversation.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_conversations.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_messages.dart';
import 'package:conet_app/feature/message/domain/usecases/message_mark_as_read.dart';
import 'package:conet_app/feature/message/domain/usecases/message_send_message.dart';
import 'package:conet_app/feature/message/domain/usecases/message_watch_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageCreateConversation _createConversation;
  final MessageGetConversations _getConversationsUsecase;
  final MessageGetMessages _getMessages;
  final MessageSendMessage _sendMessage;
  final MessageMarkAsRead _markAsRead;
  final MessageWatchMessages _watchMessages;
  StreamSubscription<List<Message>>? _messagesSubscription;

  MessageBloc({
    required MessageCreateConversation createConversation,
    required MessageGetConversations getConversationsUsecase,
    required MessageGetMessages getMessages,
    required MessageSendMessage sendMessage,
    required MessageMarkAsRead markAsRead,
    required MessageWatchMessages watchMessages,
  }) : _createConversation = createConversation,
       _getConversationsUsecase = getConversationsUsecase,
       _getMessages = getMessages,
       _sendMessage = sendMessage,
       _markAsRead = markAsRead,
       _watchMessages = watchMessages,
       super(MessageState()) {
    on<MessageWatchStarted>(_onWatchStarted);
    on<MessageListUpdated>(_onListUpdated);
    on<MessageSent>(_onMessageSent);
    on<MessageFetchHistoryRequested>(_onFetchHistoryRequested);
    on<MessageMarkAsReadRequested>(_onMarkAsReadRequested);
    on<MessageConversationCreated>(_onConversationCreated);
    on<MessageConversationsRequested>(_onConversationsRequested);
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onConversationsRequested(
    MessageConversationsRequested event,
    Emitter<MessageState> emit,
  ) async {
    emit(state.copyWith(status: MessageStatus.loading));
    final result = await _getConversationsUsecase();
    result.fold(
      (l) => emit(
        state.copyWith(status: MessageStatus.failure, errorMessage: l.message),
      ),
      (r) =>
          emit(state.copyWith(status: MessageStatus.success, conversations: r)),
    );
  }

  Future<void> _onConversationCreated(
    MessageConversationCreated event,
    Emitter<MessageState> emit,
  ) async {
    final result = await _createConversation(userId: event.userId);
    result.fold((l) => emit(state.copyWith(errorMessage: l.message)), (r) {
      // Optionally handle success, e.g., navigate or start watching the new conversation
      // For now, we might just want to start refreshing or emit a specific state if needed
      // Assuming the UI will handle navigation or we might want to emit a "ConversationCreated" side effect if using BlocListener
    });
  }

  void _onWatchStarted(MessageWatchStarted event, Emitter<MessageState> emit) {
    _messagesSubscription?.cancel();
    emit(state.copyWith(status: MessageStatus.loading));
    _messagesSubscription = _watchMessages(event.conversationId).listen((
      messages,
    ) {
      add(MessageListUpdated(messages));
    });
  }

  void _onListUpdated(MessageListUpdated event, Emitter<MessageState> emit) {
    emit(
      state.copyWith(status: MessageStatus.success, messages: event.messages),
    );
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<MessageState> emit,
  ) async {
    final result = await _sendMessage(
      conversationId: event.conversationId,
      content: event.content,
    );
    result.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => null,
    );
  }

  Future<void> _onFetchHistoryRequested(
    MessageFetchHistoryRequested event,
    Emitter<MessageState> emit,
  ) async {
    // TODO: support pagination
    final result = await _getMessages(conversationId: event.conversationId);
    result.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => emit(state.copyWith(messages: r)),
    );
  }

  Future<void> _onMarkAsReadRequested(
    MessageMarkAsReadRequested event,
    Emitter<MessageState> emit,
  ) async {
    final result = await _markAsRead(conversationId: event.conversationId);
    result.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => null,
    );
  }
}
