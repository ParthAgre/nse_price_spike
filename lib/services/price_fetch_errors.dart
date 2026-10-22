/// Typed failures from fetching or parsing an NSE file.
sealed class PriceFetchException implements Exception {
  const PriceFetchException();

  String get message;

  @override
  String toString() => '$runtimeType: $message';
}

/// HTTP 404: an exchange holiday, or the file is not published yet.
class PriceNotFound extends PriceFetchException {
  final String url;
  const PriceNotFound(this.url);

  @override
  String get message => 'Not found (404): $url';
}

/// HTTP 403: NSE is blocking the request.
class PriceForbidden extends PriceFetchException {
  final String url;
  const PriceForbidden(this.url);

  @override
  String get message => 'Forbidden (403): $url';
}

class PriceTimeout extends PriceFetchException {
  final String url;
  const PriceTimeout(this.url);

  @override
  String get message => 'Timed out: $url';
}

/// Any other non-200 status.
class PriceHttpFailure extends PriceFetchException {
  final int statusCode;
  final String url;
  const PriceHttpFailure(this.statusCode, this.url);

  @override
  String get message => 'HTTP $statusCode: $url';
}

/// No connection, DNS failure, TLS error and similar.
class PriceNetworkFailure extends PriceFetchException {
  final String detail;
  const PriceNetworkFailure(this.detail);

  @override
  String get message => 'Network error: $detail';
}

/// A 200 response whose body is not a zip (e.g. an HTML or text error page).
class PriceNotAZip extends PriceFetchException {
  /// The first characters of the body, for the debug log.
  final String bodyPreview;
  const PriceNotAZip(this.bodyPreview);

  @override
  String get message => 'Response is not a zip: "$bodyPreview"';
}

/// The body was a zip/CSV but its content could not be used.
class PriceParseFailure extends PriceFetchException {
  final String reason;
  const PriceParseFailure(this.reason);

  @override
  String get message => 'Could not parse file: $reason';
}
