import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nse_price_spike/models/instrument.dart';
import 'package:nse_price_spike/services/bhavcopy_parser.dart';
import 'package:nse_price_spike/services/fixture_price_provider.dart';
import 'package:nse_price_spike/services/price_fetch_errors.dart';
import 'package:nse_price_spike/utils/trading_day.dart';

import '../helpers/fixtures.dart';

Uint8List zipOf(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, text) => archive.add(ArchiveFile.string(name, text)));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  group('real fixture (21 Oct 2026)', () {
    final file = fixtureDailyFile();

    test('trade date comes from TradDt', () {
      expect(file.tradeDate, d('2026-10-21'));
    });

    test('RELIANCE: ClsPric and PrvsClsgPric in paise, stock', () {
      final row = file.rowsByIsin['INE002A01018']!;
      expect(row.symbol, 'RELIANCE');
      expect(row.closePaise, 120900);
      expect(row.prevClosePaise, 120200);
      expect(row.type, InstrumentType.stock);
      expect(row.series, 'EQ');
    });

    test('NIFTYBEES: close 25957, ETF', () {
      final row = file.rowsByIsin['INF204KB14I2']!;
      expect(row.symbol, 'NIFTYBEES');
      expect(row.closePaise, 25957);
      expect(row.type, InstrumentType.etf);
    });

    test('GB (gold bond) rows are excluded but counted', () {
      expect(file.seriesCounts['GB'], 43);
      expect(file.rows.where((r) => r.series == 'GB'), isEmpty);
      // SGBJUN28 is the first data row of the file and a GB row.
      expect(file.rowsByIsin.containsKey('IN0020200104'), isFalse);
    });

    test('rows are kept by ISIN, from every equity series; all counted', () {
      expect(file.keptSeriesCounts, {
        'EQ': 2693, // 2,340 INE…01 stocks + 353 INF ETFs
        'SM': 393,
        'BE': 222,
        'ST': 83,
        'BZ': 29,
      });
      expect(file.rowsByIsin.length, 3420);
      expect(file.seriesCounts['EQ'], 2694, reason: 'incl. 1 IN9 DVR row');
      expect(file.seriesCounts['BL'], 5);
      expect(
        file.seriesCounts.values.fold(0, (a, b) => a + b),
        file.rowsParsed,
      );
      expect(file.rowsParsed, 3708);
      expect(file.rowsExcluded, 3708 - 3420);
      expect(file.duplicatesDropped, 0, reason: 'BL is excluded up front');
    });

    test('a BZ stock is included', () {
      final row = file.rowsByIsin['INE583L01014']!;
      expect(row.symbol, 'AGSTRA');
      expect(row.series, 'BZ');
      expect(row.type, InstrumentType.stock);
      expect(row.closePaise, 205);
    });

    test('SM and ST (SME) stocks are included', () {
      final sm = file.rowsByIsin['INE0O6N01012']!;
      expect(
        (sm.symbol, sm.series, sm.type),
        ('AGUL', 'SM', InstrumentType.stock),
      );
      expect(sm.closePaise, 4220);
      final st = file.rowsByIsin['INE124401014']!;
      expect((st.symbol, st.series), ('AARADHYA', 'ST'));
      expect(st.closePaise, 12065);
    });

    test('company debentures (INE, type code 07) are excluded', () {
      // N0 series: AFIL 11.50% 2029, ISIN INE916Y07073.
      expect(file.rowsByIsin.containsKey('INE916Y07073'), isFalse);
      expect(
        file.rows.where(
          (r) =>
              r.isin.substring(7, 9) != '01' && r.type == InstrumentType.stock,
        ),
        isEmpty,
      );
    });

    test('REIT (25) and InvIT (23) units and the IN9 DVR are excluded', () {
      expect(file.rowsByIsin.containsKey('INE2OVN25015'), isFalse); // REIT
      expect(file.rowsByIsin.containsKey('INE1UA823019'), isFalse); // InvIT
      expect(file.rowsByIsin.containsKey('IN9175A01010'), isFalse); // DVR
    });

    test('block-deal (BL) rows never replace the EQ close', () {
      // ADANIENSOL: BL close 1334.00, EQ close 1324.00.
      final row = file.rowsByIsin['INE931S01010']!;
      expect(row.series, 'EQ');
      expect(row.closePaise, 132400);
      expect(file.rows.where((r) => r.series == 'BL'), isEmpty);
    });

    test('traded value (TtlTrfVal) is read in paise', () {
      expect(
        file.rowsByIsin['INE002A01018']!.tradedValuePaise,
        2142358729880, // 21423587298.80
      );
    });

    test('zip entry time is read as IST', () {
      // The CSV inside the zip is stamped 21 Oct 2026 16:31 (IST).
      final t = toIst(file.zipEntryTime!);
      expect(
        (t.year, t.month, t.day, t.hour, t.minute),
        (2026, 10, 21, 16, 31),
      );
    });

    test('raw zip and size are kept', () {
      expect(file.sizeBytes, fixtureBytes(fixtureBhavcopyFile).length);
      expect(file.rawZip, isNotNull);
    });

    test('zip and extracted CSV parse identically', () {
      final fromCsv = parseBhavcopyCsv(fixtureText(bhavCsvFile));
      expect(fromCsv.rowsByIsin.length, file.rowsByIsin.length);
      expect(fromCsv.rowsByIsin['INE002A01018']!.closePaise, 120900);
    });
  });

  group('header lookup by name', () {
    test('reordered columns and a quoted name with a comma', () {
      const csv =
          'LastPric,ClsPric,FinInstrmNm,SctySrs,PrvsClsgPric,ISIN,TckrSymb,TradDt\n'
          '999.00,1209.00,"RELIANCE INDUSTRIES, LTD",EQ,1202.00,INE002A01018,RELIANCE,2026-10-21\n'
          '1.00,259.57,NIP IND ETF NIFTY BEES,EQ,,INF204KB14I2,NIFTYBEES,2026-10-21\n';
      final file = parseBhavcopyCsv(csv);
      final rel = file.rowsByIsin['INE002A01018']!;
      expect(rel.closePaise, 120900, reason: 'ClsPric, never LastPric');
      expect(rel.name, 'RELIANCE INDUSTRIES, LTD');
      expect(rel.prevClosePaise, 120200);
      expect(file.rowsByIsin['INF204KB14I2']!.prevClosePaise, isNull);
    });

    test('headers with surrounding spaces and CRLF line endings', () {
      const csv =
          ' TradDt , ISIN ,TckrSymb,SctySrs,FinInstrmNm,ClsPric,PrvsClsgPric\r\n'
          '2026-10-21,INE002A01018,RELIANCE,EQ,RIL,1209.00,1202.00\r\n';
      expect(
        parseBhavcopyCsv(csv).rowsByIsin['INE002A01018']!.closePaise,
        120900,
      );
    });

    test('a missing column is a parse failure naming it', () {
      const csv =
          'TradDt,ISIN,TckrSymb,SctySrs,FinInstrmNm,LastPric\n'
          '2026-10-21,INE002A01018,RELIANCE,EQ,RIL,1209.00\n';
      expect(
        () => parseBhavcopyCsv(csv),
        throwsA(
          isA<PriceParseFailure>().having(
            (e) => e.reason,
            'reason',
            allOf(contains('ClsPric'), contains('PrvsClsgPric')),
          ),
        ),
      );
    });

    test('non-equity ISINs are excluded whatever the series', () {
      const csv =
          'TradDt,ISIN,TckrSymb,SctySrs,FinInstrmNm,ClsPric,PrvsClsgPric\n'
          '2026-10-21,IN9999999999,PARTLY,EQ,Partly paid,10.00,9.00\n'
          '2026-10-21,INE999X07011,NCD,EQ,Some NCD,1000.00,999.00\n'
          '2026-10-21,INE002A01018,RELIANCE,EQ,RIL,1209.00,1202.00\n'
          '2026-10-21,INE002A01018,RELIANCE,BL,RIL block,1210.00,1202.00\n'
          '2026-10-21,INE111A01011,BADPRICE,EQ,Bad,n/a,1.00\n';
      final file = parseBhavcopyCsv(csv);
      expect(file.rowsByIsin.keys, ['INE002A01018']);
      expect(file.rowsByIsin['INE002A01018']!.closePaise, 120900);
      expect(file.rowsExcluded, 3);
      expect(file.rowsSkipped, 1);
    });

    test('the same ISIN in two series: higher-priority series wins', () {
      const csv =
          'TradDt,ISIN,TckrSymb,SctySrs,FinInstrmNm,ClsPric,PrvsClsgPric\n'
          '2026-10-21,INE123A01011,ABC,SM,Abc SME,50.00,49.00\n'
          '2026-10-21,INE123A01011,ABC,EQ,Abc,51.00,49.00\n'
          '2026-10-21,INE123A01011,ABC,ZZ,Abc other,52.00,49.00\n';
      final file = parseBhavcopyCsv(csv);
      final row = file.rowsByIsin['INE123A01011']!;
      expect(row.series, 'EQ');
      expect(row.closePaise, 5100);
      expect(file.duplicatesDropped, 2);
      expect(file.keptSeriesCounts, {'EQ': 1});
    });

    test('TtlTrfVal is optional', () {
      const csv =
          'TradDt,ISIN,TckrSymb,SctySrs,FinInstrmNm,ClsPric,PrvsClsgPric\n'
          '2026-10-21,INE002A01018,RELIANCE,EQ,RIL,1209.00,1202.00\n';
      expect(
        parseBhavcopyCsv(csv).rowsByIsin['INE002A01018']!.tradedValuePaise,
        isNull,
      );
    });
  });

  group('error bodies', () {
    test('plain-text body (eod_reliance.json) is not a zip', () {
      expect(
        () => parseBhavcopyZip(fixtureBytes('eod_reliance.json')),
        throwsA(
          isA<PriceNotAZip>().having(
            (e) => e.bodyPreview,
            'preview',
            'Ticker Not Found.',
          ),
        ),
      );
    });

    test('HTML body is not a zip', () {
      final html = utf8.encode('<html><body>Access Denied</body></html>');
      expect(() => parseBhavcopyZip(html), throwsA(isA<PriceNotAZip>()));
    });

    test('empty zip is a parse failure', () {
      final empty = Uint8List.fromList([
        0x50,
        0x4B,
        0x05,
        0x06,
        ...List.filled(18, 0),
      ]);
      expect(looksLikeZip(empty), isTrue);
      expect(() => parseBhavcopyZip(empty), throwsA(isA<PriceParseFailure>()));
    });

    test('zip without a CSV is a parse failure', () {
      expect(
        () => parseBhavcopyZip(zipOf({'readme.txt': 'hello'})),
        throwsA(isA<PriceParseFailure>()),
      );
    });

    test('zip whose CSV has only a header is a parse failure', () {
      expect(
        () => parseBhavcopyZip(
          zipOf({
            'x.csv':
                'TradDt,ISIN,TckrSymb,SctySrs,FinInstrmNm,ClsPric,PrvsClsgPric\n',
          }),
        ),
        throwsA(isA<PriceParseFailure>()),
      );
    });

    test('truncated zip is a parse failure', () {
      final bytes = fixtureBytes(fixtureBhavcopyFile);
      expect(
        () => parseBhavcopyZip(Uint8List.sublistView(bytes, 0, 2000)),
        throwsA(isA<PriceParseFailure>()),
      );
    });
  });
}
