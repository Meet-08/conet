import 'package:conet_app/feature/report/domain/usecases/create_report.dart';
import 'package:conet_app/feature/report/presentation/bloc/report_event.dart';
import 'package:conet_app/feature/report/presentation/bloc/report_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final CreateReport _createReport;

  ReportBloc({required CreateReport createReport})
    : _createReport = createReport,
      super(const ReportState()) {
    on<ReportCreateRequested>(_onCreateRequested);
  }

  Future<void> _onCreateRequested(
    ReportCreateRequested event,
    Emitter<ReportState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ReportSubmissionStatus.submitting,
        errorMessage: null,
      ),
    );

    final result = await _createReport(
      targetId: event.targetId,
      targetType: event.targetType,
      reason: event.reason,
      description: event.description,
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: ReportSubmissionStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (_) {
        emit(
          state.copyWith(
            status: ReportSubmissionStatus.success,
            errorMessage: null,
          ),
        );
      },
    );
  }
}