import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static final NumberFormat _nprFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );
  
  static final NumberFormat _compactFormatter = NumberFormat.compact(
    locale: 'en_US',
  );
  
  /// Format amount in Nepali Rupees with proper formatting
  /// Example: formatNPR(1234.56) returns "रू 1,234.56"
  static String formatNPR(double amount) {
    try {
      return _nprFormatter.format(amount);
    } catch (e) {
      // Fallback formatting if locale is not available
      return '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}';
    }
  }
  
  /// Format amount in compact form for display in charts/summaries
  /// Example: formatCompact(1234567) returns "12L" (12 Lakh)
  static String formatCompact(double amount) {
    try {
      return _compactFormatter.format(amount);
    } catch (e) {
      // Fallback for compact formatting
      if (amount >= 10000000) {
        return '${(amount / 10000000).toStringAsFixed(1)}Cr';
      } else if (amount >= 100000) {
        return '${(amount / 100000).toStringAsFixed(1)}L';
      } else if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)}K';
      }
      return amount.toStringAsFixed(0);
    }
  }
  
  /// Parse currency string back to double
  /// Example: parseNPR("रू 1,234.56") returns 1234.56
  static double parseNPR(String currencyString) {
    try {
      // Remove currency symbol and spaces
      String cleanString = currencyString
          .replaceAll(AppConstants.currencySymbol, '')
          .replaceAll(',', '')
          .trim();
      
      return double.parse(cleanString);
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Format amount without currency symbol
  /// Example: formatAmount(1234.56) returns "1,234.56"
  static String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'ne_NP');
    try {
      return formatter.format(amount);
    } catch (e) {
      return amount.toStringAsFixed(2);
    }
  }
  
  /// Check if amount is valid for transactions
  static bool isValidAmount(double amount) {
    return amount >= AppConstants.minTransactionAmount && 
           amount <= AppConstants.maxTransactionAmount;
  }
  
  /// Format percentage
  /// Example: formatPercentage(0.1234) returns "12.34%"
  static String formatPercentage(double percentage) {
    final formatter = NumberFormat.percentPattern('ne_NP');
    try {
      return formatter.format(percentage);
    } catch (e) {
      return '${(percentage * 100).toStringAsFixed(2)}%';
    }
  }
  
  /// Convert amount to words in Nepali context
  /// This is a simplified version - you might want to use a proper number-to-words library
  static String amountToWords(double amount) {
    // This is a placeholder - implement proper number to words conversion
    // You might want to use a library like 'number_to_words' or create custom logic
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)} करोड';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)} लाख';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} हजार';
    }
    return amount.toStringAsFixed(0);
  }
}
