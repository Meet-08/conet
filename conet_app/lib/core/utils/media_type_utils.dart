enum MediaType { image, video, audio, document, unknown }

MediaType getMediaType(String mediaUrl) {
  final trimmedUrl = mediaUrl.trim();
  if (trimmedUrl.isEmpty) return MediaType.unknown;

  final uri = Uri.tryParse(trimmedUrl);
  if (uri == null || uri.pathSegments.isEmpty) return MediaType.unknown;

  final fileName = uri.pathSegments.last;
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == fileName.length - 1) {
    return MediaType.unknown;
  }

  final extension = fileName.substring(dotIndex + 1).toLowerCase();
  return _mediaTypeFromExtension(extension);
}

MediaType getMediaTypeFromFileName(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == fileName.length - 1) {
    return MediaType.unknown;
  }
  final extension = fileName.substring(dotIndex + 1).toLowerCase();
  return _mediaTypeFromExtension(extension);
}

MediaType _mediaTypeFromExtension(String extension) {
  if (_imageExtensions.contains(extension)) return MediaType.image;
  if (_videoExtensions.contains(extension)) return MediaType.video;
  if (_audioExtensions.contains(extension)) return MediaType.audio;
  if (_documentExtensions.contains(extension)) return MediaType.document;

  return MediaType.unknown;
}

const Set<String> _imageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'tif',
  'tiff',
  'svg',
  'heic',
  'heif',
  'avif',
};

const Set<String> _videoExtensions = {
  'mp4',
  'mov',
  'm4v',
  'mkv',
  'webm',
  'avi',
  '3gp',
  'mpeg',
  'mpg',
};

const Set<String> _audioExtensions = {
  'mp3',
  'm4a',
  'aac',
  'wav',
  'ogg',
  'flac',
};

const Set<String> _documentExtensions = {
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'txt',
  'csv',
  'zip',
  'rar',
  '7z',
};
