import 'package:conet_app/feature/report/domain/entities/report_target_type.dart';
import 'package:equatable/equatable.dart';

sealed class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

final class ReportCreateRequested extends ReportEvent {
  final String targetId;
  final ReportTargetType targetType;
  final String reason;
  final String? description;

  const ReportCreateRequested({
    required this.targetId,
    required this.targetType,
    required this.reason,
    this.description,
  });

  @override
  List<Object?> get props => [targetId, targetType, reason, description];
}