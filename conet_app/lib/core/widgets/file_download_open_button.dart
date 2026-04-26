import 'dart:io';

import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/utils/app_toast.dart';
import 'package:conet_app/init_dependencies.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
    this.downloadColor,
    this.openColor,
  });

  @override
  State<FileDownloadOpenButton> createState() => _FileDownloadOpenButtonState();
}

class _FileDownloadOpenButtonState extends State<FileDownloadOpenButton> {
  bool _isLoading = false;
  bool _isDownloaded = false;
  double? _progress;
  String? _filePath;

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
    final baseDir = await getApplicationDocumentsDirectory();
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

  Future<void> _openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (!mounted) return;

    if (result.type != ResultType.done) {
      AppToast.showWarning(context, result.message);
    }
  }

  String _sanitizeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'[\x00-\x1F]'), '')
        .trim();
  }

  String? _extractFileNameFromContentDisposition(String? headerValue) {
    if (headerValue == null || headerValue.trim().isEmpty) return null;

    final encodedMatch = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(headerValue);

    if (encodedMatch != null) {
      final encoded = encodedMatch.group(1)?.trim();
      if (encoded != null && encoded.isNotEmpty) {
        String decoded;
        try {
          decoded = Uri.decodeComponent(encoded);
        } catch (_) {
          decoded = encoded;
        }
        final cleaned = _sanitizeFileName(decoded);
        if (cleaned.isNotEmpty) return cleaned;
      }
    }

    final quotedMatch = RegExp(
      r'filename="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(headerValue);
    final unquotedMatch = RegExp(
      r'filename=([^;]+)',
      caseSensitive: false,
    ).firstMatch(headerValue);

    final fileName = quotedMatch?.group(1) ?? unquotedMatch?.group(1);
    if (fileName == null || fileName.trim().isEmpty) return null;

    final cleaned = _sanitizeFileName(fileName.trim());
    return cleaned.isEmpty ? null : cleaned;
  }

  Future<void> _download({required bool force}) async {
    if (_isLoading) return;

    final path = _filePath ?? await _resolveFilePath();
    final file = File(path);
    if (force && file.existsSync()) {
      await file.delete();
    }

    setState(() {
      _isLoading = true;
      _progress = 0;
      _filePath = path;
    });

    try {
      final response = await serviceLocator<DioClient>().dio.download(
        widget.downloadUrl,
        path,
        options: Options(headers: widget.headers),
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          if (total <= 0) {
            setState(() => _progress = null);
            return;
          }
          setState(() => _progress = received / total);
        },
      );

      var finalPath = path;
      final headerFileName = _extractFileNameFromContentDisposition(
        response.headers.value('content-disposition'),
      );

      if (headerFileName != null) {
        final targetPath = '${file.parent.path}/$headerFileName';
        if (targetPath != path) {
          final targetFile = File(targetPath);
          if (targetFile.existsSync()) {
            await targetFile.delete();
          }
          final renamed = await file.rename(targetPath);
          finalPath = renamed.path;
        }
      }

      if (!mounted) return;
      setState(() {
        _filePath = finalPath;
        _isDownloaded = true;
      });

      if (widget.openAfterDownload) {
        await _openFile(finalPath);
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
    if (_isDownloaded && path != null && File(path).existsSync()) {
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
