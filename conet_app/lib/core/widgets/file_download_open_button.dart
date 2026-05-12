import 'dart:io';

import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class FileDownloadOpenButton extends StatefulWidget {
  final String downloadUrl;
  final String fileName;
  final Map<String, dynamic>? headers;
  final bool allowRedownload;
  final bool openAfterDownload;
  final String? subDirectory;
  final bool usePublicDownloads;
  final Color? downloadColor;
  final Color? openColor;

  const FileDownloadOpenButton({
    super.key,
    required this.downloadUrl,
    required this.fileName,
    this.headers,
    this.allowRedownload = true,
    this.openAfterDownload = true,
    this.subDirectory,
    this.usePublicDownloads = false,
    this.downloadColor,
    this.openColor,
  });

  @override
  State<FileDownloadOpenButton> createState() => _FileDownloadOpenButtonState();
}

class _FileDownloadOpenButtonState extends State<FileDownloadOpenButton> {
  static const MethodChannel _downloadsChannel = MethodChannel(
    'conet_app/downloads',
  );

  bool _isLoading = false;
  bool _isDownloaded = false;
  double? _progress;
  String? _filePath;
  String? _savedMimeType;

  @override
  void initState() {
    super.initState();
    _initFileState();
  }

  Future<void> _initFileState() async {
    final path = await _resolveFilePath();
    if (!mounted) return;

    setState(() {
      _filePath = path;
      _isDownloaded = File(path).existsSync();
    });
  }

  Future<String> _resolveFilePath() async {
    final baseDir = widget.usePublicDownloads
        ? await _resolveDownloadDirectory()
        : await getApplicationDocumentsDirectory();
    final targetDir =
        widget.subDirectory == null || widget.subDirectory!.trim().isEmpty
        ? baseDir.path
        : '${baseDir.path}/${widget.subDirectory!.trim()}';
    final directory = Directory(targetDir);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    return '${directory.path}/${widget.fileName}';
  }

  Future<Directory> _resolveDownloadDirectory() async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        return downloadsDir;
      }
    } catch (_) {
      // Fall through to app documents only if the platform has no downloads dir.
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
    if (widget.usePublicDownloads && Platform.isAndroid) {
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

    final directory = await getApplicationDocumentsDirectory();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _openFile(String path) async {
    if (Platform.isAndroid && path.startsWith('content://')) {
      try {
        await _downloadsChannel.invokeMethod<bool>(
          'openDownloadedUri',
          <String, dynamic>{
            'uri': path,
            if (_savedMimeType != null) 'mimeType': _savedMimeType,
          },
        );
        return;
      } catch (_) {
        if (!mounted) return;
        AppToast.showWarning(context, 'Unable to open downloaded file');
        return;
      }
    }

    final result = await OpenFilex.open(path);
    if (!mounted) return;

    if (result.type != ResultType.done) {
      AppToast.showWarning(context, result.message);
    }
  }

  Future<void> _download({required bool force}) async {
    if (_isLoading) return;

    final path = _filePath ?? await _resolveFilePath();
    final uri = Uri.tryParse(widget.downloadUrl);
    if (uri == null) {
      if (!mounted) return;
      AppToast.showError(context, 'Invalid download URL');
      return;
    }

    final file = File(path);
    if (!widget.usePublicDownloads) {
      if (force && file.existsSync()) {
        await file.delete();
      }
    }

    setState(() {
      _isLoading = true;
      _progress = 0;
      _filePath = path;
    });

    try {
      final response = await serviceLocator<DioClient>().dio.get<List<int>>(
        widget.downloadUrl,
        options: Options(
          headers: widget.headers,
          responseType: ResponseType.bytes,
        ),
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
          ? _guessMimeType(widget.fileName)
          : contentType.trim();

      final savedPath = await _persistDownload(
        Uint8List.fromList(bytesList),
        widget.fileName,
        mimeType,
      );

      if (!mounted) return;
      setState(() {
        _isDownloaded = true;
        _filePath = savedPath;
        _savedMimeType = mimeType;
      });

      if (widget.openAfterDownload) {
        await _openFile(savedPath);
      }
    } on DioException catch (error) {
      if (!mounted) return;
      final message = error.response?.data is Map
          ? (error.response?.data['message']?.toString() ?? 'Download failed')
          : 'Download failed';
      AppToast.showError(context, message);
    } catch (_) {
      if (!mounted) return;
      AppToast.showError(context, 'Download failed');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _handlePrimaryTap() async {
    if (_isLoading) return;
    final path = _filePath;
    final canOpenExistingFile =
        path != null && (widget.usePublicDownloads || File(path).existsSync());
    if (_isDownloaded && canOpenExistingFile) {
      await _openFile(path);
      return;
    }
    await _download(force: false);
  }

  Future<void> _handleRedownloadTap() async {
    await _download(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _isLoading ? null : _handlePrimaryTap,
          tooltip: _isDownloaded ? 'Open file' : 'Download file',
          icon: _isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: _progress,
                  ),
                )
              : FaIcon(
                  _isDownloaded
                      ? FontAwesomeIcons.folderOpen
                      : FontAwesomeIcons.download,
                  size: 18,
                  color: _isDownloaded
                      ? (widget.openColor ?? colorScheme.primary)
                      : (widget.downloadColor ?? colorScheme.onSurface),
                ),
        ),
        if (widget.allowRedownload && _isDownloaded)
          IconButton(
            onPressed: _isLoading ? null : _handleRedownloadTap,
            tooltip: 'Re-download',
            icon: const FaIcon(FontAwesomeIcons.rotateRight, size: 16),
          ),
      ],
    );
  }
}
