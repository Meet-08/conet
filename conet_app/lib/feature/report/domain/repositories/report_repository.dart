import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/report/domain/entities/report_target_type.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ReportRepository {
  Future<Either<AppFailure, Unit>> createReport({
    required String targetId,
    required ReportTargetType targetType,
    required String reason,
    String? description,
  });
}