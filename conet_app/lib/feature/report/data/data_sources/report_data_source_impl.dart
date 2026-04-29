import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/error/error_handler.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/report/data/data_sources/report_data_source.dart';
import 'package:conet_app/feature/report/data/models/report_create_request_model.dart';
import 'package:conet_app/main.dart';

class ReportDataSourceImpl implements ReportDataSource {
  final DioClient _dioClient;

  ReportDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<void> createReport(ReportCreateRequestModel request) async {
    try {
      final response = await _dioClient.dio.post(
        '/reports',
        data: request.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException('Failed to submit report');
      }
    } catch (e) {
      logger.e('Failed to submit report', error: e);
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }
}
