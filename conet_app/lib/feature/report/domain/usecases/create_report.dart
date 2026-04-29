import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/report/domain/entities/report_target_type.dart';
import 'package:conet_app/feature/report/domain/repositories/report_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateReport {
  final ReportRepository _reportRepository;

  CreateReport({required ReportRepository reportRepository})
    : _reportRepository = reportRepository;

  Future<Either<AppFailure, Unit>> call({
    required String targetId,
    required ReportTargetType targetType,
    required String reason,
    String? description,
  }) {
    return _reportRepository.createReport(
      targetId: targetId,
      targetType: targetType,
      reason: reason,
      description: description,
    );
  }
}