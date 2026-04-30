enum ReportTargetType {
  post('post', 'Post'),
  comment('comment', 'Comment'),
  conversation('conversation', 'Conversation'),
  event('event', 'Event'),
  user('user', 'User');

  final String apiValue;
  final String label;

  const ReportTargetType(this.apiValue, this.label);
}