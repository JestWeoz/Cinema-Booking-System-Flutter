import 'package:intl/intl.dart';

class CurrencyUtils {
  CurrencyUtils._();

  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  static String formatVND(num amount) => _vndFormat.format(amount);
  static String formatUSD(num amount) => _usdFormat.format(amount);

  static String formatPrice(num amount, {String currency = 'VND'}) {
    return currency == 'USD' ? formatUSD(amount) : formatVND(amount);
  }
}
