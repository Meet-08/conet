import 'dart:io';

import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFileUploadDataSource implements FileUploadDataSource {
  final SupabaseClient supabaseClient;

  SupabaseFileUploadDataSource({required this.supabaseClient});

  @override
  Future<List<String>> uploadFiles({
    required List<PlatformFile> files,
    required String bucket,
    required String folder,
  }) async {
    try {
      final urls = <String>[];

      for (final file in files) {
        final fileName = file.name;
        final path = '$folder/$fileName';

        if (kIsWeb) {
          if (file.bytes != null) {
            await supabaseClient.storage
                .from(bucket)
                .uploadBinary(path, file.bytes!);
          }
        } else {
          if (file.path != null) {
            await supabaseClient.storage
                .from(bucket)
                .upload(path, File(file.path!));
          }
        }

        final url = supabaseClient.storage.from(bucket).getPublicUrl(path);

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
