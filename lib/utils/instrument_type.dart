import 'package:nse_price_spike/models/instrument.dart';

/// INE → stock, INF → ETF; anything else is ignored for now (null).
InstrumentType? instrumentTypeFromIsin(String isin) {
  final prefix = isin.trim().toUpperCase();
  if (prefix.startsWith('INE')) return InstrumentType.stock;
  if (prefix.startsWith('INF')) return InstrumentType.etf;
  return null;
}
