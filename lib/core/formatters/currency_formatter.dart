import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactInrFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _percentFormat = NumberFormat('0.00', 'en_US');

  static String formatPaise(int paise, {bool includeSymbol = true}) {
    final double rupees = paise / 100.0;
    if (!includeSymbol) {
      return _inrFormat.format(rupees).replaceAll('₹', '').trim();
    }
    return _inrFormat.format(rupees);
  }

  static String formatSignedPaise(int paise, {bool includeSymbol = true}) {
    final String formatted = formatPaise(
      paise.abs(),
      includeSymbol: includeSymbol,
    );
    if (paise > 0) {
      return '+$formatted';
    } else if (paise < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  static String formatPercentage(double percent, {bool includeSign = true}) {
    final String value = '${_percentFormat.format(percent.abs())}%';
    if (!includeSign) return value;
    if (percent > 0) return '+$value';
    if (percent < 0) return '-$value';
    return value;
  }

  static String formatCompactPaise(int paise) {
    return _compactInrFormat.format(paise / 100.0);
  }

  static int rupeesToPaise(double rupees) {
    return (rupees * 100).round();
  }

  static double paiseToRupees(int paise) {
    return paise / 100.0;
  }
}
