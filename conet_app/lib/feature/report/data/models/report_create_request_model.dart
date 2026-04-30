import 'package:conet_app/feature/report/domain/entities/report_target_type.dart';

class ReportCreateRequestModel {
  final String targetId;
  final ReportTargetType targetType;
  final String reason;
  final String? description;

  const ReportCreateRequestModel({
    required this.targetId,
    required this.targetType,
    required this.reason,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'target_id': targetId,
      'target_type': targetType.apiValue,
      'reason': reason,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
    };
  }
}