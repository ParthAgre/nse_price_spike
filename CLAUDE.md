# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`nse_price_spike` is a standalone Android-only Flutter spike. It validates tracking stock and ETF holdings with end-of-day prices from NSE's free daily bhavcopy, before integrating into Brokd (`E:\Projects\Fyntrest\brokd`). It mirrors Brokd's conventions so modules can be copied across; see "Porting to Brokd" in `README.md`.

- **Stack:**
  - Flutter 3.44 / Dart 3.12 (`sdk: ^3.12.2`)
  - flutter_riverpod 2.x
  - Drift (+ drift_dev, build_runner), path_provider, http, archive, csv 8.x
  - Plain Material UI
- **Allowed dependencies:** only the ones above. **Ask before adding any other dependency.** `sqlite3_flutter_libs` was removed on purpose: sqlite3 3.x bundles SQLite through build hooks, and 0.6.0+eol is an empty stub.
- **Status:** `STATUS.md` holds the current status, check results and next steps. `docs/USER_SOP.md` is the user guide.
- **Never** touch other projects, or commit or push without explicit approval.

## Commands (verified on this machine)

```bash
flutter pub get
flutter analyze
flutter test --timeout 90s                   # all tests; no network, in-memory Drift
flutter test test/services/refresh_service_test.dart
dart run build_runner build                  # after any change in lib/database/tables/
dart format lib test
flutter build apk --debug
cd android && JAVA_HOME="/e/Softwares/Android Studio/jbr" ./gradlew --stop   # free memory after builds
```

- **Emulator:**
  - `flutter emulators --launch Pixel_9` works.
  - Launching `emulator.exe` directly from the Bash tool exited with code 127.
- **Install and launch:** `adb install -r build/app/outputs/flutter-apk/app-debug.apk`, then `adb shell monkey -p com.fyntrest.nse_price_spike -c android.intent.category.LAUNCHER 1`.
- **360 dp screen:** `adb shell wm size 720x1600 && adb shell wm density 320`. Undo with `wm size reset` and `wm density reset`.
- **adb in Git Bash:** set `MSYS_NO_PATHCONV=1`, or paths like `/sdcard/ui.xml` get rewritten.

## Architecture

**Data path:** UI → Riverpod providers (`lib/providers/`) → repositories (`lib/repositories/`) → `AppDatabase` (Drift).

- **Widgets never import `lib/database/` or drift.** Reads go through `StreamProvider`s; writes go through `ref.read(xRepositoryProvider)` or `refreshControllerProvider.notifier`.
- **Holdings are derived, never stored.** `HoldingsRepository.watchHoldings()` re-reads transactions and quotes on every change, via `tableUpdates`.
- **Pure logic lives in `lib/utils/` and `lib/models/`**, all unit-tested:
  - `portfolio_math.dart`
  - `money.dart`
  - `trading_day.dart`
  - `symbol_search.dart`
  - `holding_validation.dart`
  - `selectEffectivePrice` in `price_quote.dart`
- **`RefreshService`** (`lib/services/refresh_service.dart`) owns every refresh rule. It never throws; failures become `RefreshOutcome`s. `RefreshController` builds it per run for the current mode.
- **Settings** (mode, download bookkeeping, file stats) are in the Drift `app_settings` key/value table (`SettingKeys`). This is because shared_preferences is not an allowed dependency.
- **`FileCache`** keeps the latest bhavcopy zip, so an instrument that isn't held yet can show its close. When a holding is added, it is back-filled from this cache.
- **Test seams** are provider overrides: `clockProvider`, `fixtureLoaderProvider`, `fileCacheProvider`, `useIsolateProvider` (false in tests) and `appDatabaseProvider`.

## Rules (from the spec; don't regress)

- **ISIN is identity.** Match instruments across files by ISIN; the symbol is display-only.
- **Instrument type:** `INE` with type code `01` (ISIN characters 8–9) → stock; `INF` → ETF; anything else is ignored. This covers debentures, REIT/InvIT units, rights entitlements, gold bonds, G-secs and IN9 DVRs. The rule is `instrumentTypeFromIsin`.
- **Price** = `ClsPric`, **never** `LastPric`. Previous close = `PrvsClsgPric`.
- **Series:** keep rows **by ISIN, not by series**.
  - Every series counts except **BL** (block deals), which repeats EQ ISINs at other closes.
  - Duplicate ISINs resolve EQ > BE > BZ > SM > ST > others (`seriesPriority`).
  - Count every series, kept and total, on the Debug screen.
  - The data check behind this rule (21 Oct 2026 fixture) is in `STATUS.md`.
- **Locate CSV columns by header name** with a real CSV parser. Trim headers; EQUITY_L has leading spaces.
- **One URL constant:** `bhavcopyUrlPattern` in `lib/constants/nse_urls.dart`. Send the browser User-Agent.
- **Money and quantity:** integer paise, and quantity × 10,000. Convert decimal strings to paise by string parsing (`parseDecimalToPaise`), never through `double`. Round only for display.
- **Avg cost excludes fees; invested includes them.**
- **Refresh:**
  - Expected day = today if it is a weekday and ≥ **17:00 IST**, else the previous weekday.
  - **A 404 for today's file means "not published yet":**
    - Keep the previous prices.
    - It does **not** count as the day's download (`lastSuccessIstDate` is unchanged, even if an earlier day was fetched in the same run).
    - Retry on the next open/resume (`automatic: true`), at most once per 30 minutes (`todayPendingCheckedAt`). A manual refresh and "Download now" are not throttled.
  - For earlier dates, on a 404 walk back over weekdays: at most 5 tries in total, stopping at the stored day.
  - At most one counted download per IST day, unless forced ("Download now").
  - On any other error, keep the cache and show "Couldn't reach NSE — prices as of {date}".
  - Store quotes only for held ISINs.
  - From each file, replace the `origin = 'bhavcopy'` rows of `symbol_master`: every kept row that EQUITY_L lacks.
  - Record `Last-Modified` and the zip entry time in the publish log (Debug → Publish times).
  - EQUITY_L: download on first run, then at most weekly. It replaces only the `origin = 'equity_l'` rows.
- **Manual price** is dated today (IST). A file price overrides it only when the file's trade date is strictly newer.
- **Tests make no real network calls.** Use `MockClient` (`package:http/testing.dart`) or `ScriptedPriceProvider` (`test/helpers/fixtures.dart`).
- **Fixtures** live in `test/fixtures/`. The zip and EQUITY_L are also app assets for Fixture mode.

## Gotchas

- **Widget tests:** read fixture bytes in `setUpAll` (`memoryFixtureLoader()`), because real file I/O doesn't complete inside `testWidgets`' fake async. Unmount with `pumpWidget(SizedBox())` at the end of each test.
- **`runParse`** sends a top-level function plus its argument to `Isolate.run`. Never pass a closure that captures `this`, or it would try to copy the http client.
- **Search ranking:**
  - Groups: exact symbol (or exact ISIN), then symbol prefix, then name contains. A match inside a symbol alone is not a match.
  - Within a group: traded value (`TtlTrfVal`) from the latest cached bhavcopy, descending; instruments without one go last, then A–Z.
  - `symbolSearchIndexProvider` (in `refresh_providers.dart`) rebuilds when `latestFileProvider` is invalidated.
- **Schema is v2.** It added `symbol_master.origin`. Write a migration step in `AppDatabase.migration` for every schema change, and test it the way `test/repositories/migration_test.dart` does.
- **Zip entry times have no time zone.** They are read as IST.
- **Shell heredocs:** heredocs that contain apostrophes can fail in the Bash tool. Write the file with the Write tool instead.
