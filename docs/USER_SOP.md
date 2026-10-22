# NSE Price Spike: how to use the app

This short guide is for anyone testing the app. You don't need any coding knowledge.

The app tracks the stocks and ETFs you own. It values them at the **official NSE closing price**, which NSE publishes once a day in a free file called the *bhavcopy*. Prices are **end of day, not live**.

---

## 1. Install and open

1. Get the file `app-debug.apk` from the developer (it is built into `build/app/outputs/flutter-apk/`).
2. Install it on an Android phone or emulator, then open **NSE Price Spike**.
3. The **Portfolio** screen opens. The app checks for prices on its own in the background. A thin bar at the top moves while it works.

## 2. Fixture mode and Live mode

The app has two modes. You switch between them on the **Debug** screen: tap the bug icon at the top right of Portfolio.

| Mode | What it does | When to use it |
|---|---|---|
| **Fixture** (default) | Uses a saved NSE file from **21 Oct 2026** that is built into the app. It needs no internet. | Demos and testing. You always get the same, known prices. |
| **Live** | Downloads the real file from NSE. | To check real, current prices. |

To switch modes:

1. Open **Debug** and flip **Live mode (NSE)** on or off. The app remembers your choice.
2. After switching, tap **Download now** on the same screen so prices come from the new mode straight away. The app normally downloads only once a day, so without this step it may wait until tomorrow.

## 3. Add a holding

1. On Portfolio, tap **+ Add** at the bottom right.
2. Type part of a **symbol** (`RELI`), a **company name** (`reliance`) or a full **ISIN** (`INE002A01018`). Results appear as you type and use no internet.
3. Tap the right result. The **Add holding** screen shows the **Latest close** so you can sanity-check your price.
4. Fill in:
   - **Quantity:** more than 0. Stocks need whole shares; ETFs allow up to 4 decimals.
   - **Average buy price (₹):** more than 0, up to 2 decimals.
   - **Fees (₹, optional):** brokerage and taxes. Fees count in "Invested" but not in "Avg cost".
   - **Buy date (optional):** tap **Pick**. Leave it empty if this is a holding you already had (an *opening position*).
5. Tap **Save**. You return to Portfolio and the holding is valued right away.

> To add more of the same stock later, add it again, or use **Add entry** on its detail screen. Each purchase is kept as a separate entry, and the average is calculated for you.

## 4. Read the Portfolio screen

- **Total value:** quantity × latest closing price, summed over everything you hold.
- **Invested:** what you paid, including fees.
- **Unrealised P&L:** value minus invested, in ₹ and %.
- **Today's change:** how much the value moved since the previous day's close, in ₹ and %.
- **"Prices as of 21 Oct 2026 · NSE closing prices":** the trading day the prices are from.
- **Holdings list:** biggest value first. Each row shows the name, symbol, quantity, average cost, close, value and P&L. "(manual)" means you set that price yourself.

## 5. Refresh prices

You can refresh in any of three ways:

- Open the app, or come back to it. It checks on its own.
- Tap the **refresh icon** at the top.
- **Pull down** on the Portfolio list.

**When new prices appear:** NSE publishes the day's file in the evening. From **7:00 pm IST on a weekday** the app looks for that day's file. Before that, and at weekends, it uses the previous weekday.

**Holidays:** if NSE has no file for a day (for example an exchange holiday), the app tries up to 5 earlier weekdays.

**Once a day:** after one successful download the app won't download again that day. Use **Download now** on Debug if you need to force it.

## 6. Set a manual price

Use this if a price is missing or you want to test a value.

1. Tap the holding on Portfolio to open its detail screen.
2. Tap **Set manual price**, enter the price and tap **Save**.
3. The manual price is dated today. A newer NSE file replaces it automatically. A file for the same day or an older day does not.

## 7. Edit or delete

- **Edit an entry:** open the holding, tap the entry under **Entries**, change it, then tap **Save**.
- **Delete one entry:** on the edit screen, tap the **bin icon**, then **Delete**.
- **Delete the whole holding:** on the holding's detail screen, tap the **bin icon** at the top, then **Delete**. This can't be undone.

## 8. "Couldn't reach NSE — prices as of …"

This banner means the last download failed. Common causes are no internet, NSE blocking the request, or a bad or unfinished file.

- **Your data is safe.** The app keeps showing the last prices it had, with their date.
- Tap **Retry**, or try again later. For details, open **Debug** and look at **Last error** and the network list at the bottom.
- In **Fixture** mode this banner should never appear.

## 9. The Debug screen (for testers)

| Item | Meaning |
|---|---|
| Live mode toggle | Switch between Fixture and Live (see section 2). |
| Last file date / Downloaded at | Which trading day you have, and when it was fetched (IST). |
| File size / Rows parsed | Size of the NSE file and how many rows it had. |
| Holdings matched | How many of your holdings were found in the last file. |
| symbol_master size | How many stocks and ETFs search can find (about 2,960). |
| EQUITY_L fetched | When the stock list was last updated. It refreshes weekly. |
| Rows per series | Row counts per NSE series. Only **EQ** and **BE** (in bold) are used. |
| **Download now** | Fetch the latest file now, ignoring the once-a-day limit. |
| **Re-download EQUITY_L** | Refresh the stock list used by search. |
| **Clear cache** | Forget downloaded prices. Holdings and manual prices stay. The next refresh downloads again. |
| **Reset database** ⚠️ | Deletes **everything**: holdings, prices and settings. The app returns to Fixture mode. It can't be undone. |
| Network events | The last 20 downloads this session: time, address, result, duration. |

## 10. Troubleshooting

| Problem | What to do |
|---|---|
| Search says the symbol list isn't downloaded | Go back, pull down to refresh, or use Debug → **Re-download EQUITY_L**. In Live mode you need internet. |
| A holding shows "—" for value | It has no price yet. Tap **Download now** on Debug, or set a manual price. |
| Prices didn't change after 7 pm | NSE may not have published yet, or you already downloaded today. Wait, or use **Download now**. |
| "Stocks need a whole number" | Stocks are bought in whole shares. Enter, for example, `10` rather than `10.5`. |
| A holding's "Today's change" shows "—" | It is valued at a manual price, which has no previous close, so it is left out of today's change. |
| I want to start over | Debug → **Reset database**. |
