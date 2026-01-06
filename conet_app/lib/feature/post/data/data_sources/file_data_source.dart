import 'package:file_picker/file_picker.dart';

abstract interface class FileDataSource {
  Future<List<String>> uploadFiles({
    required List<PlatformFile> files,
    required String postId,
  });
}
