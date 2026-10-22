# nse_price_spike

A standalone Android spike. It tracks stock and ETF holdings using end-of-day prices from NSE's free daily **bhavcopy** file, plus fixed deposits valued with interest maths, on one Investments screen, before any of this goes into Brokd. It follows Brokd's conventions so modules can be copied across:

- Flutter / Dart
- Riverpod 2.x
- the Repository pattern
- Drift/SQLite
- pure functions for the maths

Other docs:

- `docs/USER_SOP.md`: a short note linking to the shared user SOP.
- `STATUS.md`: current state and check results.
- `CLAUDE.md`: conventions for working on the code.

## Run it

Requirements: Flutter 3.44 / Dart 3.12 (`sdk: ^3.12.2`) and an Android device or emulator.

```bash
flutter pub get
dart run build_runner build      # after any change in lib/database/tables/
flutter analyze
flutter test --timeout 90s       # no network; in-memory Drift; no device needed
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

On a low-memory host, stop the Gradle daemons after a build:

```bash
cd android && JAVA_HOME="/e/Softwares/Android Studio/jbr" ./gradlew --stop
```

For a 360 dp screen on the Pixel_9 emulator, run `adb shell wm size 720x1600 && adb shell wm density 320`. Undo it with `wm size reset` and `wm density reset`.

### Fixture mode vs Live mode

- **Fixture (default):** serves the bundled `test/fixtures/bhav_20261021.zip` and `EQUITY_L.csv`, which are declared as assets. No network is used. Every request returns the 21 Oct 2026 file, and its date is taken from the file's `TradDt`.
- **Live:** downloads from `nsearchives.nseindia.com` with a browser-like User-Agent.
- Switch modes with the toggle on the Debug screen (bug icon). The choice persists in the `app_settings` table.

## How it works

| Piece | File |
|---|---|
| URL pattern (the one constant) | `lib/constants/nse_urls.dart` |
| Bhavcopy unzip and parse (by header name; ClsPric, never LastPric; rows kept by ISIN; TtlTrfVal; zip entry time) | `lib/services/bhavcopy_parser.dart`, `csv_table.dart` |
| EQUITY_L parse (trimmed headers) | `lib/services/equity_list_parser.dart` |
| `PriceProvider` interface | `lib/services/price_provider.dart` |
| Live and fixture providers (live logs `Last-Modified`) | `nse_bhavcopy_provider.dart`, `fixture_price_provider.dart` |
| Typed errors (404/403/timeout/not-a-zip/parse/…) | `lib/services/price_fetch_errors.dart` |
| Refresh rules (expected day, not-published-yet handling, 5-try holiday walk-back, once per IST day, weekly EQUITY_L, publish-time log) | `lib/services/refresh_service.dart` |
| Expected trading day (17:00 IST cutoff) | `lib/utils/trading_day.dart` |
| Paise and quantity parsing (string-based) and formatting (Indian grouping, "−" for negatives, whole-rupee variant, signed %) | `lib/utils/money.dart` |
| FD maths (maturity from tenure, simple vs compound, receipt-calibrated value, payouts) | `lib/utils/fd_math.dart` |
| FD model and status (Upcoming / Active / Maturing soon / Matured / Closed) | `lib/models/fixed_deposit.dart` |
| Combined summary (stocks + ETFs + FDs), filters and sorting | `lib/utils/investments_summary.dart`, `holding_sort.dart` |
| Form validation | `lib/utils/holding_validation.dart`, `fd_validation.dart` |
| All user-facing text (except the Debug screen) | `lib/constants/strings.dart` |
| Theme tokens (gain/loss colours) | `lib/theme/app_theme.dart` |
| Portfolio maths (pure) | `lib/utils/portfolio_math.dart` |
| Manual vs file price rule | `selectEffectivePrice` in `lib/models/price_quote.dart` |
| Local search (exact symbol → prefix → name; by traded value) | `lib/utils/symbol_search.dart` |
| Drift schema v3 | `lib/database/` (tables `instruments`, `investment_transactions`, `price_quotes`, `symbol_master`, `app_settings`, `fixed_deposits`) |
| Repositories (holdings are derived, never stored) | `lib/repositories/` |
| Riverpod wiring | `lib/providers/` |
| Screens (Investments, Search, Stock/ETF form and detail, FD form and detail, Debug) | `lib/screens/` |
| Dumb widgets (state + callbacks): summary card, allocation bar, chips, rows, price chart | `lib/widgets/` |

Data path: **UI → Riverpod providers → repositories → Drift**. Widgets never import drift.

Money is integer **paise**. Quantity is an integer **× 10,000**. CSV decimals become paise by string parsing (`"259.57"` → `25957`), and rounding happens only for display.

### What's tracked: by ISIN, not by series

- **Stocks:** `INE` ISINs whose security-type code (characters 8–9) is `01`.
- **ETFs:** `INF` ISINs.
- **Series:** both are kept from any series (EQ, BE, BZ, SM, ST, …) except **BL**. BL is the block-deal window, and it repeats EQ ISINs at different closes.
- **Duplicates:** if one ISIN still appears in two series, the row is taken from the first series in this order: EQ > BE > BZ > SM > ST > others.
- **Excluded:** everything else, including debentures (`07`/`08`/`A7`/`24`), InvIT (`23`) and REIT (`25`) units, rights entitlements (`20`), gold bonds and G-secs (`IN0…`), SDLs and DVRs (`IN9…`).
- **Search list:** `symbol_master` holds EQUITY_L.csv plus every kept bhavcopy row that EQUITY_L lacks: all ETFs, and SME stocks (SM/ST). The `origin` column (schema v2) records which source each row came from.

### Refresh timing

- **Expected day:** today from **17:00 IST** on a weekday; otherwise the previous weekday.
- **Today's file 404s:** this means *not published yet*.
  - The previous prices are kept.
  - Earlier days are still walked back to if needed.
  - The run doesn't count as the day's download.
  - App open/resume re-checks at most once every 30 minutes. A manual refresh or "Download now" checks immediately.
- **Earlier days:** the holiday fallback is unchanged (up to 5 weekdays).
- **Publish times:** each successful download records the server `Last-Modified` header and the CSV's zip-entry timestamp, shown under Debug → "Publish times" (last 30). This is to measure when NSE really publishes.

### Investments screen

- **Summary card:** Current value (whole rupees), Invested, Returns (₹ and %, with an info button), and "Today (stocks & ETFs)". The footer reads "Market prices as of {date} · FD values as of today".
- **Allocation bar** by asset class (Stocks = INE, ETFs = INF, FDs), drawn with `CustomPaint`, shown when more than one class is held.
- **Filter chips** All · Stocks · ETFs · FDs, one per held class. Changing the chip resets the sort to that chip's default.
- **Total / Today toggle** (stock and ETF rows only) and a **sort menu**: Current value (default), Returns %, Today's change, Name, plus Maturity date under FDs (its default).
- **Matured FDs** are pinned to the top with "Renewed or withdrawn?". **Closed FDs** sit in a collapsible "Closed" section and are left out of every total.
- **Gains and losses** always carry a sign ("+", or "−" U+2212) as well as a colour from the `GainLossColors` theme extension.

### Fixed deposits

- **Stored:** principal, rate (thousandths of a percent: 7.125% = 7125), start date, **maturity date** (tenure is only an input method), interest type, payout frequency, compounding, the optional receipt maturity amount and payout amount, and closure (status, date, amount received, `renewed_into_id`).
- **Maths** (`fd_math.dart`): actual/365. Maturity before start + 6 calendar months → simple interest; otherwise P × (1 + r/n)^(n × days/365). Doubles only inside the formulas; one half-up rounding to paise at the end.
- **Value today:** principal before the start, the maturity amount from maturity on, and in between either the receipt-calibrated curve P × (M/P)^(elapsed/total) or the formula. Shown with "≈" until maturity. Payout FDs are always worth the principal; their interest is counted as payouts received on month-step boundaries.
- **Lifecycle:** Withdrawn (amount + date), Renewed (opens a prefilled form; saving closes and links the old FD), Close early (amount + date; realised interest = received − principal, plus payouts already received).

## Porting to Brokd

**Move as-is.** These have no app-specific dependencies:

- `lib/utils/money.dart`, `portfolio_math.dart`, `trading_day.dart`, `instrument_type.dart`, `symbol_search.dart`, `holding_validation.dart`, `fd_math.dart`, `fd_validation.dart`, `investments_summary.dart`, `holding_sort.dart`
- `lib/models/` (`instrument`, `daily_file`, `holding`, `price_quote`, `network_event`, `fixed_deposit`)
- `lib/services/` (`bhavcopy_parser`, `csv_table`, `equity_list_parser`, `price_provider`, `nse_bhavcopy_provider`, `fixture_price_provider`, `price_fetch_errors`, `network_log`, `refresh_service`, `file_cache`)
- `lib/constants/nse_urls.dart`
- Their tests under `test/utils`, `test/models` and `test/services`, plus `test/helpers/fixtures.dart` and `test/fixtures/`

**Move with changes:**

1. **Tables** (`lib/database/tables/*.dart` except `app_settings`). Add them to Brokd's `@DriftDatabase` list. Bump Brokd's `schemaVersion` (currently 8 → 9) and add an `onUpgrade` step that runs `m.createTable(...)` for `instruments`, `investmentTransactions`, `priceQuotes`, `symbolMaster` and `fixedDeposits`. Then regenerate `app_database.g.dart`. Brokd creates these tables fresh, so they get `symbol_master.origin` and `investment_transactions.notes` directly; this app's own v1 → v2 and v2 → v3 steps are not needed there.
2. **Settings.** Brokd keeps settings in SharedPreferences (`services/profile_store.dart`). Re-implement `SettingsRepository` over that store and keep the key names from `SettingKeys`. Then drop the `app_settings` table.
3. **Database connection.** Brokd opens SQLite with `drift_flutter`'s `driftDatabase(...)`. Use Brokd's connection and drop this app's `LazyDatabase`/`NativeDatabase` opener. Neither app needs `sqlite3_flutter_libs`: sqlite3 3.x bundles SQLite itself.
4. **Repositories** (`lib/repositories/*`). These take `AppDatabase`, so they port unchanged against Brokd's class. Brokd keeps most query logic in `app_database.dart`; either keep these repositories thick, or move the queries in to match.
5. **Providers.** Merge `repository_providers.dart`, `service_providers.dart` and `refresh_providers.dart` into Brokd's `lib/providers/`, and reuse Brokd's `appDatabaseProvider`.
6. **Refresh trigger.** Call `refreshControllerProvider.notifier.refresh(automatic: true)` from Brokd's `AppGate` resume handler instead of `NsePriceSpikeApp`'s `AppLifecycleListener`. Pass `automatic: true` so the 30-minute throttle for an unpublished file applies.
7. **Screens.** Restyle with Brokd's theme tokens and Inter font, use Brokd's formatters (`lib/utils/formatters.dart`) where they overlap `money.dart`, and route through Brokd's navigation. The widgets in `lib/widgets/` take plain state and callbacks, and all copy is in `lib/constants/strings.dart`; map `GainLossColors` onto Brokd's colour tokens. Hide the Debug screen behind Brokd's debug Profile row.
8. **Assets.** Ship the fixture assets only in debug builds, or drop Fixture mode from release builds.

**Not done in the spike:** stock sells, FIFO and realised P&L, dividends, corporate actions (splits and bonuses), REIT/InvIT units, DVR shares (IN9), bonds and gold bonds, mutual funds, gold, recurring deposits, TDS and tax, notifications, automatic FD renewal, and a background price job when the app is closed.
