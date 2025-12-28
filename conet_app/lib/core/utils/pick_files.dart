import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<List<File>?> pickFiles({int limit = 10}) async {
  final result = await FilePicker.platform.pickFiles(allowMultiple: true);

  return result?.files.map((file) => File(file.path!)).toList();
}
