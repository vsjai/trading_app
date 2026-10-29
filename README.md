# 021 Trading App — Flutter Assessment

A demo Flutter trading app featuring mock real-time market data, multi-watchlist management with drag-to-reorder, simulated Buy/Sell market orders with integer-paise precision, and a live portfolio screen with real-time unrealized P&L aggregation and dynamic sorting.

Zero backend setup or API keys required — runs completely standalone out of the box with `flutter pub get && flutter run`.

---

## Features

### 1. Multi-Watchlist Management
- **Multiple Watchlists**: Create custom watchlists, rename them, and delete existing ones while preserving at least one active list.
- **Stock Picker**: Add any of the 10 canonical stocks (`RELIANCE`, `TCS`, `INFY`, `HDFCBANK`, `ICICIBANK`, `SBIN`, `ITC`, `LT`, `BHARTIARTL`, `AXISBANK`).
- **Drag-to-Reorder**: Reorder stocks seamlessly within any watchlist using `ReorderableListView` backed by stable keys.
- **Stock Removal**: Delete stocks with immediate UI update and persistence.
- **Cross-Watchlist Consistency**: Stocks appearing in multiple watchlists simultaneously receive identical live prices from the shared market data stream.
- **Persistence Across Restarts**: Watchlists, their custom names, and exact stock orderings persist across cold app restarts via `shared_preferences`.
- **Direct Trade Navigation**: Tapping any watchlist row opens the Buy/Sell ticket pre-filled with that stock.

### 2. Live Market Overview & Real-Time Engine
- **Centralized Mock Feed**: Single source of truth (`MarketFeedService`) broadcasting live quotes across the entire app.
- **Configurable Tick Rate Modes**:
  - **Normal**: ~0.2 ticks/sec/stock (~2 ticks/sec overall).
  - **Active**: ~1.0 ticks/sec/stock (~10 ticks/sec overall).
  - **Stress**: ~5.5 ticks/sec/stock (~55+ ticks/sec overall).
- **Subtree Price Flash Badges**: Ticking prices flash green on upward movement and red on downward movement, holding the color for 1.5 seconds before smoothly reverting to normal text color.
- **Zero-Jank Reactivity**: Granular Riverpod family providers ensure only the ticking stock's leaf widget rebuilds, preventing full list or screen rebuilds during rapid price updates.
- **Continuous Background Ingestion**: Market feed ticks continue updating central memory when navigating across tabs; returning to any screen immediately displays up-to-date quotes without staleness.

### 3. Simulated Buy/Sell Order Ticket
- **Pre-Selected Stock**: Automatically populated when opened from Watchlists or Holdings.
- **Live LTP & Projected Cost**: Displays current LTP and calculates projected order value (`Quantity × LTP`) in real time as the user types.
- **Integer Paise Precision**: All monetary calculations use `int` paise to eliminate IEEE-754 floating-point drift.
- **Strict Pre-Execution Validation**:
  - Rejects zero, negative, fractional, and non-numeric quantities.
  - Blocks Buy orders when total cost exceeds available wallet balance with inline margin errors.
  - Blocks Sell orders when quantity exceeds shares currently held.
- **Atomic State Mutations**: Deducts purchase cost from wallet, updates existing holdings using quantity-weighted average cost, or liquidates positions when quantity drops to zero.
- **Order History & Receipts**: Displays confirmation receipt upon order execution and logs order history to persistent storage.

### 4. Holdings & Portfolio Overview
- **Position Tracking**: Displays symbol, shares held, weighted average cost, live LTP, current market value, unrealized P&L in rupees, and P&L percentage.
- **Live Aggregate Summary Card**: Real-time totals for Invested Amount, Current Market Value, Total P&L (₹ and %), and Available Cash.
- **Exact Mathematical Parity**: Aggregate totals are computed using the identical integer-paise formulas as individual rows, guaranteeing consistent row sums.
- **Dynamic Re-Ranking & Sorting**:
  - Sort by **P&L** (default descending), **Symbol**, or **Current Value**.
  - Ranks update automatically in real time as price movements cross thresholds.
- **Tap to Trade**: Tapping any holding row opens the Buy/Sell ticket with that stock preselected.
- **Empty State**: Displays an informative empty state with a direct "Explore Market" call to action when no positions are held.
- **Cold Restart Persistence**: Preserves portfolio holdings across app restarts.

---

## Tech Stack & Architecture

- **Framework**: Flutter (Stable channel)
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod: ^2.6.1`)
- **Persistence**: `shared_preferences: ^2.5.2` (production) & `InMemoryStorageService` (testing)
- **Formatting**: `intl: ^0.20.2` with custom `CurrencyFormatter` for Indian Rupee notation (Lakhs/Crores grouping)
- **Clean Architecture Layers**:
  ```
  lib/
  ├── core/               # Theme, constants, formatters (CurrencyFormatter)
  ├── models/             # Immutable data models (Stock, StockQuote, Holding, StockOrder, Watchlist)
  ├── services/           # MarketFeedService (single source of truth), StorageService abstractions
  ├── state/              # Riverpod StateNotifiers & StreamProviders
  ├── ui/                 # Screens & leaf widgets
  │   ├── common/         # PriceFlashBadge, shared UI components
  │   ├── holdings/       # HoldingsScreen, PortfolioSummaryCard, HoldingRowTile
  │   ├── market/         # MarketOverviewScreen, LiveStockTile, TickRateControlSheet
  │   ├── navigation/     # MainNavigationScaffold
  │   ├── trade/          # BuySellTicketSheet, OrderConfirmationDialog
  │   └── watchlist/      # WatchlistsScreen, WatchlistStockRow, StockPickerSheet
  └── main.dart           # App bootstrap with storage initialization
  ```

---

## Monetary Precision & Order Execution

Floating-point representations (`double`) can introduce subtle penny/paise drift (e.g. `0.1 + 0.2 = 0.30000000000000004`). In this app:
1. **Integer Representation**: All monetary values (`ltpPaise`, `avgCostPaise`, `walletBalancePaise`, `totalCostPaise`, `orderPricePaise`) are stored as `int` representing paise ($\frac{1}{100}$ of a rupee).
2. **Weighted Average Cost Formula**:
   $$\text{NewAvgCost} = \frac{\text{PreviousTotalCost} + (\text{BuyQty} \times \text{LTP})}{\text{PreviousQty} + \text{BuyQty}}$$
3. **Partial Sells**: When partially selling, the holding's average cost basis remains intact while the quantity and total cost decrease proportionally.
4. **Liquidation**: When a position's quantity reaches zero, the holding is completely removed from state and storage.

---

## Mock Market-Data Feed Design

- The 10 canonical stocks are initialized with representative base prices:
  `RELIANCE` (₹2,950.50), `TCS` (₹3,845.00), `INFY` (₹1,520.25), `HDFCBANK` (₹1,430.75), `ICICIBANK` (₹1,090.00), `SBIN` (₹785.40), `ITC` (₹435.60), `LT` (₹3,560.00), `BHARTIARTL` (₹1,280.50), `AXISBANK` (₹1,145.00).
- Price updates follow a bounded random walk with a mean-reverting damper ($\pm 8\%$ threshold) to keep simulated movements realistic.
- Users can switch between **Normal**, **Active**, and **Stress (55 ticks/sec)** modes on demand via the header badge in the Live Market tab.

---

## Getting Started

### Prerequisites
- Flutter SDK $\ge 3.11.4$ / Dart SDK $\ge 3.0$
- macOS, Linux, or Windows with an emulator or physical device

### Installation & Run
```bash
# 1. Clone the repository
git clone https://github.com/vsjai/trading_app.git
cd trading_app

# 2. Fetch dependencies
flutter pub get

# 3. Run the application (no backend or configuration required)
flutter run
```

### Useful Flutter Resources
- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
- [Flutter documentation](https://docs.flutter.dev/)

---

## Test Suite & Verification Results

The project includes unit, widget, and integration test suites covering calculations, persistence, UI rendering, stress feed throughput, and all 12 evaluation scenarios.

### Run Tests
```bash
# Run code analysis
flutter analyze

# Run all unit, widget, and integration tests
flutter test test/unit/ test/widget/ test/integration/ test/widget_test.dart

# Check formatting
dart format --output=none --set-exit-if-changed lib test
```

### Verified Test Results
- **86 of 86 tests passing (100% pass rate)**:
  - `test/unit/` (44 tests): Domain serialization, currency formatting without drift, weighted average cost, storage adapters, watchlist reordering, market feed distribution.
  - `test/widget/` (26 tests): Market overview rendering, price flashes, watchlist tabs, stock picker modal, buy/sell ticket validations, order confirmation receipts, portfolio summary card, smooth scrolling.
  - `test/integration/` (16 tests): Cold restart restoration, cross-watchlist price parity, live price continuity across tab navigation, margin validation, 55+ ticks/sec stress benchmark, and granular stream rebuild isolation.
- **Static Analysis**: 0 warnings, 0 errors (`flutter analyze`).
- **Code Cleanliness**: 0 comments in `lib/` in adherence to user directives.

---

## Assumptions & Known Limitations

1. **Market Orders Only**: Orders execute immediately at the latest sampled LTP upon submission. Limit orders, stop-losses, and order-book depth are not part of this simulation.
2. **Local Persistence**: App state is persisted locally using `shared_preferences` without cloud synchronization.
3. **Simulated Starting Balance**: The app initializes with a default paper wallet balance of ₹5,00,000.00.

---

## Walkthrough Video Recording Checklist

When preparing the Loom or screen recording submission, cover the following steps:

1. **Watchlists**:
   - [ ] Show the default watchlists ("Nifty 50" and "Tech Giants").
   - [ ] Create a new custom watchlist and rename it.
   - [ ] Open the Stock Picker and add a stock.
   - [ ] Drag to reorder stocks in the list.
   - [ ] Delete a stock from the watchlist.
2. **Live Prices**:
   - [ ] Navigate to the "Live Market" tab.
   - [ ] Observe live price movements and green/red flash badges.
   - [ ] Tap the tick rate badge and switch to **Stress Mode (55/s)**.
   - [ ] Scroll through all 10 stocks demonstrating smooth scrolling without frame drops.
3. **Buy/Sell Ticket**:
   - [ ] Tap a stock in Watchlist or Market to open the Buy/Sell ticket with that stock pre-filled.
   - [ ] Enter a quantity and demonstrate live projected order value updates as LTP changes.
   - [ ] Try entering an invalid quantity (0 or negative) and excessive quantity to show inline margin errors.
   - [ ] Execute a valid BUY order and show the Order Confirmation dialog.
4. **Holdings & Portfolio**:
   - [ ] Navigate to the "Holdings" tab to see the newly bought position.
   - [ ] Point out the aggregate summary card (Invested, Current Value, Total P&L).
   - [ ] Switch sorting criteria (P&L, Symbol, Current Value).
   - [ ] Tap the holding to open the Sell ticket and execute a partial sell, then a full liquidation.
5. **App Restart Persistence**:
   - [ ] Fully terminate/restart the app.
   - [ ] Show that custom watchlists, modified stock order, updated wallet balance, and order history are completely restored.
