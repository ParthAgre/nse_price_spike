// FD form validation. Each function returns an error message, or null when
// the input is valid. Pure, so it is unit-tested without widgets.

import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/utils/fd_math.dart';
import 'package:nse_price_spike/utils/money.dart';

/// Highest accepted rate: 20% p.a.
const fdMaxRateMilliPct = 20 * fdRateScale;

String? validateInstitution(String text) =>
    text.trim().isEmpty ? S.enterInstitution : null;

/// Required; > 0 with at most 2 decimals.
String? validatePrincipal(String text) {
  if (text.trim().isEmpty) return S.enterPrincipal;
  final paise = tryParseDecimalToPaise(text);
  if (paise == null) return S.amountFormat;
  if (paise <= 0) return S.principalPositive;
  return null;
}

/// "7.125" → 7125. Null when malformed.
int? tryParseRateMilli(String text) {
  try {
    return parseScaledDecimal(text, 3);
  } on FormatException {
    return null;
  }
}

/// Required; 0 < rate ≤ 20, up to 3 decimals.
String? validateRate(String text) {
  if (text.trim().isEmpty) return S.enterRate;
  final milli = tryParseRateMilli(text);
  if (milli == null) return S.rateFormat;
  if (milli <= 0) return S.ratePositive;
  if (milli > fdMaxRateMilliPct) return S.rateTooHigh;
  return null;
}

/// Parses the three tenure boxes (blank = 0). Null when any is not a
/// whole number.
Tenure? tryParseTenure(String years, String months, String days) {
  int? part(String s) => s.trim().isEmpty ? 0 : int.tryParse(s.trim());
  final y = part(years);
  final m = part(months);
  final d = part(days);
  if (y == null || m == null || d == null || y < 0 || m < 0 || d < 0) {
    return null;
  }
  return Tenure(y, m, d);
}

String? validateTenureFields(String years, String months, String days) {
  if ([years, months, days].every((s) => s.trim().isEmpty)) {
    return S.enterTenure;
  }
  return tryParseTenure(years, months, days) == null ? S.tenureWhole : null;
}

/// Maturity must be after the start and at most 10 years later. Future
/// start dates are allowed.
String? validateFdDates(DateTime start, DateTime maturity) {
  if (!maturity.isAfter(start)) return S.maturityAfterStart;
  if (maturity.isAfter(addMonthsClamped(start, fdMaxTenureMonths))) {
    return S.tenureTooLong;
  }
  return null;
}

/// Optional; when given must be more than the principal.
String? validateReceiptAmount(String text, int? principalPaise) {
  if (text.trim().isEmpty) return null;
  final paise = tryParseDecimalToPaise(text);
  if (paise == null) return S.amountFormat;
  if (principalPaise != null && paise <= principalPaise) {
    return S.receiptAboveFrom;
  }
  return null;
}

/// Optional (payout per period, or an amount received); when given > 0.
String? validateOptionalAmount(String text) {
  if (text.trim().isEmpty) return null;
  return validateRequiredAmount(text);
}

String? validateRequiredAmount(String text) {
  final paise = tryParseDecimalToPaise(text);
  if (paise == null) return S.amountFormat;
  if (paise <= 0) return S.amountPositive;
  return null;
}
