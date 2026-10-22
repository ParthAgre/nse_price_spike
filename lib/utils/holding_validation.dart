import 'package:nse_price_spike/constants/strings.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/utils/money.dart';

const maxNotesLength = 200;

/// Returns an error message, or null when the quantity is valid.
/// Must be > 0; whole numbers for stocks, up to 4 decimals for ETFs.
String? validateQuantity(String text, InstrumentType type) {
  if (text.trim().isEmpty) return S.enterQuantity;
  final scaled = tryParseQuantityScaled(text);
  if (scaled == null) return S.quantityFormat;
  if (scaled <= 0) return S.quantityPositive;
  if (type == InstrumentType.stock && scaled % quantityScale != 0) {
    return S.stocksWhole;
  }
  return null;
}

/// Must be > 0 with at most 2 decimals.
String? validatePrice(String text) {
  if (text.trim().isEmpty) return S.enterPrice;
  final paise = tryParseDecimalToPaise(text);
  if (paise == null) return S.priceFormat;
  if (paise <= 0) return S.pricePositive;
  return null;
}

/// Optional; when given must be ≥ 0 with at most 2 decimals.
String? validateFees(String text) {
  if (text.trim().isEmpty) return null;
  if (tryParseDecimalToPaise(text) == null) return S.feesFormat;
  return null;
}

/// Optional; at most [maxNotesLength] characters.
String? validateNotes(String text) =>
    text.trim().length > maxNotesLength ? S.notesTooLong : null;

/// Trimmed notes, or null when blank.
String? cleanNotes(String text) => text.trim().isEmpty ? null : text.trim();
