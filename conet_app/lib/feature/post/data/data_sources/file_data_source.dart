import 'package:file_picker/file_picker.dart';

abstract interface class FileDataSource {
  /// Uploads files for a post and returns their public URLs
  Future<List<String>> uploadFiles({
    required List<PlatformFile> files,
    required String postId,
  });
}
