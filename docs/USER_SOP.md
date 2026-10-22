# User SOP: developer note

The step-by-step user guide for this app is the shared SOP, maintained outside this repo:

**Shared SOP:** `<link to be added>`

Keep that SOP in line with the code. Update it when a change affects any of these:

- **Screens and buttons:** Portfolio, Search, Add/Edit holding, Holding detail, Debug.
- **Refresh rules** (`lib/services/refresh_service.dart`, `lib/utils/trading_day.dart`):
  - Expected day = today from **17:00 IST** on weekdays.
  - A 404 for today's file means "not published yet": prices are kept, it doesn't count as the day's download, and open/resume re-checks at most every 30 minutes.
  - Holiday walk-back covers up to 5 weekdays.
  - One counted download per IST day; "Download now" bypasses this.
- **What's tracked** (`lib/utils/instrument_type.dart`, `lib/services/bhavcopy_parser.dart`):
  - Equity shares (ISIN `INE…01…`) from any series except BL.
  - ETFs (`INF…`).
- **Search ranking** (`lib/utils/symbol_search.dart`):
  - Groups: exact symbol, then symbol prefix, then name.
  - Within a group: by traded value.
- **Validation messages** (`lib/utils/holding_validation.dart`) and the error banner text.

`STATUS.md` records what's built and the check results; `README.md` covers running and porting.
