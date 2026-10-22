import 'package:nse_price_spike/utils/trading_day.dart';

/// The single source of truth for the bhavcopy download URL.
/// `{YYYYMMDD}` is replaced with the trading day.
const bhavcopyUrlPattern =
    'https://nsearchives.nseindia.com/content/cm/BhavCopy_NSE_CM_0_0_0_{YYYYMMDD}_F_0000.csv.zip';

const equityListUrl =
    'https://nsearchives.nseindia.com/content/equities/EQUITY_L.csv';

/// NSE's archive host rejects requests without a browser-like User-Agent.
const browserUserAgent =
    'Mozilla/5.0 (Linux; Android 14; Pixel 9) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36';

String bhavcopyUrlFor(DateTime tradingDay) =>
    bhavcopyUrlPattern.replaceFirst('{YYYYMMDD}', yyyymmdd(tradingDay));
