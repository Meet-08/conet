import 'dart:io';

import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/error/error_handler.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_compress/video_compress.dart';

class SupabaseFileUploadDataSource implements FileUploadDataSource {
  final SupabaseClient supabaseClient;

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'};
  static const _videoExtensions = {
    'mp4',
    'mov',
    'mkv',
    'webm',
    'avi',
    '3gp',
    'mpeg',
    'mpg',
    'm4v',
  };

  static const _uploadOptions = FileOptions(
    cacheControl: '2592000',
    upsert: false,
  );

  SupabaseFileUploadDataSource({required this.supabaseClient});

  bool _isImageFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0) return false;

    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    return _imageExtensions.contains(ext);
  }

  bool _isVideoFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0) return false;

    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    return _videoExtensions.contains(ext);
  }

  CompressFormat _compressFormatFromFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0) return CompressFormat.jpeg;

    final ext = fileName.substring(dotIndex + 1).toLowerCase();
    return ext == 'png' ? CompressFormat.png : CompressFormat.jpeg;
  }

  Future<Uint8List?> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;

    if (file.path != null) {
      return File(file.path!).readAsBytes();
    }

    return null;
  }

  Future<Uint8List?> _compressImageBytes(PlatformFile file) async {
    final inputBytes = await _readFileBytes(file);
    if (inputBytes == null || inputBytes.isEmpty) {
      return null;
    }

    final compressed = await FlutterImageCompress.compressWithList(
      inputBytes,
      minWidth: 1920,
      minHeight: 1920,
      quality: 75,
      format: _compressFormatFromFileName(file.name),
      keepExif: true,
    );

    if (compressed.isEmpty) {
      return null;
    }

    return Uint8List.fromList(compressed);
  }

  Future<File?> _compressVideoFile(PlatformFile file) async {
    if (kIsWeb || file.path == null || file.path!.isEmpty) {
      return null;
    }

    try {
      final mediaInfo = await VideoCompress.compressVideo(
        file.path!,
        quality: VideoQuality.DefaultQuality,
        includeAudio: true,
        deleteOrigin: false,
      );

      final compressed = mediaInfo?.file;
      if (compressed == null || !compressed.existsSync()) {
        return null;
      }

      if (file.size > 0) {
        final compressedSize = await compressed.length();
        if (compressedSize >= file.size) {
          return null;
        }
      }

      return compressed;
    } catch (e) {
      logger.w('Video compression failed for ${file.name}: $e');
      return null;
    }
  }

  String _replaceExtensionWithMp4(String path) {
    final slashIndex = path.lastIndexOf('/');
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex <= slashIndex) {
      return '$path.mp4';
    }

    return '${path.substring(0, dotIndex)}.mp4';
  }

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
        final isImage = _isImageFileName(fileName);
        final isVideo = _isVideoFileName(fileName);

        if (isImage) {
          final compressedBytes = await _compressImageBytes(file);
          if (compressedBytes != null) {
            await supabaseClient.storage
                .from(bucket)
                .uploadBinary(
                  path,
                  compressedBytes,
                  fileOptions: _uploadOptions,
                );

            final url = supabaseClient.storage.from(bucket).getPublicUrl(path);
            urls.add(url);
            continue;
          }

          logger.w(
            'Image compression skipped for $path; uploading original bytes',
          );
        }

        if (isVideo) {
          final compressedVideo = await _compressVideoFile(file);
          if (compressedVideo != null) {
            final videoPath = _replaceExtensionWithMp4(path);
            await supabaseClient.storage
                .from(bucket)
                .upload(
                  videoPath,
                  compressedVideo,
                  fileOptions: _uploadOptions,
                );

            final url = supabaseClient.storage
                .from(bucket)
                .getPublicUrl(videoPath);
            urls.add(url);
            continue;
          }

          logger.w(
            'Video compression skipped for $path; uploading original file',
          );
        }

        if (kIsWeb) {
          if (file.bytes == null || file.bytes!.isEmpty) {
            throw ServerException('Cannot upload empty web file: $fileName');
          }

          await supabaseClient.storage
              .from(bucket)
              .uploadBinary(path, file.bytes!, fileOptions: _uploadOptions);
        } else {
          if (file.path == null || file.path!.isEmpty) {
            throw ServerException(
              'Cannot upload file without local path: $fileName',
            );
          }

          await supabaseClient.storage
              .from(bucket)
              .upload(path, File(file.path!), fileOptions: _uploadOptions);
        }

        final url = supabaseClient.storage.from(bucket).getPublicUrl(path);

        urls.add(url);
      }

      return urls;
    } catch (e) {
      logger.e(e.toString());
      throw ServerException(AppErrorHandler.handleException(e), e);
    } finally {
      if (!kIsWeb) {
        await VideoCompress.deleteAllCache();
      }
    }
  }
}
