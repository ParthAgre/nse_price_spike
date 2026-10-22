// Every user-facing string of the app's screens, in one place, so copy can
// be reviewed and changed without touching layout code. (The Debug screen is
// a developer tool and keeps its own text.)

abstract final class S {
  // App and home.
  static const appTitle = 'Investments';
  static const investmentsTitle = 'Investments';
  static const refresh = 'Refresh';
  static const debug = 'Debug';
  static const add = 'Add';
  static const retry = 'Retry';
  static String couldntReach(String pricesAsOf) =>
      "Couldn't reach NSE — $pricesAsOf";
  static String loadFailed(Object e) => 'Could not load: $e';

  // Summary card.
  static const currentValue = 'Current value';
  static const invested = 'Invested';
  static const returns = 'Returns';
  static const todayMarket = 'Today (stocks & ETFs)';
  static const returnsInfoTooltip = 'What are returns?';
  static const returnsInfo =
      'Returns: what your investments are worth now minus what you paid; '
      'not yet sold, before charges and tax.';
  static const ok = 'OK';
  static String footer(String date) =>
      'Market prices as of $date · FD values as of today';
  static const footerNoPrices = 'No market prices yet · FD values as of today';
  static String unpriced(int n) => n == 1
      ? '1 holding has no price yet and is not in the value.'
      : '$n holdings have no price yet and are not in the value.';

  // Asset classes, filters, sorting.
  static const classStocks = 'Stocks';
  static const classEtfs = 'ETFs';
  static const classFds = 'FDs';
  static const filterAll = 'All';
  static const allocationLabel = 'Allocation by asset class';
  static const toggleTotal = 'Total';
  static const toggleToday = 'Today';
  static const sortTooltip = 'Sort';
  static const sortValue = 'Current value';
  static const sortReturns = 'Returns %';
  static const sortToday = "Today's change";
  static const sortName = 'Name';
  static const sortMaturity = 'Maturity date';

  // Holding rows.
  static String sharesLine(String qty, String avg, {required bool etf}) =>
      '$qty ${etf ? 'units' : 'shares'} · avg $avg';
  static const noPrice = 'No price yet';
  static const approx = '≈';

  // FD rows.
  static String fdLine(String principal, String rate, String rest) =>
      '$principal · $rate% · $rest';
  static String maturesIn(String date, int days) =>
      'matures $date (${days == 1 ? '1 day' : '$days days'})';
  static String maturedOn(String date) => 'matured $date';
  static String startsOn(String date) => 'Starts on $date';
  static const chipMaturingSoon = 'Maturing soon';
  static const chipMatured = 'Matured';
  static const chipUpcoming = 'Upcoming';
  static const maturedPrompt = 'Renewed or withdrawn?';
  static const withdrawn = 'Withdrawn';
  static const renewed = 'Renewed';
  static String closedSection(int n) => 'Closed ($n)';
  static String closedWithdrawn(String date) => 'Withdrawn on $date';
  static String closedRenewed(String date) => 'Renewed on $date';
  static String closedEarly(String date) => 'Closed early on $date';
  static const realisedInterest = 'Realised interest';

  // Empty state and add sheet.
  static const emptyTitle = 'Track your investments';
  static const emptyBody =
      'Add your stocks, ETFs and fixed deposits to see them in one place.';
  static const addStockOrEtf = 'Add a stock or ETF';
  static const addFd = 'Add a fixed deposit';
  static const sheetTitle = 'What do you want to add?';
  static const sheetStock = 'Stock or ETF';
  static const sheetStockHint = 'Listed on NSE · priced from the daily file';
  static const sheetFd = 'Fixed deposit';
  static const sheetFdHint = 'Valued with interest maths';

  // Search.
  static const searchHint = 'Symbol, name or ISIN';
  static String searchPrompt(int n) => 'Type to search $n stocks and ETFs.';
  static const searchNoMatches = 'No matches.';
  static const searchNoList =
      'The symbol list has not been downloaded yet. Go back and pull down to '
      'refresh, or use Debug → "Re-download EQUITY_L".';
  static String searchLoadFailed(Object e) => 'Could not load symbols: $e';

  // Stock/ETF form.
  static const addStockTitle = 'Add stock or ETF';
  static const editEntryTitle = 'Edit entry';
  static const quantity = 'Quantity';
  static const wholeShares = 'Whole shares';
  static const etfUnits = 'Units (up to 4 decimals)';
  static const avgBuyPrice = 'Average buy price (₹)';
  static const avgBuyPriceHint = "From your broker's holdings page";
  static const moreDetails = 'More details';
  static const purchaseDate = 'Purchase date';
  static const purchaseDateBlank = 'Blank = opening position';
  static const pick = 'Pick';
  static const clearDate = 'Clear date';
  static const charges = 'Charges (₹)';
  static const nickname = 'Nickname';
  static const notes = 'Notes';
  static const save = 'Save';
  static const saving = 'Saving…';
  static const cancel = 'Cancel';
  static const delete = 'Delete';
  static String couldNotSave(Object e) => 'Could not save: $e';
  static String latestClose(String price, String date) =>
      'Latest close: $price ($date)';
  static String latestPrice(String price, String date) =>
      'Latest price: $price ($date)';
  static const latestCloseUnknown = 'Latest close: not known yet';
  static String stockPreview(String invested, String worth, String pct) =>
      'Invested $invested · worth $worth today ($pct)';
  static const stockPreviewNoPrice =
      'No price yet — will update after the next NSE file';
  static const deleteEntryTitle = 'Delete entry?';
  static String deleteEntryMessage(String symbol) =>
      'This removes this entry of $symbol. It cannot be undone.';

  // Validation (stocks).
  static const enterQuantity = 'Enter a quantity';
  static const quantityFormat = 'Enter a number (up to 4 decimals)';
  static const quantityPositive = 'Quantity must be more than 0';
  static const stocksWhole = 'Stocks need a whole number';
  static const enterPrice = 'Enter a price';
  static const priceFormat = 'Enter a price like 1209.50';
  static const pricePositive = 'Price must be more than 0';
  static const feesFormat = 'Enter an amount like 20.50';
  static const notesTooLong = 'Notes can be up to 200 characters';

  // Stock/ETF detail.
  static const today = 'Today';
  static const avgBuyPriceShort = 'Avg buy price (excl. charges)';
  static const investedInclCharges = 'Invested (incl. charges)';
  static const latestCloseLabel = 'Latest close';
  static const manualPriceLabel = 'Manual price';
  static const priceHistory = 'Price history';
  static const entries = 'Entries';
  static const addEntry = 'Add entry';
  static const setManualPrice = 'Set manual price';
  static const manualPriceHelper = 'Dated today. A newer NSE file replaces it.';
  static const priceField = 'Price (₹)';
  static const openingPosition = 'Opening position';
  static String boughtOn(String date) => 'Bought $date';
  static String entryLine(String qty, String price, String? charges) =>
      '$qty @ $price${charges == null ? '' : ' · charges $charges'}';
  static const closeHistory = 'Close history';
  static const noStoredPrices = 'No stored prices yet.';
  static const manual = 'Manual';
  static String nseClosePrev(String prev) => 'NSE close · prev $prev';
  static const deleteHolding = 'Delete holding';
  static const deleteHoldingTitle = 'Delete holding?';
  static String deleteHoldingMessage(int n, String symbol) =>
      'This removes all $n entries of $symbol. It cannot be undone.';
  static const noEntries = 'This holding has no entries.';

  // FD form.
  static const addFdTitle = 'Add fixed deposit';
  static const editFdTitle = 'Edit fixed deposit';
  static const renewFdTitle = 'Renew fixed deposit';
  static String renewing(String name) =>
      'Renewing $name. Check the new rate and tenure.';
  static const institution = 'Bank or institution';
  static const principal = 'Principal (₹)';
  static const principalLabel = 'Principal';
  static const rate = 'Interest rate (% p.a.)';
  static const startDate = 'Start date';
  static const byTenure = 'Tenure';
  static const byMaturityDate = 'Maturity date';
  static const years = 'Years';
  static const months = 'Months';
  static const days = 'Days';
  static String maturesOnDerived(String date) => 'Matures on $date';
  static String tenureDerived(int y, int m, int d) => 'Tenure: $y y $m m $d d';
  static const interestType = 'Interest';
  static const cumulative = 'Cumulative';
  static const payout = 'Payout';
  static const payoutFrequency = 'Payout frequency';
  static const compounding = 'Compounding';
  static const monthly = 'Monthly';
  static const quarterly = 'Quarterly';
  static const halfYearly = 'Half-yearly';
  static const yearly = 'Yearly';
  static const receiptAmount = 'Maturity amount from your FD receipt (₹)';
  static const receiptHint =
      'Recommended: makes values match your bank exactly';
  static const payoutAmount = 'Payout amount per period (₹)';
  static String fdPreview(String date, String maturity, String interest) =>
      'Matures $date · $maturity · interest $interest';
  static String usingReceipt(String estimate) =>
      "Using your bank's figure (app estimate $estimate)";

  // Validation (FDs).
  static const enterInstitution = 'Enter the bank or institution';
  static const enterPrincipal = 'Enter the principal';
  static const amountFormat = 'Enter an amount like 100000.50';
  static const principalPositive = 'Principal must be more than 0';
  static const enterRate = 'Enter the interest rate';
  static const rateFormat = 'Enter a rate like 7.125 (up to 3 decimals)';
  static const ratePositive = 'Rate must be more than 0';
  static const rateTooHigh = 'Rate must be 20% or less';
  static const enterTenure = 'Enter a tenure';
  static const tenureWhole = 'Use whole numbers';
  static const maturityAfterStart = 'Maturity must be after the start date';
  static const tenureTooLong = 'Tenure can be at most 10 years';
  static const receiptAboveFrom = 'Must be more than the principal';
  static const amountPositive = 'Amount must be more than 0';

  // FD detail.
  static const rateLabel = 'Rate';
  static const typeLabel = 'Type';
  static String typeCumulative(String compounding) =>
      'Cumulative · compounded ${compounding.toLowerCase()}';
  static String typePayout(String frequency) =>
      'Payout · ${frequency.toLowerCase()}';
  static const startToMaturity = 'Start → maturity';
  static String daysProgress(int elapsed, int total) =>
      '$elapsed of $total days';
  static const valueToday = 'Value today';
  static const interestSoFar = 'Interest so far';
  static const interestReceived = 'Interest received so far';
  static const interestPerPeriod = 'Interest per period';
  static const maturityAmount = 'Maturity amount';
  static const daysLeft = 'Days left';
  static const receiptFigure = 'Receipt figure';
  static const receiptInUse = 'In use';
  static const receiptNotEntered = 'Not entered (app estimate)';
  static const notApplicable = 'Not used for payout FDs';
  static const edit = 'Edit';
  static const closeEarly = 'Close early';
  static const deleteFdTitle = 'Delete fixed deposit?';
  static String deleteFdMessage(String name) =>
      'This removes $name. It cannot be undone.';
  static const status = 'Status';
  static const amountReceived = 'Amount received (₹)';
  static const amountReceivedLabel = 'Amount received';
  static const closedOnLabel = 'Date';
  static const confirm = 'Confirm';
  static const closeDateBeforeStart = 'Date must be on or after the start date';
  static const fdNotFound = 'This fixed deposit no longer exists.';
}
