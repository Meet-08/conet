import 'dart:io';

import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/post/data/data_sources/file_data_source.dart';
import 'package:conet_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFileDataSource implements FileDataSource {
  final SupabaseClient supabaseClient;

  SupabaseFileDataSource({required this.supabaseClient});

  @override
  Future<List<String>> uploadFiles({
    required List<File> files,
    required String postId,
  }) async {
    try {
      final urls = <String>[];

      for (final file in files) {
        final fileName = file.path.split('/').last;
        final path = '$postId/$fileName';

        await supabaseClient.storage.from('post').upload(path, file);

        final url = supabaseClient.storage.from('post').getPublicUrl(path);

        urls.add(url);
      }

      return urls;
    } on StorageException catch (e) {
      logger.e(e.toString());
      throw ServerException(e.message);
    } catch (e) {
      logger.e(e.toString());
      throw ServerException(e.toString());
    }
  }
}
