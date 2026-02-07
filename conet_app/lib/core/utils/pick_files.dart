import 'package:file_picker/file_picker.dart';

Future<List<PlatformFile>?> pickFiles({int limit = 10}) async {
  final result = await FilePicker.platform.pickFiles(allowMultiple: true);

  return result?.files;
}
