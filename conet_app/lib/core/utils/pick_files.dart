import 'package:file_picker/file_picker.dart';

Future<List<PlatformFile>?> pickFiles({
  int limit = 10,
  FileType type = FileType.any,
  List<String>? allowedExtensions,
}) async {
  // When allowedExtensions is provided, must use FileType.custom
  final fileType = allowedExtensions != null ? FileType.custom : type;

  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: true,
    type: fileType,
    allowedExtensions: allowedExtensions,
  );

  if (result == null) return null;
  return result.files.take(limit).toList();
}
