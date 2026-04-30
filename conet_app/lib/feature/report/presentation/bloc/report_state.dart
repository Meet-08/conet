import 'package:equatable/equatable.dart';

enum ReportSubmissionStatus { initial, submitting, success, failure }

final class ReportState extends Equatable {
  final ReportSubmissionStatus status;
  final String? errorMessage;

  const ReportState({
    this.status = ReportSubmissionStatus.initial,
    this.errorMessage,
  });

  bool get isSubmitting => status == ReportSubmissionStatus.submitting;

  ReportState copyWith({
    ReportSubmissionStatus? status,
    String? errorMessage,
  }) {
    return ReportState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}