import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/error/error_handler.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/event/data/data_sources/event_data_source.dart';
import 'package:conet_app/feature/event/data/models/event_attendance_result_model.dart';
import 'package:conet_app/feature/event/data/models/event_attendees_model.dart';
import 'package:conet_app/feature/event/data/models/event_create_payload_model.dart';
import 'package:conet_app/feature/event/data/models/event_model.dart';
import 'package:conet_app/feature/event/data/models/event_page_model.dart';
import 'package:conet_app/feature/event/data/models/event_registration_ticket_model.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_custom_field.dart';
import 'package:conet_app/feature/event/domain/entities/event_register_response.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';
import 'package:conet_app/main.dart';
import 'package:uuid/uuid.dart';

class EventDataSourceImpl implements EventDataSource {
  final DioClient _dioClient;
  final FileUploadDataSource _fileUploadDataSource;

  EventDataSourceImpl({
    required DioClient dioClient,
    required FileUploadDataSource fileUploadDataSource,
  }) : _dioClient = dioClient,
       _fileUploadDataSource = fileUploadDataSource;

  @override
  Future<Event> getEventById(String eventId) async {
    try {
      final response = await _dioClient.dio.get('/events/$eventId');

      if (response.statusCode != 200) {
        throw ServerException('Failed to fetch event');
      }

      final data = response.data as Map<String, dynamic>;
      return EventModel.fromJson(data['event'] as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<EventPageModel> getPublishedEvents({
    int limit = 20,
    String? cursor,
    String? category,
    String? locationType,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/events',
        queryParameters: {
          'page_size': limit,
          if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor,
          if (category != null && category.trim().isNotEmpty)
            'category': category.trim(),
          if (locationType != null && locationType.trim().isNotEmpty)
            'location_type': locationType.trim(),
          if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
          if (dateTo != null) 'date_to': dateTo.toIso8601String(),
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to fetch published events');
      }

      return EventPageModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<EventPageModel> getMyEvents({
    required String type,
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/events/my',
        queryParameters: {
          'type': type,
          'page_size': limit,
          if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to fetch my events');
      }

      return EventPageModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<EventPageModel> getMyOrganizedEvents({
    String? status,
    String? timeline,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/events/organized',
        queryParameters: {
          'page_size': limit,
          if (status != null && status.trim().isNotEmpty)
            'status': status.trim(),
          if (timeline != null && timeline.trim().isNotEmpty)
            'timeline': timeline.trim(),
          if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
          if (dateTo != null) 'date_to': dateTo.toIso8601String(),
          if (cursor != null && cursor.trim().isNotEmpty) 'cursor': cursor,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to fetch organized events');
      }

      return EventPageModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<EventRegisterResponse> registerEvent(
    String eventId,
    EventRegistrationPayload payload,
  ) async {
    try {
      final requestBody = payload.toJson();

      final response = await _dioClient.dio.post(
        '/events/$eventId/register',
        data: requestBody,
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to register event');
      }

      final data = response.data as Map<String, dynamic>;
      final eventResult = EventModel.fromJson(
        data['event'] as Map<String, dynamic>,
      );
      final registration = data['registration'] as Map<String, dynamic>;
      final registrationId =
          (registration['id'] ?? registration['registration_id'])?.toString();

      if (registrationId == null || registrationId.trim().isEmpty) {
        throw ServerException('Registration ID missing in register response');
      }

      return EventRegisterResponse(
        event: eventResult,
        registrationId: registrationId,
      );
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<EventAttendanceResultModel> saveEvent(String eventId) async {
    try {
      final response = await _dioClient.dio.post('/events/$eventId/save');

      if (response.statusCode != 200) {
        throw ServerException('Failed to save event');
      }

      return EventAttendanceResultModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<EventRegistrationTicketModel> getRegistrationInfo(
    String eventId,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        '/events/$eventId/registration-info',
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to fetch registration info');
      }

      final data = response.data as Map<String, dynamic>;
      return EventRegistrationTicketModel.fromJson(
        data['registration'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<EventAttendeesModel> getEventAttendees({
    required String eventId,
    String? status,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/events/$eventId/attendees',
        queryParameters: {
          if (status != null && status.trim().isNotEmpty) 'status': status,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to fetch attendees');
      }

      return EventAttendeesModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<EventAttendanceResultModel> markAttendance({
    required String eventId,
    required String userId,
    required String registrationId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/events/$eventId/attend',
        data: {
          'event_id': eventId,
          'user_id': userId,
          'registration_id': registrationId,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to mark attendance');
      }

      return EventAttendanceResultModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Event> publishEvent(EventCreatePayload payload) async {
    try {
      return await _createEvent(payload, publish: true, syncCohosts: false);
    } catch (e) {
      logger.e('publishEvent failed', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Event> updateEvent(String eventId, EventCreatePayload payload) async {
    try {
      return await _updateEventInternal(
        eventId: eventId,
        payload: payload,
        publish: true,
      );
    } catch (e) {
      logger.e('updateEvent failed', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Event> updateDraftEvent(
    String eventId,
    EventCreatePayload payload,
  ) async {
    try {
      return await _updateEventInternal(
        eventId: eventId,
        payload: payload,
        publish: false,
      );
    } catch (e) {
      logger.e('updateDraftEvent failed', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  Future<Event> _updateEventInternal({
    required String eventId,
    required EventCreatePayload payload,
    required bool publish,
  }) async {
    String? imageUrl = payload.eventImageUrl?.trim();
    if (payload.eventImage != null) {
      final urls = await _fileUploadDataSource.uploadFiles(
        files: [payload.eventImage!],
        bucket: 'event',
        folder: eventId,
      );
      imageUrl = urls.isNotEmpty ? urls.first : imageUrl;
    }

    final resolvedCustomFields = await _uploadCustomFieldImages(
      eventId: eventId,
      customFields: payload.customFields,
    );
    final payloadWithUploadedFieldImages = payload.copyWith(
      customFields: resolvedCustomFields,
    );

    final requestBody = EventCreatePayloadModel.fromEntity(
      payloadWithUploadedFieldImages,
      publish: publish,
    ).toJson();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      requestBody['event_image_url'] = imageUrl;
    }

    final response = await _dioClient.dio.put(
      '/events/$eventId',
      data: requestBody,
    );

    if (response.statusCode != 200) {
      throw ServerException('Failed to update event');
    }

    final data = response.data as Map<String, dynamic>;
    return EventModel.fromJson(data['event'] as Map<String, dynamic>);
  }

  @override
  Future<Event> publishDraftById(String eventId) async {
    try {
      final response = await _dioClient.dio.patch('/events/$eventId/publish');

      if (response.statusCode != 200) {
        throw ServerException('Failed to publish event');
      }

      final data = response.data as Map<String, dynamic>;
      return EventModel.fromJson(data['event'] as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Event> updateEventConversationId({
    required String eventId,
    required String conversationId,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '/events/$eventId',
        data: {'conversation_id': conversationId},
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to update event conversation');
      }

      final data = response.data as Map<String, dynamic>;
      return EventModel.fromJson(data['event'] as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Event> saveEventDraft(EventCreatePayload payload) async {
    try {
      return await _createEvent(payload, publish: false, syncCohosts: true);
    } catch (e) {
      logger.e('saveEventDraft failed', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<void> setupOrganizerResources({
    required String eventId,
    required List<String> cohostUserIds,
    required bool createEventConversation,
    String? conversationId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/events/$eventId/organizer-setup',
        data: {
          'cohost_user_ids': cohostUserIds,
          'create_event_conversation': createEventConversation,
          if (conversationId != null && conversationId.trim().isNotEmpty)
            'conversation_id': conversationId.trim(),
        },
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to configure organizer resources');
      }
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  Future<EventModel> _createEvent(
    EventCreatePayload payload, {
    required bool publish,
    required bool syncCohosts,
  }) async {
    if (payload.eventImage == null) {
      throw ServerException('Event banner image is required');
    }

    String? imageUrl;
    final eventId = const Uuid().v4();
    final urls = await _fileUploadDataSource.uploadFiles(
      files: [payload.eventImage!],
      bucket: 'event',
      folder: eventId,
    );
    imageUrl = urls.isNotEmpty ? urls.first : null;

    final resolvedCustomFields = await _uploadCustomFieldImages(
      eventId: eventId,
      customFields: payload.customFields,
    );
    final payloadWithUploadedFieldImages = payload.copyWith(
      customFields: resolvedCustomFields,
    );

    final requestBody = EventCreatePayloadModel.fromEntity(
      payloadWithUploadedFieldImages,
      publish: publish,
    ).toJson();

    if (imageUrl != null) requestBody['event_image_url'] = imageUrl;

    final response = await _dioClient.dio.post('/events', data: requestBody);

    if (response.statusCode != 201) {
      throw ServerException('Failed to create event');
    }

    final data = response.data as Map<String, dynamic>;
    final createdEvent = EventModel.fromJson(
      data['event'] as Map<String, dynamic>,
    );

    if (syncCohosts) {
      await _syncCohostsForEvent(
        eventId: createdEvent.id,
        cohostUserIds: payload.cohostUserIds,
      );
    }

    return createdEvent;
  }

  Future<List<EventCustomField>> _uploadCustomFieldImages({
    required String eventId,
    required List<EventCustomField> customFields,
  }) async {
    if (customFields.isEmpty) {
      return customFields;
    }

    final resolved = <EventCustomField>[];

    for (final field in customFields) {
      if (field.normalizedType != 'image') {
        resolved.add(field.copyWith(imageFile: null));
        continue;
      }

      final folderSegment = _sanitizeStorageSegment(
        field.key.isNotEmpty ? field.key : field.label,
      );

      String? uploadedImageUrl = field.imageUrl?.trim();
      if (field.imageFile != null) {
        final urls = await _fileUploadDataSource.uploadFiles(
          files: [field.imageFile!],
          bucket: 'event',
          folder: '$eventId/custom_fields/$folderSegment',
        );

        uploadedImageUrl = urls.isNotEmpty ? urls.first : null;
      }

      if (uploadedImageUrl == null || uploadedImageUrl.isEmpty) {
        throw ServerException(
          'Image is required for custom field: ${field.label}',
        );
      }

      resolved.add(
        field.copyWith(
          required: false,
          options: const <String>[],
          imageUrl: uploadedImageUrl,
          imageFile: null,
        ),
      );
    }

    return resolved;
  }

  String _sanitizeStorageSegment(String raw) {
    final normalized = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return const Uuid().v4();
  }

  Future<void> _syncCohostsForEvent({
    required String eventId,
    required List<String> cohostUserIds,
  }) async {
    if (cohostUserIds.isEmpty) return;

    final uniqueIds = cohostUserIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final userId in uniqueIds) {
      try {
        final response = await _dioClient.dio.post(
          '/events/$eventId/cohosts',
          data: {'user_id': userId},
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          logger.e('Failed to add cohost $userId for event $eventId');
        }
      } catch (e) {
        logger.e('Failed to add cohost $userId for event $eventId', error: e);
      }
    }
  }
}
