import 'dart:io';

import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';

class ChatMediaDownloadButton extends StatefulWidget {
  final String mediaUrl;
  final Color iconColor;
  final Color backgroundColor;

  const ChatMediaDownloadButton({
    super.key,
    required this.mediaUrl,
    this.iconColor = Colors.white,
    this.backgroundColor = const Color(0x70000000),
  });

  @override
  State<ChatMediaDownloadButton> createState() =>
      _ChatMediaDownloadButtonState();
}

class _ChatMediaDownloadButtonState extends State<ChatMediaDownloadButton> {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'conet_app/downloads',
  );

  bool _isDownloading = false;
  double? _progress;

  String _buildFileName(Uri uri) {
    final lastSegment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final decoded = Uri.decodeComponent(lastSegment).trim();
    if (decoded.isEmpty) {
      return 'download_${DateTime.now().millisecondsSinceEpoch}';
    }

    final safeName = decoded.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return safeName.isEmpty
        ? 'download_${DateTime.now().millisecondsSinceEpoch}'
        : safeName;
  }

  Future<Directory> _resolveNonAndroidDownloadDirectory() async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        return downloadsDir;
      }
    } catch (_) {
      // Fall through to app documents.
    }

    return getApplicationDocumentsDirectory();
  }

  String _guessMimeType(String fileName) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String> _persistDownload(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    if (Platform.isAndroid) {
      final savedPathOrUri = await _downloadsChannel.invokeMethod<String>(
        'saveToDownloads',
        <String, dynamic>{
          'fileName': fileName,
          'mimeType': mimeType,
          'bytes': bytes,
        },
      );

      if (savedPathOrUri == null || savedPathOrUri.isEmpty) {
        throw Exception('Unable to save file to Downloads.');
      }

      return savedPathOrUri;
    }

    final directory = await _resolveNonAndroidDownloadDirectory();
    try {
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      throw Exception('Unable to save file to this device.');
    }
  }

  Future<void> _download(BuildContext context) async {
    if (_isDownloading) return;

    final uri = Uri.tryParse(widget.mediaUrl);
    if (uri == null) {
      if (context.mounted) {
        AppToast.showWarning(context, 'Invalid media URL');
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    try {
      final fileName = _buildFileName(uri);
      final response = await serviceLocator<DioClient>().dio.get<List<int>>(
        widget.mediaUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          if (total <= 0) {
            setState(() => _progress = null);
            return;
          }
          setState(() => _progress = received / total);
        },
      );

      final bytesList = response.data;
      if (bytesList == null || bytesList.isEmpty) {
        throw Exception('Download response is empty.');
      }

      final contentType = response.headers
          .value(Headers.contentTypeHeader)
          ?.split(';')
          .first;
      final mimeType = (contentType == null || contentType.trim().isEmpty)
          ? _guessMimeType(fileName)
          : contentType.trim();

      await _persistDownload(Uint8List.fromList(bytesList), fileName, mimeType);

      if (context.mounted) {
        AppToast.showSuccess(context, 'Saved to Downloads: $fileName');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showWarning(context, 'Download failed');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            value: _progress,
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () => _download(context),
        child: FaIcon(
          FontAwesomeIcons.download,
          color: widget.iconColor,
          size: 16,
        ),
      ),
    );
  }
}
