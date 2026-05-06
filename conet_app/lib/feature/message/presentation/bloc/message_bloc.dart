import 'dart:async';

import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/common/usecases/user_search_users.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/group_member.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/entities/message_realtime_event.dart';
import 'package:conet_app/feature/message/domain/usecases/message_add_group_member.dart';
import 'package:conet_app/feature/message/domain/usecases/message_create_conversation.dart';
import 'package:conet_app/feature/message/domain/usecases/message_create_group.dart';
import 'package:conet_app/feature/message/domain/usecases/message_delete_group.dart';
import 'package:conet_app/feature/message/domain/usecases/message_demote_group_member.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_conversations.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_group_members.dart';
import 'package:conet_app/feature/message/domain/usecases/message_get_messages.dart';
import 'package:conet_app/feature/message/domain/usecases/message_mark_as_read.dart';
import 'package:conet_app/feature/message/domain/usecases/message_promote_group_member.dart';
import 'package:conet_app/feature/message/domain/usecases/message_remove_group_member.dart';
import 'package:conet_app/feature/message/domain/usecases/message_send_message.dart';
import 'package:conet_app/feature/message/domain/usecases/message_update_group.dart';
import 'package:conet_app/feature/message/domain/usecases/message_watch_conversation_updates.dart';
import 'package:conet_app/feature/message/domain/usecases/message_watch_messages.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  static const int _messagePageSize = 20;
  static const Duration _markAsReadCooldown = Duration(milliseconds: 1200);

  final MessageCreateConversation _createConversation;
  final MessageGetConversations _getConversationsUsecase;
  final MessageGetMessages _getMessages;
  final MessageSendMessage _sendMessage;
  final MessageMarkAsRead _markAsRead;
  final MessageWatchMessages _watchMessages;
  final MessageWatchConversationUpdates _watchConversationUpdates;
  final UserSearchUsers _searchUsers;
  final MessageCreateGroup _createGroup;
  final MessageUpdateGroup _updateGroup;
  final MessageDeleteGroup _deleteGroup;
  final MessageGetGroupMembers _getGroupMembers;
  final MessageAddGroupMember _addGroupMember;
  final MessageRemoveGroupMember _removeGroupMember;
  final MessagePromoteGroupMember _promoteGroupMember;
  final MessageDemoteGroupMember _demoteGroupMember;
  final String? Function() _getCurrentUserId;
  StreamSubscription<MessageRealtimeEvent>? _messagesSubscription;
  StreamSubscription<void>? _globalSubscription;
  String? _globalSubscriptionUserId;
  int _searchToken = 0;
  final Set<String> _markAsReadInFlightConversations = {};
  final Map<String, DateTime> _lastMarkAsReadAt = {};

  MessageBloc({
    required MessageCreateConversation createConversation,
    required MessageGetConversations getConversationsUsecase,
    required MessageGetMessages getMessages,
    required MessageSendMessage sendMessage,
    required MessageMarkAsRead markAsRead,
    required MessageWatchMessages watchMessages,
    required MessageWatchConversationUpdates watchConversationUpdates,
    required UserSearchUsers searchUsers,
    required MessageCreateGroup createGroup,
    required MessageUpdateGroup updateGroup,
    required MessageDeleteGroup deleteGroup,
    required MessageGetGroupMembers getGroupMembers,
    required MessageAddGroupMember addGroupMember,
    required MessageRemoveGroupMember removeGroupMember,
    required MessagePromoteGroupMember promoteGroupMember,
    required MessageDemoteGroupMember demoteGroupMember,
    String? Function()? getCurrentUserId,
  }) : _createConversation = createConversation,
       _getConversationsUsecase = getConversationsUsecase,
       _getMessages = getMessages,
       _sendMessage = sendMessage,
       _markAsRead = markAsRead,
       _watchMessages = watchMessages,
       _watchConversationUpdates = watchConversationUpdates,
       _searchUsers = searchUsers,
       _createGroup = createGroup,
       _updateGroup = updateGroup,
       _deleteGroup = deleteGroup,
       _getGroupMembers = getGroupMembers,
       _addGroupMember = addGroupMember,
       _removeGroupMember = removeGroupMember,
       _promoteGroupMember = promoteGroupMember,
       _demoteGroupMember = demoteGroupMember,
       _getCurrentUserId =
           (getCurrentUserId ??
           (() => Supabase.instance.client.auth.currentUser?.id)),
       super(
         MessageState(
           currentUserId:
               (getCurrentUserId ??
               (() => Supabase.instance.client.auth.currentUser?.id))(),
         ),
       ) {
    on<MessageWatchStarted>(_onWatchStarted);
    on<MessageWatchStopped>(_onWatchStopped);
    on<MessageRealtimeReceived>(_onRealtimeReceived);
    on<MessageSent>(_onMessageSent);
    on<MessageFetchHistoryRequested>(_onFetchHistoryRequested);
    on<MessageMarkAsReadRequested>(_onMarkAsReadRequested);
    on<MessageConversationCreated>(_onConversationCreated);
    on<MessageGroupCreated>(_onGroupCreated);
    on<MessageConversationsRequested>(_onConversationsRequested);
    on<MessageFilterChanged>(_onFilterChanged);
    on<MessageConversationRealtimePinged>(_onConversationRealtimePinged);
    on<MessageUserSearchRequested>(_onUserSearchRequested);
    on<MessageUserSearchCleared>(_onUserSearchCleared);
    on<MessageCreatedConversationHandled>(_onCreatedConversationHandled);
    on<MessageGroupUpdated>(_onGroupUpdated);
    on<MessageGroupDeleted>(_onGroupDeleted);
    on<MessageGroupMembersRequested>(_onGroupMembersRequested);
    on<MessageGroupMemberAdded>(_onGroupMemberAdded);
    on<MessageGroupMemberRemoved>(_onGroupMemberRemoved);
    on<MessageGroupMemberPromoted>(_onGroupMemberPromoted);
    on<MessageGroupMemberDemoted>(_onGroupMemberDemoted);

    // Initial global subscription setup
    _initGlobalSubscription();
  }

  void _initGlobalSubscription() {
    final currentUserId = _getCurrentUserId();
    final hasExistingSubscription = _globalSubscription != null;
    final isSameUser = _globalSubscriptionUserId == currentUserId;

    if (hasExistingSubscription && isSameUser) {
      return;
    }

    _globalSubscription?.cancel();
    _globalSubscriptionUserId = currentUserId;
    _globalSubscription = _watchConversationUpdates().listen((_) {
      add(MessageConversationRealtimePinged());
    });
  }

  void _onConversationRealtimePinged(
    MessageConversationRealtimePinged event,
    Emitter<MessageState> emit,
  ) {
    emit(state.copyWith(lastConversationRealtimeAt: DateTime.now()));
    add(MessageConversationsRequested());
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _globalSubscription?.cancel();
    _markAsReadInFlightConversations.clear();
    _lastMarkAsReadAt.clear();
    return super.close();
  }

  Future<void> _onConversationsRequested(
    MessageConversationsRequested event,
    Emitter<MessageState> emit,
  ) async {
    _initGlobalSubscription();

    final hasExplicitSearchQuery = event.searchQuery != null;
    final normalizedSearchQuery = event.searchQuery?.trim();
    final searchQuery = hasExplicitSearchQuery
        ? (normalizedSearchQuery == null || normalizedSearchQuery.isEmpty
              ? null
              : normalizedSearchQuery)
        : state.conversationSearchQuery;

    if (hasExplicitSearchQuery) {
      emit(state.copyWith(conversationSearchQuery: searchQuery));
    }

    final shouldShowLoading =
        state.conversations.isEmpty &&
        state.conversationStatus != MessageStatus.success;
    if (shouldShowLoading) {
      emit(state.copyWith(conversationStatus: MessageStatus.loading));
    }

    final result = searchQuery == null
        ? await _getConversationsUsecase(type: state.conversationFilter)
        : await _getConversationsUsecase(
            type: state.conversationFilter,
            search: searchQuery,
          );
    result.fold(
      (l) {
        if (state.conversations.isNotEmpty) {
          emit(state.copyWith(errorMessage: l.message));
          return;
        }
        emit(
          state.copyWith(
            conversationStatus: MessageStatus.failure,
            errorMessage: l.message,
          ),
        );
      },
      (r) => emit(
        state.copyWith(
          conversationStatus: MessageStatus.success,
          conversations: r,
          conversationSearchQuery: searchQuery,
        ),
      ),
    );
  }

  Future<void> _onConversationCreated(
    MessageConversationCreated event,
    Emitter<MessageState> emit,
  ) async {
    emit(state.copyWith(conversationStatus: MessageStatus.loading));
    final result = await _createConversation(userId: event.userId);
    result.fold(
      (l) => emit(
        state.copyWith(
          conversationStatus: MessageStatus.failure,
          errorMessage: l.message,
        ),
      ),
      (r) {
        emit(
          state.copyWith(
            conversationStatus: MessageStatus.success,
            createdConversation: r,
            userSuggestions: const [],
            userSearchError: null,
            isSearchingUsers: false,
          ),
        );
        add(MessageConversationsRequested());
      },
    );
  }

  void _onCreatedConversationHandled(
    MessageCreatedConversationHandled event,
    Emitter<MessageState> emit,
  ) {
    emit(state.copyWith(clearCreatedConversation: true));
  }

  Future<void> _onGroupCreated(
    MessageGroupCreated event,
    Emitter<MessageState> emit,
  ) async {
    emit(state.copyWith(conversationStatus: MessageStatus.loading));
    final result = await _createGroup(
      name: event.name,
      description: event.description,
      memberIds: event.userIds,
      onlyAdminAddMembers: event.onlyAdminAddMembers,
      onlyAdminRemoveMembers: event.onlyAdminRemoveMembers,
      onlyAdminEditGroup: event.onlyAdminEditGroup,
      groupImageFile: event.groupImageFile,
    );
    result.fold(
      (l) => emit(
        state.copyWith(
          conversationStatus: MessageStatus.failure,
          errorMessage: l.message,
        ),
      ),
      (r) {
        emit(
          state.copyWith(
            conversationStatus: MessageStatus.success,
            createdConversation: r,
            userSuggestions: const [],
            userSearchError: null,
            isSearchingUsers: false,
          ),
        );
        add(MessageConversationsRequested());
      },
    );
  }

  void _onFilterChanged(
    MessageFilterChanged event,
    Emitter<MessageState> emit,
  ) {
    emit(state.copyWith(conversationFilter: event.filter));
    add(MessageConversationsRequested());
  }

  Future<void> _onGroupUpdated(
    MessageGroupUpdated event,
    Emitter<MessageState> emit,
  ) async {
    final result = await _updateGroup(
      groupId: event.groupId,
      name: event.name,
      description: event.description,
      groupImageUrl: event.groupImageUrl,
      onlyAdminAddMembers: event.onlyAdminAddMembers,
      onlyAdminRemoveMembers: event.onlyAdminRemoveMembers,
      onlyAdminEditGroup: event.onlyAdminEditGroup,
      onlyAdminSendMessages: event.onlyAdminSendMessages,
      groupImageFile: event.groupImageFile,
    );
    result.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => add(MessageConversationsRequested()),
    );
  }

  Future<void> _onGroupDeleted(
    MessageGroupDeleted event,
    Emitter<MessageState> emit,
  ) async {
    final result = await _deleteGroup(groupId: event.groupId);
    result.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => add(MessageConversationsRequested()),
    );
  }

  Future<void> _onGroupMembersRequested(
    MessageGroupMembersRequested event,
    Emitter<MessageState> emit,
  ) async {
    final result = await _getGroupMembers(groupId: event.groupId);
    result.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => emit(state.copyWith(groupMembers: r)),
    );
  }

  Future<void> _onGroupMemberAdded(
    MessageGroupMemberAdded event,
    Emitter<MessageState> emit,
  ) async {
    final result = await _addGroupMember(
      groupId: event.groupId,
      userId: event.userId,
    );
    result.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => add(MessageGroupMembersRequested(event.groupId)),
    );
  }

  Future<void> _onGroupMemberRemoved(
    MessageGroupMemberRemoved event,
    Emitter<MessageState> emit,
  ) async {
    final result = await _removeGroupMember(
      groupId: event.groupId,
      userId: event.userId,
    );
    result.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => add(MessageGroupMembersRequested(event.groupId)),
    );
  }

  Future<void> _onGroupMemberPromoted(
    MessageGroupMemberPromoted event,
    Emitter<MessageState> emit,
  ) async {
    final result = await _promoteGroupMember(
      groupId: event.groupId,
      userId: event.userId,
    );
    result.fold((l) => emit(state.copyWith(errorMessage: l.message)), (r) {
      add(MessageGroupMembersRequested(event.groupId));
      add(MessageConversationsRequested());
    });
  }

  Future<void> _onGroupMemberDemoted(
    MessageGroupMemberDemoted event,
    Emitter<MessageState> emit,
  ) async {
    final result = await _demoteGroupMember(
      groupId: event.groupId,
      userId: event.userId,
    );
    result.fold((l) => emit(state.copyWith(errorMessage: l.message)), (r) {
      add(MessageGroupMembersRequested(event.groupId));
      add(MessageConversationsRequested());
    });
  }

  Future<void> _onWatchStarted(
    MessageWatchStarted event,
    Emitter<MessageState> emit,
  ) async {
    _messagesSubscription?.cancel();
    emit(
      state.copyWith(
        messageStatus: MessageStatus.loading,
        messages: const [],
        activeConversationId: event.conversationId,
        isFetchingHistory: false,
        hasMoreHistory: true,
        clearNextBeforeCursor: true,
      ),
    );

    final initialResult = await _getMessages(
      conversationId: event.conversationId,
      limit: _messagePageSize,
    );

    initialResult.fold(
      (l) => emit(
        state.copyWith(
          messageStatus: MessageStatus.failure,
          errorMessage: l.message,
        ),
      ),
      (page) {
        emit(
          state.copyWith(
            messageStatus: MessageStatus.success,
            messages: page.messages,
            hasMoreHistory: page.hasMore,
            nextBeforeCursor: page.nextBefore,
          ),
        );
        _requestMarkAsRead(event.conversationId, force: true);
      },
    );

    _messagesSubscription = _watchMessages(event.conversationId).listen((
      realtimeEvent,
    ) {
      add(MessageRealtimeReceived(realtimeEvent, event.conversationId));
    });
  }

  void _onWatchStopped(MessageWatchStopped event, Emitter<MessageState> emit) {
    if (state.activeConversationId != event.conversationId) {
      return;
    }

    _messagesSubscription?.cancel();
    _messagesSubscription = null;

    emit(
      state.copyWith(
        messages: const [],
        messageStatus: MessageStatus.initial,
        activeConversationId: null,
        isFetchingHistory: false,
        hasMoreHistory: true,
        clearNextBeforeCursor: true,
      ),
    );

    add(MessageConversationsRequested());
  }

  void _onRealtimeReceived(
    MessageRealtimeReceived event,
    Emitter<MessageState> emit,
  ) {
    if (state.activeConversationId != event.conversationId) {
      return;
    }

    final currentMessages = List<Message>.from(state.messages);
    final eventType = event.realtimeEvent.type;
    final realtimeMessage = event.realtimeEvent.message;

    if (eventType == MessageRealtimeEventType.deleted) {
      currentMessages.removeWhere((m) => m.id == event.realtimeEvent.messageId);
    } else if (realtimeMessage != null) {
      final existingIndex = currentMessages.indexWhere(
        (m) => m.id == realtimeMessage.id,
      );
      if (existingIndex == -1) {
        final pendingIndex = _findMatchingPendingMessageIndex(
          currentMessages,
          realtimeMessage,
        );
        if (pendingIndex != -1) {
          currentMessages[pendingIndex] = realtimeMessage;
        } else {
          currentMessages.add(realtimeMessage);
        }
      } else {
        currentMessages[existingIndex] = realtimeMessage;
      }
    }

    final merged = _dedupeById(currentMessages);
    emit(
      state.copyWith(messageStatus: MessageStatus.success, messages: merged),
    );

    _markUnreadFromOthers(merged, event.conversationId);
  }

  void _markUnreadFromOthers(List<Message> messages, String conversationId) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId != null) {
      final hasUnreadFromOthers = messages.any(
        (m) => !m.isRead && m.senderId != currentUserId,
      );
      if (hasUnreadFromOthers) {
        _requestMarkAsRead(conversationId);
      }
    }
  }

  void _requestMarkAsRead(String conversationId, {bool force = false}) {
    if (_markAsReadInFlightConversations.contains(conversationId)) {
      return;
    }

    final lastSentAt = _lastMarkAsReadAt[conversationId];
    if (!force && lastSentAt != null) {
      final elapsed = DateTime.now().difference(lastSentAt);
      if (elapsed < _markAsReadCooldown) {
        return;
      }
    }

    _lastMarkAsReadAt[conversationId] = DateTime.now();
    add(MessageMarkAsReadRequested(conversationId));
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<MessageState> emit,
  ) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return;

    final tempId = const Uuid().v4();
    final tempMessage = Message(
      id: tempId,
      conversationId: event.conversationId,
      senderId: currentUserId,
      content: event.content,
      createdAt: DateTime.now(),
      status: MessageDeliveryStatus.pending,
      mediaUrls: event.mediaUrls ?? [],
    );

    // Optimistic update
    final currentMessages = List<Message>.from(state.messages)
      ..add(tempMessage);
    emit(state.copyWith(messages: currentMessages));

    final result = await _sendMessage(
      conversationId: event.conversationId,
      content: event.content,
      mediaUrls: event.mediaUrls,
      files: event.files,
    );

    result.fold(
      (l) {
        final messages = List<Message>.from(state.messages);
        final index = messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          messages[index] = Message(
            id: tempMessage.id,
            conversationId: tempMessage.conversationId,
            senderId: tempMessage.senderId,
            content: tempMessage.content,
            createdAt: tempMessage.createdAt,
            status: MessageDeliveryStatus.error,
            mediaUrls: tempMessage.mediaUrls,
            isRead: tempMessage.isRead,
          );
          emit(state.copyWith(messages: messages, errorMessage: l.message));
        } else {
          emit(state.copyWith(errorMessage: l.message));
        }
      },
      (r) {
        final messages = List<Message>.from(state.messages);
        final index = messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          messages[index] = r;
        } else {
          final existingServerMessageIndex = messages.indexWhere(
            (m) => m.id == r.id,
          );
          if (existingServerMessageIndex == -1) {
            messages.add(r);
          } else {
            messages[existingServerMessageIndex] = r;
          }
        }

        emit(state.copyWith(messages: _dedupeById(messages)));

        add(MessageConversationsRequested());
      },
    );
  }

  Future<void> _onFetchHistoryRequested(
    MessageFetchHistoryRequested event,
    Emitter<MessageState> emit,
  ) async {
    if (state.activeConversationId != event.conversationId) return;
    if (state.isFetchingHistory || !state.hasMoreHistory) return;

    emit(state.copyWith(isFetchingHistory: true));
    final result = await _getMessages(
      conversationId: event.conversationId,
      limit: _messagePageSize,
      before: state.nextBeforeCursor,
    );
    result.fold(
      (l) => emit(
        state.copyWith(isFetchingHistory: false, errorMessage: l.message),
      ),
      (page) {
        final merged = _dedupeById([...state.messages, ...page.messages]);
        emit(
          state.copyWith(
            isFetchingHistory: false,
            messages: merged,
            hasMoreHistory: page.hasMore,
            nextBeforeCursor: page.nextBefore,
          ),
        );
      },
    );
  }

  Future<void> _onMarkAsReadRequested(
    MessageMarkAsReadRequested event,
    Emitter<MessageState> emit,
  ) async {
    if (_markAsReadInFlightConversations.contains(event.conversationId)) {
      return;
    }

    _markAsReadInFlightConversations.add(event.conversationId);

    final currentUserId = _getCurrentUserId();
    final nextMessages =
        state.activeConversationId == event.conversationId &&
            currentUserId != null
        ? state.messages
              .map(
                (message) =>
                    message.senderId != currentUserId && !message.isRead
                    ? Message(
                        id: message.id,
                        conversationId: message.conversationId,
                        senderId: message.senderId,
                        content: message.content,
                        createdAt: message.createdAt,
                        status: message.status,
                        mediaUrls: message.mediaUrls,
                        isRead: true,
                      )
                    : message,
              )
              .toList()
        : state.messages;

    final updatedConversations = state.conversations
        .map(
          (conversation) => conversation.id == event.conversationId
              ? Conversation(
                  id: conversation.id,
                  type: conversation.type,
                  otherUser: conversation.otherUser,
                  name: conversation.name,
                  description: conversation.description,
                  groupImageUrl: conversation.groupImageUrl,
                  createdBy: conversation.createdBy,
                  onlyAdminAddMembers: conversation.onlyAdminAddMembers,
                  onlyAdminRemoveMembers: conversation.onlyAdminRemoveMembers,
                  onlyAdminEditGroup: conversation.onlyAdminEditGroup,
                  onlyAdminSendMessages: conversation.onlyAdminSendMessages,
                  currentUserRole: conversation.currentUserRole,
                  members: conversation.members,
                  lastMessage: conversation.lastMessage,
                  updatedAt: conversation.updatedAt,
                  unreadCount: 0,
                  lastMessageMediaUrls: conversation.lastMessageMediaUrls,
                  isEvent: conversation.isEvent,
                )
              : conversation,
        )
        .toList();

    emit(
      state.copyWith(
        messages: nextMessages,
        conversations: updatedConversations,
      ),
    );

    final result = await _markAsRead(conversationId: event.conversationId);
    result.fold(
      (l) => emit(state.copyWith(errorMessage: l.message)),
      (r) => null,
    );

    _markAsReadInFlightConversations.remove(event.conversationId);
  }

  Future<void> _onUserSearchRequested(
    MessageUserSearchRequested event,
    Emitter<MessageState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          userSuggestions: const [],
          userSearchError: null,
          isSearchingUsers: false,
        ),
      );
      return;
    }

    final token = ++_searchToken;
    emit(state.copyWith(isSearchingUsers: true, userSearchError: null));
    await Future.delayed(const Duration(milliseconds: 350));
    if (token != _searchToken) return;

    final result = await _searchUsers(query: query, limit: 3);
    result.fold(
      (l) => emit(
        state.copyWith(isSearchingUsers: false, userSearchError: l.message),
      ),
      (r) => emit(state.copyWith(isSearchingUsers: false, userSuggestions: r)),
    );
  }

  void _onUserSearchCleared(
    MessageUserSearchCleared event,
    Emitter<MessageState> emit,
  ) {
    emit(
      state.copyWith(
        userSuggestions: const [],
        userSearchError: null,
        isSearchingUsers: false,
      ),
    );
  }

  List<Message> _dedupeById(List<Message> messages) {
    final map = <String, Message>{
      for (final message in messages) message.id: message,
    };
    final unique = map.values.toList();
    unique.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return unique;
  }

  int _findMatchingPendingMessageIndex(
    List<Message> messages,
    Message incomingMessage,
  ) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null || incomingMessage.senderId != currentUserId) {
      return -1;
    }

    for (var index = 0; index < messages.length; index++) {
      final message = messages[index];
      if (message.status != MessageDeliveryStatus.pending) {
        continue;
      }
      if (message.senderId != incomingMessage.senderId) {
        continue;
      }
      if (message.conversationId != incomingMessage.conversationId) {
        continue;
      }
      if (message.content != incomingMessage.content) {
        continue;
      }
      if (!_sameMediaUrls(message.mediaUrls, incomingMessage.mediaUrls)) {
        continue;
      }

      final timeDelta = message.createdAt.difference(incomingMessage.createdAt);
      if (timeDelta.inSeconds.abs() > 15) {
        continue;
      }

      return index;
    }

    return -1;
  }

  bool _sameMediaUrls(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }
    return true;
  }
}
