# Status: nse_price_spike

_Last updated 2026-10-22 14:15 IST._

## Snapshot

- **State:** round 3 is done: the multi-asset Investments screen and fixed deposits (FDs).
  - Round 2 is committed as `6c4885c` (approved). Round 3 is **uncommitted** on top of it and awaits approval.
- **Checks** (2026-10-22, Flutter 3.44.8 / Dart 3.12.2):

  | Check | When (IST) | Result |
  |---|---|---|
  | `dart format --set-exit-if-changed lib test` | 14:05 | 0 files changed (after formatting) |
  | `flutter analyze` | 14:05 | No issues found |
  | `flutter test --timeout 90s` | 14:05 | **211 tests, all passed** (was 146); slowest test 3.6 s, whole suite ≈ 15 s |
  | `flutter build apk --debug` | 14:06 | Built `build/app/outputs/flutter-apk/app-debug.apk` |

- **Emulator check** (Pixel_9, 13:54–14:10 IST): details under "Device check" below. Upgrade v2 → v3 kept the RELIANCE holding; no overflow at 1080×2424, nor at 360 dp with text scale 1.3.

## Round 3 changes

### Investments screen (replaces Portfolio as home)

- **Summary card:** Current value (whole rupees), Invested, Returns (₹ and %, with an info button), "Today (stocks & ETFs)", footer "Market prices as of {date} · FD values as of today".
- **Allocation bar** (CustomPaint) by asset class with a % legend, shown when more than one class is held.
- **Filter chips** All · Stocks · ETFs · FDs (only held classes). **Total / Today toggle** (stock/ETF rows only). **Sort menu:** Current value, Returns %, Today's change, Name, and Maturity date (FDs only, its default).
- **Rows:** stocks/ETFs show name, symbol, "{qty} shares · avg ₹x" (ETFs: "units"), value and % (total or today). FDs show bank · nickname, "₹principal · rate% · matures {date} ({n} days)", value (≈ until maturity), "+₹interest", and a Maturing soon / Matured chip.
- **Matured FDs** are pinned with "Renewed or withdrawn?". **Closed FDs** are in a collapsible "Closed (n)" section, out of every total.
- **Empty state** "Track your investments" with "Add a stock or ETF" and "Add a fixed deposit". **"+ Add"** opens a sheet: Stock or ETF / Fixed deposit.
- **Formatting:** `formatRupees` uses Indian grouping and "−" (U+2212) for negatives; `formatRupeesWhole` for large figures; percentages have 2 decimals and an explicit sign. Gain/loss colours come from the `GainLossColors` theme extension and always pair with a sign.
- **Copy** is in `lib/constants/strings.dart`; screens are built from widgets in `lib/widgets/` that take state and callbacks.

### Stock/ETF form and detail

- Form: Quantity, Average buy price ("From your broker's holdings page"), then a collapsed **More details** (Purchase date — blank = opening position; Charges; Notes ≤ 200 characters).
- **Live preview:** "Invested ₹11,000 · worth ₹12,090 today (+9.91%)" from the latest close, or "No price yet — will update after the next NSE file".
- Detail: Current value, Returns, Today, entries with edit and delete, a CustomPaint price line from stored NSE closes (hidden with fewer than 2), Set manual price, close history.

### Fixed deposits

- **Form:** bank (suggestions from earlier entries), principal, rate (up to 3 decimals), start date (future allowed), tenure in years/months/days **or** a maturity date (the other is shown), Cumulative or Payout (Monthly / Quarterly / Half-yearly / Yearly). More details: compounding (default Quarterly), receipt maturity amount, payout amount per period, nickname, notes.
- **Validation:** principal > 0; 0 < rate ≤ 20; maturity after start and at most 10 years later; receipt amount > principal; notes ≤ 200.
- **Live preview:** "Matures {date} · ₹{maturity} · interest ₹{interest}", plus "Using your bank's figure (app estimate ₹X)" when the receipt differs by more than ₹1.
- **Detail:** principal, rate, type, start → maturity with a progress bar, value today (≈), interest so far, maturity amount, days left, receipt figure in use; Edit, Close early, Delete; Withdrawn / Renewed when matured.
- **Lifecycle:** Withdrawn (amount, default = maturity amount; date), Renewed (opens the form prefilled with principal = maturity amount for cumulative or principal for payout, start = old maturity date, same bank, rate and tenure; saving closes the old FD as renewed and links them), Close early (amount, default = today's value; date).

### FD maths: assumptions (also in `lib/utils/fd_math.dart`)

1. **Day count is actual/365**, also in leap years. Some banks use 366 for leap-year days, so values can differ by a few rupees.
2. **Short FDs:** if maturity is before start + 6 calendar months, interest is **simple**: P × r × days/365.
3. **Otherwise compound:** P × (1 + r/n)^(n × days/365), n = compounding periods per year. Broken periods compound fractionally.
4. **Rounding:** doubles only inside the formulas; one half-up rounding to the nearest paisa at the end. Storage stays in integer paise; rates are thousandths of a percent (7.125% = 7125).
5. **Maturity date from tenure:** start + years + months (clamped to month end: 31 Jan + 1 month = 28/29 Feb) + days. Only the maturity date is stored.
6. **Value of a cumulative FD:** principal before the start; maturity amount on and after maturity; in between the receipt-calibrated curve P × (M/P)^(elapsed/total) when a receipt amount M exists (it hits M exactly at maturity), else the formula with elapsed days. Shown with "≈" except at or before the start and at maturity.
7. **Payout FDs:** value is always the principal; maturity amount = principal. Interest per period = the bank's figure if entered, else P × r / k (labelled ≈; banks typically pay a little less than r/12 monthly). Interest received = completed periods (month steps from the start date, month-end clamped) × interest per period. A final broken period shorter than one step is not counted.
8. **Returns:** cumulative = value − principal; payout = interest received so far. In the summary, payouts received count in Returns but not in Current value.
9. **Closed FDs:** realised interest = amount received − principal (+ payouts already received for payout FDs); lower than the accrued value when a penalty applied.
10. **Status:** Upcoming (start > today), Active, Maturing soon (≤ 30 days to maturity), Matured (today ≥ maturity, not closed), Closed (withdrawn / renewed / closed early, stored).

Required values (unit-tested): ₹1,00,000 at 7% quarterly for 1 year → **10718590 paise**; ₹50,000 at 6% for 90 days (simple) → **5073973 paise**.

### Data model: schema v3

- `investment_transactions.notes` (nullable).
- New `fixed_deposits`: institution, nickname, principal_paise, rate_milli_pct, start_date, maturity_date, interest_type, payout_frequency, compounding, receipt_maturity_paise, payout_amount_paise, status, closed_on, amount_received_paise, renewed_into_id (plain integer, not a foreign key, so either FD can be deleted; links are cleared on delete), notes, created_at.
- Migration v2 → v3 tested from the exact v2 SQL with a RELIANCE holding and quote: holding, value and day change survive; notes and FDs are usable afterwards.

### Tests (211)

- **Unit:** `money_test` (lakh/crore grouping, negatives, zero, whole rupees, signed %, rates), `fd_math_test` (required values, month-end and leap years, 6-month boundary, compounding, receipt curve, monotonic value, future start, payout steps), `fixed_deposit_test` (status), `investments_summary_test` (mixed stocks + ETF + FDs, closed FD excluded, Today from market only), `holding_sort_test`, `fd_validation_test`.
- **Repository:** `fixed_deposit_repository_test` (round-trip, renew + link, close early, payout realised interest, suggestions), `migration_v3_test`.
- **Widget:** `investments_flow_test` (empty state → add FD with value and chip; stock preview with More details collapsed; chips and Total/Today; sorting; returns info), `fd_lifecycle_test` (matured → Renewed → prefilled, old in Closed; Close early → realised interest; Withdrawn), and the adapted `portfolio_flow_test`.

## Device check (Pixel_9, 2026-10-22 13:54–14:10 IST)

- **Upgrade:** installed over the v2 install. RELIANCE survived: ₹12,090.00, +₹1,090.00 (+9.91%), today +₹70.00 (+0.58%).
- **Added through the UI:** TCS 5 @ ₹2,400 + ₹20 charges + note; NIFTYBEES 100 @ ₹250; SBI ₹2,00,000 at 7.1% cumulative, 15 Jan 2026 + 2 years, receipt ₹2,30,000; HDFC Bank ₹5,00,000 at 7% monthly payout, 10 Jun 2026 + 3 years; Axis Bank "Short term" ₹50,000 at 6%, 1 Sep 2026 + 90 days; ICICI Bank ₹1,00,000 at 7%, 1 Jan 2025 + 1 year (matured).
- **Hand checks:**
  - SBI estimate 2,00,000 × 1.01775^8 = ₹2,30,228.39 (app: same, with the receipt note). Value today 2,00,000 × 1.15^(280/730) = ₹2,11,014.0 (app ≈₹2,11,014.04); 450 days left.
  - HDFC payout ₹2,916.67 × 4 completed months = ₹11,666.68 (app ≈+₹11,666.68); total over 36 months ₹1,05,000.12.
  - Axis: 50,000 × 6% × 51/365 = ₹419.18; maturity ₹50,739.73 (the required value).
  - ICICI: ₹1,07,185.90 (the required value). Renewed on the device: new FD prefilled with ₹1,07,185.90 from 1 Jan 2026; preview ₹1,14,888.17; value today ≈₹1,13,347.76; old FD in "Closed (1)" with realised +₹7,185.90.
  - Totals before renewal: value ₹9,19,311, invested ₹8,98,020.00, returns +₹32,957.80 — all match the sum of the rows.
- **Exercised:** every chip, the Total/Today toggle, every sort option (orders correct), the add sheet, bank suggestions, both detail screens, the FD form in payout mode.
- **Layout:** no overflow at 1080×2424 or at 360 dp with text scale 1.3 (logcat had no "overflowed"). Fixed during the check: FD row detail line was truncated at 2 lines at scale 1.3 ("(45…"); it now wraps fully. The detail screen's "Principal (₹)" label became "Principal".
- **Left behind:** emulator display reset to native size and font scale 1.0; the app (Fixture mode) holds the data above; Gradle daemons stopped.

## Decisions and deviations (cumulative)

- **`sqlite3_flutter_libs` removed** (approved round 1). sqlite3 3.x bundles SQLite.
- **Settings live in a Drift `app_settings` key/value table**, because shared_preferences isn't allowed. The publish log is stored there as JSON and survives "Clear cache".
- **`symbol_master`** has extra `series` and `origin` columns. **`price_quotes`** has an autoincrement `id`.
- **Latest bhavcopy zip is cached** on the device (closes for unheld instruments, backfill, traded values for search).
- **Fixture mode** serves the 21 Oct 2026 file for any day; after 17:00 it counts as the day's download.
- **Zip entry times** carry no time zone and are read as IST.
- **Round 3:**
  - "−" (U+2212) for negatives (approved); `money_test` expectations for −₹70.00 and −10.00% updated accordingly.
  - `portfolio_flow_test` adapted to the new screen (approved): same numbers; navigation via the add sheet; "Track your investments" and the new footer; Current value now shown in whole rupees ("₹12,090").
  - `migration_test` (v1 → v2) fixture gained the v1 `instruments` and `investment_transactions` tables: the v3 step alters `investment_transactions`, which every real v1 database has.
  - ETF rows say "units" instead of "shares".
  - Chips: changing the filter resets the sort to that filter's default. Chips wrap rather than scroll sideways.
  - The Returns info button sits next to "Returns" rather than in the card header.
  - The Debug screen keeps its own text (not moved to `strings.dart`).
  - Renewal closes the old FD only when the new one is saved; cancelling the form leaves it matured.

## Round 2 data check (21 Oct 2026 bhavcopy; still true)

INE rows by series and ISIN type code (characters 8–9):

| Code | Series (rows) | Meaning |
|---|---|---|
| **01** | EQ 2340, SM 393, BE 222, ST 83, BZ 29, BL 5 | equity shares; **no other code appears in any equity series** |
| 07 / 08 | N0–NZ, Y*, Z* (133 / 11) | debentures and bonds |
| 23 | IV (13) | InvIT units |
| 25 | RR (6) | REIT units |
| 24, A7 | N1 (2), NR/NS (2) | strips, secured NCDs |

- ETFs: all 353 INF rows are in EQ. IN0 (GB 43, GS 50, TB 12), IN1–IN4 (SG 7) and IN9 (BZ 1, E1 2, EQ 1 DVR) are excluded.
- BL repeats 5 EQ ISINs at different closes (ADANIENSOL BL 1334.00 vs EQ 1324.00), so BL is excluded; duplicates resolve EQ > BE > BZ > SM > ST.
- Kept: 3,420 rows; `symbol_master` = 3,434 (2,605 EQUITY_L + 829 from the bhavcopy). EQUITY_L's OLAELEC-RE (`INE0LXG20016`, code 20) is excluded.

## Fixture findings (round 1, still true)

- Bhavcopy: 3,708 rows, 34 columns, LF line endings, no quoted fields, 2-decimal prices.
- EQUITY_L: no INF rows (ETFs come only from the bhavcopy), BZ rows, 2 IN9 rows, some headers with leading spaces.
- NIFTYBEES ISIN: EODHD's search fixture has `INF732E01011`; NSE has `INF204KB14I2`.

## Known limitations

- No sells, FIFO, realised P&L for stocks, dividends or corporate actions.
- REIT/InvIT units, IN9 DVRs, bonds, gold bonds, mutual funds, gold and RDs are not tracked; no TDS or tax.
- FD values are estimates (≈) unless a receipt figure is entered; actual/365 may differ from a bank's leap-year convention.
- No FD maturity notifications and no automatic renewal.
- The network-event list is in memory; the publish log persists.
- Mode switch: a Fixture download counts as the day's download; after switching to Live the same day, use "Download now".

## Next steps

1. Review round 3 and approve a commit.
2. Update the shared SOP from "Changes for the shared SOP" in the round-3 report, and paste its link into `docs/USER_SOP.md`.
3. Run a Live "Download now" from a device with internet to record a real `Last-Modified`; soak-test publish times, then revisit the 17:00 cutoff.
4. Ask a design pass to restyle via `strings.dart`, `GainLossColors` and the widgets in `lib/widgets/`.
