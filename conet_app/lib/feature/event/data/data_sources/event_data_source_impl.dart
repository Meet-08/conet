import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/error/error_handler.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/event/data/data_sources/event_data_source.dart';
import 'package:conet_app/feature/event/data/models/event_create_payload_model.dart';
import 'package:conet_app/feature/event/data/models/event_model.dart';
import 'package:conet_app/feature/event/data/models/event_page_model.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
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
  Future<Event> registerEvent(String eventId) async {
    try {
      final response = await _dioClient.dio.post('/events/$eventId/register');

      if (response.statusCode != 200) {
        throw ServerException('Failed to register event');
      }

      final data = response.data as Map<String, dynamic>;
      return EventModel.fromJson(data['event'] as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Event> publishEvent(EventCreatePayload payload) async {
    try {
      // Step 1: create as draft to obtain the event id
      final draft = await _createDraft(payload);

      // Step 2: publish the draft
      final response = await _dioClient.dio.patch(
        '/events/${draft.id}/publish',
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to publish event');
      }

      final data = response.data as Map<String, dynamic>;
      return EventModel.fromJson(data['event'] as Map<String, dynamic>);
    } catch (e) {
      logger.e('publishEvent failed', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Event> saveEventDraft(EventCreatePayload payload) async {
    try {
      return await _createDraft(payload);
    } catch (e) {
      logger.e('saveEventDraft failed', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  /// Creates the event as a draft and returns the persisted [EventModel].
  Future<EventModel> _createDraft(EventCreatePayload payload) async {
    String? imageUrl;
    if (payload.eventImage != null) {
      final eventId = const Uuid().v4();
      final urls = await _fileUploadDataSource.uploadFiles(
        files: [payload.eventImage!],
        bucket: 'event',
        folder: eventId,
      );
      imageUrl = urls.isNotEmpty ? urls.first : null;
    }

    final requestBody = EventCreatePayloadModel.fromEntity(
      payload,
      publish: false,
    ).toJson();

    if (imageUrl != null) requestBody['event_image_url'] = imageUrl;

    final response = await _dioClient.dio.post('/events', data: requestBody);

    if (response.statusCode != 201) {
      throw ServerException('Failed to create event');
    }

    final data = response.data as Map<String, dynamic>;
    return EventModel.fromJson(data['event'] as Map<String, dynamic>);
  }
}
