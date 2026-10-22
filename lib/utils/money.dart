/// Quantities are stored as integers scaled by this factor (4 decimal places).
const quantityScale = 10000;

final _decimalPattern = RegExp(r'^(\d*)(?:\.(\d*))?$');

/// Parses a non-negative decimal string with at most [maxDecimals] fraction
/// digits into an integer scaled by 10^[maxDecimals], by string manipulation
/// only (no doubles), so "259.57" is exactly 25957.
///
/// Throws [FormatException] on empty input, signs, separators, or too many
/// decimals.
int parseScaledDecimal(String input, int maxDecimals) {
  final s = input.trim();
  final m = _decimalPattern.firstMatch(s);
  final whole = m?.group(1) ?? '';
  final frac = m?.group(2) ?? '';
  if (m == null || (whole.isEmpty && frac.isEmpty)) {
    throw FormatException('Not a decimal number', input);
  }
  if (frac.length > maxDecimals) {
    throw FormatException('More than $maxDecimals decimal places', input);
  }
  final wholeValue = whole.isEmpty ? 0 : int.parse(whole);
  final paddedFrac = frac.padRight(maxDecimals, '0');
  final fracValue = paddedFrac.isEmpty ? 0 : int.parse(paddedFrac);
  var scale = 1;
  for (var i = 0; i < maxDecimals; i++) {
    scale *= 10;
  }
  return wholeValue * scale + fracValue;
}

/// "1209.00" → 120900, "0.05" → 5, "14499.99" → 1449999.
int parseDecimalToPaise(String input) => parseScaledDecimal(input, 2);

/// Like [parseDecimalToPaise] but returns null instead of throwing.
int? tryParseDecimalToPaise(String input) {
  try {
    return parseDecimalToPaise(input);
  } on FormatException {
    return null;
  }
}

/// "10" → 100000, "1.5" → 15000 (×[quantityScale]).
int parseQuantityScaled(String input) => parseScaledDecimal(input, 4);

int? tryParseQuantityScaled(String input) {
  try {
    return parseQuantityScaled(input);
  } on FormatException {
    return null;
  }
}

/// Indian digit grouping: 1234567 → "12,34,567".
String _groupIndian(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

/// 1209000 → "₹12,090.00". With [showPlus], positive values get a "+".
String formatRupees(int paise, {bool showPlus = false}) {
  final negative = paise < 0;
  final abs = paise.abs();
  final body =
      '₹${_groupIndian(abs ~/ 100)}.${(abs % 100).toString().padLeft(2, '0')}';
  if (negative) return '-$body';
  if (showPlus && paise > 0) return '+$body';
  return body;
}

/// Plain decimal for form fields: 120900 → "1209.00".
String paiseToInput(int paise) =>
    '${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';

/// 100000 → "10", 15000 → "1.5".
String formatQuantity(int scaled) {
  final whole = scaled ~/ quantityScale;
  final frac = scaled % quantityScale;
  if (frac == 0) return _groupIndian(whole);
  final fracText = frac
      .toString()
      .padLeft(4, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return '${_groupIndian(whole)}.$fracText';
}

/// Unformatted quantity for form fields.
String quantityToInput(int scaled) =>
    formatQuantity(scaled).replaceAll(',', '');

/// 0.0578 → "+5.78%". Display-only, so doubles are fine here.
String formatPercent(double? fraction, {bool showPlus = true}) {
  if (fraction == null) return '—';
  final pct = fraction * 100;
  final text = '${pct.abs().toStringAsFixed(2)}%';
  if (pct < 0) return '-$text';
  if (showPlus && pct > 0) return '+$text';
  return text;
}

/// 639151 → "624.2 KB".
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
