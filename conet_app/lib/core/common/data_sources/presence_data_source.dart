abstract interface class PresenceDataSource {
  Stream<Set<String>> watchOnlineUsers(String userId);

  Future<void> dispose();
}
