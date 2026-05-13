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

  String? _extensionFromFile(PlatformFile file) {
    final fromField = file.extension?.trim().toLowerCase();
    if (fromField != null && fromField.isNotEmpty) return fromField;

    final dotIndex = file.name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == file.name.length - 1) return null;
    return file.name.substring(dotIndex + 1).toLowerCase();
  }

  bool _isImageExtension(String? extension) {
    if (extension == null || extension.isEmpty) return false;
    return _imageExtensions.contains(extension);
  }

  bool _isVideoExtension(String? extension) {
    if (extension == null || extension.isEmpty) return false;
    return _videoExtensions.contains(extension);
  }

  CompressFormat _compressFormatFromExtension(String? extension) {
    return extension == 'png' ? CompressFormat.png : CompressFormat.jpeg;
  }

  String _sanitizeFileName(String name) {
    var sanitized = name.trim();
    // Replace problematic characters with underscores and collapse multiple underscores
    sanitized = sanitized.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), '_');
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\-.@_]'), '_');
    sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');
    if (sanitized.isEmpty) sanitized = 'file';
    return sanitized;
  }

  String _buildStorageFileName(
    PlatformFile file,
    int index,
    String? extension,
  ) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    var original = file.name;
    if (original.isEmpty) {
      // fallback to timestamped name
      final base = 'upload_${timestamp}_$index';
      return extension == null || extension.isEmpty ? base : '$base.$extension';
    }

    // sanitize original filename
    final dotIndex = original.lastIndexOf('.');
    String baseName;
    String extFromName = '';
    if (dotIndex >= 0 && dotIndex < original.length - 1) {
      baseName = original.substring(0, dotIndex);
      extFromName = original.substring(dotIndex + 1).toLowerCase();
    } else {
      baseName = original;
    }

    baseName = _sanitizeFileName(baseName);

    // determine extension to use (prefer provided extension, else the one from original name)
    final finalExt = (extension != null && extension.isNotEmpty)
        ? extension
        : (extFromName.isNotEmpty ? extFromName : null);

    // If multiple files in same batch share the same name, append index to avoid clash within same upload
    final nameWithIndex = index > 0 ? '${baseName}_$index' : baseName;

    if (finalExt == null || finalExt.isEmpty) {
      return nameWithIndex;
    }

    return '$nameWithIndex.$finalExt';
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

    final extension = _extensionFromFile(file);

    final compressed = await FlutterImageCompress.compressWithList(
      inputBytes,
      minWidth: 1920,
      minHeight: 1920,
      quality: 75,
      format: _compressFormatFromExtension(extension),
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
      var fileIndex = 0;

      for (final file in files) {
        final extension = _extensionFromFile(file);
        final fileName = _buildStorageFileName(file, fileIndex, extension);
        final path = '$folder/$fileName';
        final isImage = _isImageExtension(extension);
        final isVideo = _isVideoExtension(extension);
        fileIndex++;

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
