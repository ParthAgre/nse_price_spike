# nse_price_spike

A standalone Android spike. It tracks stock and ETF holdings using end-of-day prices from NSE's free daily **bhavcopy** file, before any of this goes into Brokd. It follows Brokd's conventions so modules can be copied across:

- Flutter / Dart
- Riverpod 2.x
- the Repository pattern
- Drift/SQLite
- pure functions for the maths

Other docs:

- `docs/USER_SOP.md`: how to use the app.
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
| Bhavcopy unzip and parse (by header name; ClsPric, never LastPric; EQ and BE only) | `lib/services/bhavcopy_parser.dart`, `csv_table.dart` |
| EQUITY_L parse (trimmed headers) | `lib/services/equity_list_parser.dart` |
| `PriceProvider` interface | `lib/services/price_provider.dart` |
| Live and fixture providers | `nse_bhavcopy_provider.dart`, `fixture_price_provider.dart` |
| Typed errors (404/403/timeout/not-a-zip/parse/…) | `lib/services/price_fetch_errors.dart` |
| Refresh rules (expected day, 5-try holiday walk-back, once per IST day, weekly EQUITY_L) | `lib/services/refresh_service.dart` |
| Expected trading day (19:00 IST cutoff) | `lib/utils/trading_day.dart` |
| Paise and quantity parsing (string-based) and formatting | `lib/utils/money.dart` |
| Portfolio maths (pure) | `lib/utils/portfolio_math.dart` |
| Manual vs file price rule | `selectEffectivePrice` in `lib/models/price_quote.dart` |
| Local search | `lib/utils/symbol_search.dart` |
| Drift schema | `lib/database/` (tables `instruments`, `investment_transactions`, `price_quotes`, `symbol_master`, `app_settings`) |
| Repositories (holdings are derived, never stored) | `lib/repositories/` |
| Riverpod wiring | `lib/providers/` |
| Screens (Portfolio, Search, Add/Edit, Detail, Debug) | `lib/screens/` |

Data path: **UI → Riverpod providers → repositories → Drift**. Widgets never import drift.

Money is integer **paise**. Quantity is an integer **× 10,000**. CSV decimals become paise by string parsing (`"259.57"` → `25957`), and rounding happens only for display.

## Porting to Brokd

**Move as-is.** These have no app-specific dependencies:

- `lib/utils/money.dart`, `portfolio_math.dart`, `trading_day.dart`, `instrument_type.dart`, `symbol_search.dart`, `holding_validation.dart`
- `lib/models/` (`instrument`, `daily_file`, `holding`, `price_quote`, `network_event`)
- `lib/services/` (`bhavcopy_parser`, `csv_table`, `equity_list_parser`, `price_provider`, `nse_bhavcopy_provider`, `fixture_price_provider`, `price_fetch_errors`, `network_log`, `refresh_service`, `file_cache`)
- `lib/constants/nse_urls.dart`
- Their tests under `test/utils`, `test/models` and `test/services`, plus `test/helpers/fixtures.dart` and `test/fixtures/`

**Move with changes:**

1. **Tables** (`lib/database/tables/*.dart` except `app_settings`). Add them to Brokd's `@DriftDatabase` list. Bump Brokd's `schemaVersion` (currently 8 → 9) and add an `onUpgrade` step that runs `m.createTable(...)` for `instruments`, `investmentTransactions`, `priceQuotes` and `symbolMaster`. Then regenerate `app_database.g.dart`.
2. **Settings.** Brokd keeps settings in SharedPreferences (`services/profile_store.dart`). Re-implement `SettingsRepository` over that store and keep the key names from `SettingKeys`. Then drop the `app_settings` table.
3. **Database connection.** Brokd opens SQLite with `drift_flutter`'s `driftDatabase(...)`. Use Brokd's connection and drop this app's `LazyDatabase`/`NativeDatabase` opener. Neither app needs `sqlite3_flutter_libs`: sqlite3 3.x bundles SQLite itself.
4. **Repositories** (`lib/repositories/*`). These take `AppDatabase`, so they port unchanged against Brokd's class. Brokd keeps most query logic in `app_database.dart`; either keep these repositories thick, or move the queries in to match.
5. **Providers.** Merge `repository_providers.dart`, `service_providers.dart` and `refresh_providers.dart` into Brokd's `lib/providers/`, and reuse Brokd's `appDatabaseProvider`.
6. **Refresh trigger.** Call `refreshControllerProvider.notifier.refresh()` from Brokd's `AppGate` resume handler instead of `NsePriceSpikeApp`'s `AppLifecycleListener`.
7. **Screens.** Restyle with Brokd's theme tokens and Inter font, use Brokd's formatters (`lib/utils/formatters.dart`) where they overlap `money.dart`, and route through Brokd's navigation. Hide the Debug screen behind Brokd's debug Profile row.
8. **Assets.** Ship the fixture assets only in debug builds, or drop Fixture mode from release builds.

**Not done in the spike:** sells and realised P&L, corporate actions (splits and bonuses), series other than EQ/BE (SM, ST, GB, …), and a background price job when the app is closed.
