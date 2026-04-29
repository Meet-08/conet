import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/report/data/data_sources/report_data_source.dart';
import 'package:conet_app/feature/report/data/models/report_create_request_model.dart';
import 'package:conet_app/feature/report/domain/entities/report_target_type.dart';
import 'package:conet_app/feature/report/domain/repositories/report_repository.dart';
import 'package:fpdart/fpdart.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportDataSource _reportDataSource;

  ReportRepositoryImpl({required ReportDataSource reportDataSource})
    : _reportDataSource = reportDataSource;

  @override
  Future<Either<AppFailure, Unit>> createReport({
    required String targetId,
    required ReportTargetType targetType,
    required String reason,
    String? description,
  }) async {
    try {
      await _reportDataSource.createReport(
        ReportCreateRequestModel(
          targetId: targetId,
          targetType: targetType,
          reason: reason,
          description: description,
        ),
      );
      return right(unit);
    } on ServerException catch (e) {
      return left(AppFailure(e.message));
    } catch (e) {
      return left(AppFailure(e.toString()));
    }
  }
}