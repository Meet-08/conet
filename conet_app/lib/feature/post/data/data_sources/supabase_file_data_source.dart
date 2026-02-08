import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/file_data_source.dart';
import 'package:file_picker/file_picker.dart';

class SupabaseFileDataSource implements FileDataSource {
  final FileUploadDataSource fileUploadDataSource;

  SupabaseFileDataSource({required this.fileUploadDataSource});

  @override
  Future<List<String>> uploadFiles({
    required List<PlatformFile> files,
    required String postId,
  }) async {
    return fileUploadDataSource.uploadFiles(
      files: files,
      bucket: 'post',
      folder: postId,
    );
  }
}
