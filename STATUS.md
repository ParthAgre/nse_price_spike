# Status: nse_price_spike

_Last updated 2026-10-22 11:45 IST._

## Snapshot

- **State:** round 2 is done. It covers ISIN-based coverage, traded-value search ranking, the 17:00 / not-published-yet refresh rules, the publish-time log, and the docs.
  - The changes are **uncommitted** on top of `48c3cbd Initial commit` and await approval.
- **Checks** (2026-10-22, Flutter 3.44.8 / Dart 3.12.2):

  | Check | When (IST) | Result |
  |---|---|---|
  | `dart format --set-exit-if-changed lib test` | 11:43 | 0 files changed |
  | `flutter analyze` | 11:43 | No issues found |
  | `flutter test --timeout 90s` | 11:44 | **146 tests, all passed** (was 115) |
  | `flutter build apk --debug` | 11:30 | Built `build/app/outputs/flutter-apk/app-debug.apk`; no `lib/` change since |

- **Emulator check** (Pixel_9 at 360 dp, 11:49–11:58 IST): I installed the new APK over the round-1 install, which had a v1 database.
  - **Migration:** v1 → v2 ran cleanly. The existing RELIANCE holding was intact: ₹12,090.00, +₹70.00 (+0.58%).
  - **Live "Download now":** **timed out after 20 s**, because the cold-booted emulator had no internet (`ping 8.8.8.8` failed). The app handled it correctly: the event was logged as `timeout` and the cached prices were kept.
  - **Fixture "Download now":** the Debug chips showed kept/all as BE 222/222, ST 83/83, BZ 29/30, BL 0/5, GB 0/43. Publish times showed "Zip entry: 21 Oct, 16:31:02 IST".
  - **Search:** "agul" finds the SM stock AGUL (`INE0O6N01012`). "reli" lists RELIANCE first, then RELIGARE, then RELIABLE.

## Round 2 changes

### 1. Coverage by ISIN, not series

Data check on the real 21 Oct 2026 bhavcopy: INE rows by series and ISIN type code (characters 8–9).

| Code | Series (rows) | Meaning |
|---|---|---|
| **01** | EQ 2340, SM 393, BE 222, ST 83, BZ 29, BL 5 | equity shares; **no other code appears in any equity series** |
| 07 / 08 | N0–NZ, Y*, Z* (133 / 11) | debentures and bonds |
| 23 | IV (13) | InvIT units |
| 25 | RR (6) | REIT units |
| 24, A7 | N1 (2), NR/NS (2) | strips, secured NCDs |

- **ETFs:** all 353 INF rows are in EQ.
- **Non-INE/INF rows:**
  - IN0: GB 43, GS 50, TB 12
  - IN1–IN4: SG 7
  - IN9: BZ 1, E1 2, EQ 1 (JISLDVREQS, a DVR)
- **Decision (approved):** keep INE…01 as stocks and INF as ETFs from any series **except BL**.
  - BL (block deals) repeats 5 EQ ISINs at different closes. For example, ADANIENSOL has BL 1334.00 and EQ 1324.00.
  - Remaining duplicates resolve EQ > BE > BZ > SM > ST > others.
  - IN9, REIT and InvIT stay excluded.
- **Result:**
  - **3,420 kept rows** (was 2,915): EQ 2,693 (incl. 353 ETFs), SM 393, BE 222, ST 83, BZ 29.
  - **symbol_master is 3,434** (was 2,959): 2,605 from EQUITY_L + 829 from the bhavcopy (353 ETFs + 476 SM/ST stocks).
  - Schema **v2** adds `symbol_master.origin`, with a migration.
- **EQUITY_L:** 2,605 stocks (was 2,606). Its one non-01 INE row, `INE0LXG20016` OLAELEC-RE (a rights entitlement, code 20), is now excluded.
- **Tests:**
  - **Included:** BZ AGSTRA (`INE583L01014`, ₹2.05), SM AGUL (`INE0O6N01012`, ₹42.20), ST AARADHYA (`INE124401014`, ₹120.65).
  - **Excluded:**
    - debenture `INE916Y07073` (AFIL 11.50% 2029)
    - REIT `INE2OVN25015`
    - InvIT `INE1UA823019`
    - DVR `IN9175A01010`
    - all GB rows
  - **BL** never overrides EQ.
  - A synthetic test covers the duplicate-priority rule.

### 2. Search ranking

- **Groups:** exact symbol (or exact ISIN), then symbol prefix, then name contains.
- **Within a group:** `TtlTrfVal` from the latest cached bhavcopy, descending; instruments without one come next, then A–Z.
- **Behaviour change:** a match only *inside* a symbol (e.g. "BEES" in NIFTYBEES) no longer counts unless the name matches. NIFTYBEES is still found through its name.
- **Tests:**
  - "reli" puts RELIANCE (traded value ₹2,142 Cr) above RELIABLE.
  - "TCS" puts TCS (`INE467B01029`) first.
  - Synthetic tests cover group order and no-value ordering.

### 3. Refresh timing

- **Cutoff:** the expected day is today from **17:00 IST** (was 19:00).
- **Today's file 404s ("not published yet"):**
  - The previous prices are kept.
  - It doesn't count as the day's download, even if an earlier day was fetched in the same run.
  - Open/resume re-checks at most once every 30 minutes. A manual refresh and "Download now" are not throttled.
- **Earlier days:** the holiday fallback is unchanged.
- **Publish-time measurement:**
  - The server `Last-Modified` header is parsed and shown on each network event.
  - Each successful download also records `Last-Modified` and the zip entry timestamp in a persisted log (last 30), shown under Debug → "Publish times".
  - The fixture's zip entry is **16:31 IST**.
- **Tests added:** 17:00 boundary, not-published-yet outcome, no daily count, 30-minute throttle (29 vs 30 minutes), manual not throttled, published-later download, earlier file not counted, previous day's pending check doesn't throttle, publish log (and its cap of 30), Last-Modified parsing.

### 4. Docs

- `docs/USER_SOP.md` is now a short developer note pointing to the shared SOP. **The link is a placeholder (`<link to be added>`)** until you paste it.
- `README.md`, `CLAUDE.md` (rules and gotchas) and this file are updated.

## Decisions and deviations (cumulative)

- **`sqlite3_flutter_libs` removed** (approved round 1). sqlite3 3.x bundles SQLite.
- **Settings live in a Drift `app_settings` key/value table**, because shared_preferences isn't allowed. The publish log is stored there as JSON and survives "Clear cache".
- **`symbol_master`** has extra `series` and `origin` columns. **`price_quotes`** has an autoincrement `id`.
- **Latest bhavcopy zip is cached** on the device. It gives the close of instruments that aren't held yet, backfills a new holding, and supplies traded values for search ranking.
- **Fixture mode** serves the 21 Oct 2026 file for any day. After 17:00 that file counts as the day's download, because the file was found; only a 404 counts as "not published".
- **Zip entry times** carry no time zone and are read as IST.

## Fixture findings (round 1, still true)

- **Bhavcopy:** 3,708 rows, 34 columns, LF line endings, no quoted fields, prices with 2 decimals.
- **EQUITY_L:**
  - It has no INF rows, so ETFs come only from the bhavcopy.
  - It has BZ rows and 2 IN9 rows.
  - Only some headers have leading spaces.
- **NIFTYBEES ISIN:** EODHD's search fixture has `INF732E01011`; NSE has `INF204KB14I2`.

## Round 1 device check (2026-10-22, 03:27–03:36 IST)

- **Fixture mode:** RELIANCE 10 @ ₹1,100 → value ₹12,090.00, P&L +₹1,090.00 (+9.91%), day +₹70.00 (+0.58%). No overflow at 360 dp.
- **Live mode:** "Download now" fetched the real 21 Oct zip: HTTP 200, 203.3 KB, 471 ms.

## Known limitations

- No sells or realised P&L; no corporate actions.
- REIT/InvIT units, IN9 DVRs, bonds and gold bonds are not tracked.
- The network-event list is in memory. The publish log persists.
- **Mode switch:** a Fixture download counts as the day's download. After switching to Live the same day, use "Download now".

## Next steps

1. Review round 2 and approve a commit.
2. Paste the shared SOP link into `docs/USER_SOP.md`.
3. Run a Live "Download now" from a device with internet, to record a real `Last-Modified`.
4. Soak-test Live mode for a few evenings to collect real `Last-Modified` and zip times (Debug → Publish times). Then revisit the 17:00 cutoff.
