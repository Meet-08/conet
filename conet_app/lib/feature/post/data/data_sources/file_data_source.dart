import 'dart:io';

abstract interface class FileDataSource {
  Future<List<String>> uploadFiles({
    required List<File> files,
    required String postId,
  });
}
