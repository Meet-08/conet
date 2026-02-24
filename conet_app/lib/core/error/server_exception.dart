class ServerException implements Exception {
  final String message;
  final dynamic originalError;

  ServerException(this.message, [this.originalError]);
}
