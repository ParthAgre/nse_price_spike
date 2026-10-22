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

/// The typographic minus (U+2212) used for every negative figure shown.
const minusSign = '−';

String _signed(String body, int value, bool showPlus) {
  if (value < 0) return '$minusSign$body';
  if (showPlus && value > 0) return '+$body';
  return body;
}

/// 10718590 → "₹1,07,185.90"; −125000 → "−₹1,250.00". With [showPlus],
/// positive values get a "+". Use it for every rupee amount shown.
String formatRupees(int paise, {bool showPlus = false}) {
  final abs = paise.abs();
  final body =
      '₹${_groupIndian(abs ~/ 100)}.${(abs % 100).toString().padLeft(2, '0')}';
  return _signed(body, paise, showPlus);
}

/// Whole rupees for large summary figures, rounded half away from zero:
/// 10718590 → "₹1,07,186".
String formatRupeesWhole(int paise, {bool showPlus = false}) {
  final rupees = (paise.abs() + 50) ~/ 100;
  return _signed(
    '₹${_groupIndian(rupees)}',
    paise < 0 ? -rupees : rupees,
    showPlus,
  );
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

/// 0.0578 → "+5.78%", −0.0058 → "−0.58%". Display-only, so doubles are
/// fine here. A value that rounds to 0.00 gets no sign.
String formatPercent(double? fraction, {bool showPlus = true}) {
  if (fraction == null) return '—';
  final text = (fraction * 100).abs().toStringAsFixed(2);
  if (text == '0.00') return '0.00%';
  if (fraction < 0) return '$minusSign$text%';
  if (showPlus) return '+$text%';
  return '$text%';
}

/// Share of a whole, one decimal, no sign: 0.6243 → "62.4%".
String formatShare(double fraction) =>
    '${(fraction * 100).toStringAsFixed(1)}%';

/// Interest rate in thousandths of a percent: 7125 → "7.125", 7000 → "7".
String formatRateMilli(int milliPct) {
  final whole = milliPct ~/ 1000;
  final frac = (milliPct % 1000)
      .toString()
      .padLeft(3, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? '$whole' : '$whole.$frac';
}

/// 639151 → "624.2 KB".
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
