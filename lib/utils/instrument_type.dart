import 'package:nse_price_spike/models/instrument.dart';

/// ISIN characters 8–9 (1-based) hold the security-type code; "01" is an
/// equity share. In the 21 Oct 2026 bhavcopy every INE…01 row is in an
/// equity series (EQ/BE/BZ/SM/ST/BL) and no other code is.
const equityShareCode = '01';

/// INE + type code 01 → stock; INF → ETF; anything else (debentures,
/// REIT/InvIT units, rights entitlements, gold bonds, IN9 DVRs, G-secs …)
/// is ignored for now (null).
InstrumentType? instrumentTypeFromIsin(String isin) {
  final s = isin.trim().toUpperCase();
  if (s.length != 12) return null;
  if (s.startsWith('INE') && s.substring(7, 9) == equityShareCode) {
    return InstrumentType.stock;
  }
  if (s.startsWith('INF')) return InstrumentType.etf;
  return null;
}
