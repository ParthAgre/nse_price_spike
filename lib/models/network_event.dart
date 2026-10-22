class NetworkEvent {
  final DateTime time;
  final String url;

  /// HTTP status code, or a word such as `timeout`, `error` or `fixture`.
  final String status;
  final Duration duration;
  final int? bytes;

  /// The response's `Last-Modified` header, or for fixtures and as a
  /// fallback the zip entry time. Used to measure when NSE publishes.
  final DateTime? lastModified;

  const NetworkEvent({
    required this.time,
    required this.url,
    required this.status,
    required this.duration,
    this.bytes,
    this.lastModified,
  });
}
