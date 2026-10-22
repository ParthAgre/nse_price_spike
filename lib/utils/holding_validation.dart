import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/utils/money.dart';

/// Returns an error message, or null when the quantity is valid.
/// Must be > 0; whole numbers for stocks, up to 4 decimals for ETFs.
String? validateQuantity(String text, InstrumentType type) {
  if (text.trim().isEmpty) return 'Enter a quantity';
  final scaled = tryParseQuantityScaled(text);
  if (scaled == null) return 'Enter a number (up to 4 decimals)';
  if (scaled <= 0) return 'Quantity must be more than 0';
  if (type == InstrumentType.stock && scaled % quantityScale != 0) {
    return 'Stocks need a whole number';
  }
  return null;
}

/// Must be > 0 with at most 2 decimals.
String? validatePrice(String text) {
  if (text.trim().isEmpty) return 'Enter a price';
  final paise = tryParseDecimalToPaise(text);
  if (paise == null) return 'Enter a price like 1209.50';
  if (paise <= 0) return 'Price must be more than 0';
  return null;
}

/// Optional; when given must be ≥ 0 with at most 2 decimals.
String? validateFees(String text) {
  if (text.trim().isEmpty) return null;
  if (tryParseDecimalToPaise(text) == null) return 'Enter an amount like 20.50';
  return null;
}
