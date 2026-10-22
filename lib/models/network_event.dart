class NetworkEvent {
  final DateTime time;
  final String url;

  /// HTTP status code, or a word such as `timeout`, `error` or `fixture`.
  final String status;
  final Duration duration;
  final int? bytes;

  const NetworkEvent({
    required this.time,
    required this.url,
    required this.status,
    required this.duration,
    this.bytes,
  });
}
