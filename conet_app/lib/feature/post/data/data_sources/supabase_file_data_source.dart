import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/post/data/data_sources/file_data_source.dart';
import 'package:conet_app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFileDataSource implements FileDataSource {
  final SupabaseClient supabaseClient;

  SupabaseFileDataSource({required this.supabaseClient});

  @override
  Future<List<String>> uploadFiles({
    required List<PlatformFile> files,
    required String postId,
  }) async {
    try {
      final bucket = supabaseClient.storage.from('post');

      final futures = files.map((file) async {
        final path = '$postId/${file.name}';

        await bucket.uploadBinary(
          path,
          file.bytes!,
          fileOptions: FileOptions(
            contentType: file.extension,
            cacheControl: '3600', // 1 hour CDN cache
            upsert: false,
          ),
        );

        return bucket.getPublicUrl(path);
      });

      return await Future.wait(futures);
    } on StorageException catch (e) {
      logger.e(e.message);
      throw ServerException(e.message);
    } catch (e) {
      logger.e(e.toString());
      throw ServerException(e.toString());
    }
  }
}
