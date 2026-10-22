# Status: nse_price_spike

_Last updated 2026-10-22 03:40 IST._

## Snapshot

- **State:** feature-complete against the spike spec (§1–§10). The repo is initialised and **nothing is committed** yet, pending approval.
- **Checks** (run 2026-10-22, 03:18–03:36 IST, Flutter 3.44.8 / Dart 3.12.2):

  | Check | Result |
  |---|---|
  | `flutter analyze` | No issues found |
  | `flutter test --timeout 90s` | 115 tests, all passed |
  | `dart format --set-exit-if-changed lib test` | 0 files changed |
  | `flutter build apk --debug` | Built `build/app/outputs/flutter-apk/app-debug.apk` |

- **Manual check on the Pixel_9 emulator at 360 dp** (03:27–03:36 IST):
  - **Fixture mode:**
    - On first open the app loaded EQUITY_L and the bhavcopy from assets (background-isolate parse): symbol_master 2,959, rows parsed 3,708.
    - I added RELIANCE: qty 10 @ ₹1,100.
    - Portfolio showed ₹12,090.00, P&L +₹1,090.00 (+9.91%) and today's change +₹70.00 (+0.58%). No layout overflow.
  - **Live mode:** **Download now** fetched the real `BhavCopy_NSE_CM_0_0_0_20261021_F_0000.csv.zip`. The response was HTTP 200, 203.3 KB, in 471 ms, and it matched 1 holding.

## Spec checklist

| § | Item | Status |
|---|---|---|
| 1 | New project and git repo, INTERNET permission, fixtures in `test/fixtures/` | ✅ |
| 2 | Bhavcopy: one URL constant, browser UA, unzip, real CSV parser, headers by name, ClsPric/PrvsClsgPric, EQ+BE only, per-series counts | ✅ |
| 2 | EQUITY_L: trimmed headers; ISIN-prefix typing; ISIN as identity | ✅ |
| 3 | `PriceProvider`, `NseBhavcopyProvider`, `FixturePriceProvider`, persisted mode toggle (default Fixture) | ✅ |
| 4 | Drift tables as specified; holdings derived by a repository query; widgets never touch drift | ✅ (see deviations) |
| 5 | Refresh on open/resume/manual; 19:00 IST rule; 404 walk-back ≤ 5 tries; once per IST day unless "Download now"; errors keep the cache with the banner; quotes only for held ISINs; ETF refresh; EQUITY_L weekly; manual-price precedence | ✅ |
| 6 | Local search: case-insensitive symbol/name, exact ISIN, symbol prefix first, max 30 | ✅ |
| 7 | Portfolio, Search, Add/Edit (validation, latest close, delete with confirm), Holding detail (entries, close history, manual price), Debug (all items) | ✅ |
| 8 | Pure maths in `lib/utils/portfolio_math.dart`; integer paise and scaled qty; string→paise | ✅ |
| 9 | All listed tests; no network in tests | ✅ |
| 10 | analyze clean, tests pass, debug APK builds, README with "Porting to Brokd" | ✅ |

## Deviations and decisions

- **`sqlite3_flutter_libs` removed** (approved). It resolved to `0.6.0+eol`, an empty stub, because drift 2.35 uses sqlite3 3.5.2, which bundles SQLite itself.
- **Settings in a Drift `app_settings` key/value table**, because shared_preferences is not on the allowed list. Brokd should use its SharedPreferences store; see README.
- **`symbol_master` has an extra nullable `series` column**, so a picked instrument gets its series.
- **`price_quotes` has an autoincrement `id`** as well as the required UNIQUE(instrument_id, trade_date, source).
- **Latest-file cache:** the latest bhavcopy zip is kept in the app cache directory. This lets the Add screen show the close of an instrument that isn't held yet, and lets a new holding be priced immediately. Quotes are still stored only for held instruments, and "Clear cache" deletes the file.
- **Fixture mode serves the 21 Oct 2026 file for any requested day.** The stored date is the file's `TradDt`.
- **The walk-back stops at the stored date** (unless forced), because an older day can't give anything newer.
- **Search ranking** within a rank is shorter symbol first, then A–Z. So "reli" lists RELIABLE before RELIANCE; the test asserts RELIANCE is among the prefix matches.

## Fixture findings (differences from the prompt)

- **Bhavcopy:**
  - 3,708 data rows and 34 columns. LF line endings, no quoted fields, every price has 2 decimals.
  - About 50 series. EQ 2,694, BE 222, SM 393, ST 83, GS 50, GB 43, BZ 30, …
  - **SME (SM/ST) rows are excluded** by the EQ/BE rule.
  - All 353 INF rows are in EQ/BE.
- **EQUITY_L:**
  - 2,608 rows, of which 2,606 are INE. **2 rows have `IN9…` ISINs** and are ignored.
  - Series include **BZ (30)**.
  - It has **no INF/ETF rows**, which confirms that ETFs must come from the bhavcopy.
  - `NAME OF COMPANY` has no leading space; the other headers do.
- **Expected values:** RELIANCE 120900/120200 and NIFTYBEES 25957 match the prompt.
- **Other source files:**
  - The EODHD `search_niftybees.json` (not copied) lists NIFTYBEES with ISIN **INF732E01011**, while the bhavcopy has **INF204KB14I2**. This is one more reason to take ISINs from NSE.
  - `exchanges.json`, `search_reliance.json` and `search_niftybees.json` were not needed and were not copied.
- **Publish time:** the zip entry is timestamped 16:31 on 21 Oct, before the 19:00 IST cutoff the app assumes. That's fine, just conservative.

## Known limitations

- No sells or realised P&L; no corporate actions (splits and bonuses).
- The network-event log is in memory: it is cleared when the app restarts.
- **Mode switch and the once-per-day rule:** a Fixture download counts as "today's download". After switching to Live the same day, use **Download now**.
- Only the EQ and BE series are tracked.
- Holdings added while the cache is empty (for example right after "Clear cache") show "—" until the next refresh.

## Next steps

1. Review, then approve the initial commit.
2. Optionally soak-test Live mode for a few evenings, including after 19:00 IST and on an NSE holiday.
3. Port to Brokd following README → "Porting to Brokd".
