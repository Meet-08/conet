import 'package:conet_app/feature/report/data/models/report_create_request_model.dart';

abstract interface class ReportDataSource {
  Future<void> createReport(ReportCreateRequestModel request);
}