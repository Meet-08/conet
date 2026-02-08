import 'package:file_picker/file_picker.dart';

abstract interface class FileUploadDataSource {
  /// Uploads files to storage and returns their public URLs
  ///
  /// [files] - List of files to upload
  /// [bucket] - Storage bucket name (e.g., 'post', 'message')
  /// [folder] - Folder path within the bucket (e.g., userId or postId)
  Future<List<String>> uploadFiles({
    required List<PlatformFile> files,
    required String bucket,
    required String folder,
  });
}
