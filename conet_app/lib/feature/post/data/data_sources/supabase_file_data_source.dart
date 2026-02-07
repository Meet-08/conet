import 'dart:io';

import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/post/data/data_sources/file_data_source.dart';
import 'package:conet_app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
      final urls = <String>[];

      for (final file in files) {
        final fileName = file.name;
        final path = '$postId/$fileName';

        if (kIsWeb) {
          if (file.bytes != null) {
            await supabaseClient.storage
                .from('post')
                .uploadBinary(path, file.bytes!);
          }
        } else {
          if (file.path != null) {
            await supabaseClient.storage
                .from('post')
                .upload(path, File(file.path!));
          }
        }

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
