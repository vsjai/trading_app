import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/formatters/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats paise to INR currency format accurately', () {
      expect(CurrencyFormatter.formatPaise(295050), '₹2,950.50');
      expect(CurrencyFormatter.formatPaise(10000), '₹100.00');
      expect(CurrencyFormatter.formatPaise(0), '₹0.00');
      expect(CurrencyFormatter.formatPaise(75), '₹0.75');
    });

    test('formats signed paise for P&L correctly', () {
      expect(CurrencyFormatter.formatSignedPaise(1250), '+₹12.50');
      expect(CurrencyFormatter.formatSignedPaise(-820), '-₹8.20');
      expect(CurrencyFormatter.formatSignedPaise(0), '₹0.00');
    });

    test('formats percentages with signs', () {
      expect(CurrencyFormatter.formatPercentage(1.45), '+1.45%');
      expect(CurrencyFormatter.formatPercentage(-0.80), '-0.80%');
      expect(CurrencyFormatter.formatPercentage(0.0), '0.00%');
    });

    test('converts rupees to paise without floating point drift', () {
      expect(CurrencyFormatter.rupeesToPaise(2950.50), 295050);
      expect(CurrencyFormatter.rupeesToPaise(10.05), 1005);
      expect(CurrencyFormatter.rupeesToPaise(0.10), 10);
    });

    test('converts paise to rupees correctly', () {
      expect(CurrencyFormatter.paiseToRupees(295050), 2950.50);
      expect(CurrencyFormatter.paiseToRupees(1005), 10.05);
    });
  });
}
