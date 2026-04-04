import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

List<dynamic> _extractOps(dynamic decoded) {
  if (decoded is List<dynamic>) {
    return decoded;
  }

  if (decoded is Map<String, dynamic>) {
    final ops = decoded['ops'];
    if (ops is List<dynamic>) {
      return ops;
    }
  }

  throw const FormatException('Invalid quill delta format');
}

Document quillDocumentFromString(String deltaJson) {
  final decoded = jsonDecode(deltaJson);
  final ops = _extractOps(decoded);

  if (ops.isEmpty) {
    return Document.fromJson(const [
      {'insert': '\n'},
    ]);
  }

  return Document.fromJson(ops);
}

String quillPlainTextFromString(String deltaJson) {
  try {
    final document = quillDocumentFromString(deltaJson);
    return document.toPlainText().trim();
  } catch (_) {
    return '';
  }
}

List<String> quillTagsFromString(String deltaJson) {
  try {
    final decoded = jsonDecode(deltaJson);
    if (decoded is! Map<String, dynamic>) return const [];

    final tags = decoded['tags'];
    if (tags is! List<dynamic>) return const [];

    return tags
        .whereType<String>()
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
}
