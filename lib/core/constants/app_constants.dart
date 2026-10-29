import '../../models/stock.dart';

class AppConstants {
  AppConstants._();

  static const int defaultWalletBalancePaise = 50000000;

  static const List<Stock> initialStocks = [
    Stock(
      symbol: 'RELIANCE',
      name: 'Reliance Industries Ltd',
      sector: 'Energy & Petrochemicals',
      basePricePaise: 295050,
      previousClosePaise: 293500,
    ),
    Stock(
      symbol: 'TCS',
      name: 'Tata Consultancy Services Ltd',
      sector: 'Information Technology',
      basePricePaise: 384500,
      previousClosePaise: 386000,
    ),
    Stock(
      symbol: 'INFY',
      name: 'Infosys Ltd',
      sector: 'Information Technology',
      basePricePaise: 152025,
      previousClosePaise: 151000,
    ),
    Stock(
      symbol: 'HDFCBANK',
      name: 'HDFC Bank Ltd',
      sector: 'Banking & Financials',
      basePricePaise: 168000,
      previousClosePaise: 167250,
    ),
    Stock(
      symbol: 'ICICIBANK',
      name: 'ICICI Bank Ltd',
      sector: 'Banking & Financials',
      basePricePaise: 112575,
      previousClosePaise: 111800,
    ),
    Stock(
      symbol: 'SBIN',
      name: 'State Bank of India',
      sector: 'Public Sector Banking',
      basePricePaise: 78550,
      previousClosePaise: 79200,
    ),
    Stock(
      symbol: 'ITC',
      name: 'ITC Ltd',
      sector: 'FMCG & Diversified',
      basePricePaise: 43525,
      previousClosePaise: 43200,
    ),
    Stock(
      symbol: 'LT',
      name: 'Larsen & Toubro Ltd',
      sector: 'Infrastructure & Engineering',
      basePricePaise: 356000,
      previousClosePaise: 354000,
    ),
    Stock(
      symbol: 'BHARTIARTL',
      name: 'Bharti Airtel Ltd',
      sector: 'Telecommunications',
      basePricePaise: 134080,
      previousClosePaise: 133500,
    ),
    Stock(
      symbol: 'AXISBANK',
      name: 'Axis Bank Ltd',
      sector: 'Banking & Financials',
      basePricePaise: 119040,
      previousClosePaise: 120500,
    ),
  ];

  static final Set<String> supportedSymbols = initialStocks
      .map((s) => s.symbol)
      .toSet();

  static const String defaultWatchlistId = 'wl_core';
  static const String defaultWatchlistName = 'Nifty Top 10';
  static const List<String> defaultWatchlistSymbols = [
    'RELIANCE',
    'TCS',
    'INFY',
    'HDFCBANK',
    'ICICIBANK',
  ];

  static const String secondaryWatchlistId = 'wl_secondary';
  static const String secondaryWatchlistName = 'Banking & Infra';
  static const List<String> secondaryWatchlistSymbols = [
    'HDFCBANK',
    'ICICIBANK',
    'SBIN',
    'LT',
    'AXISBANK',
  ];
}
