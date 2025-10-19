import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class DateHelpers {
  static final DateFormat _dateFormatter = DateFormat(AppConstants.dateFormat);
  static final DateFormat _displayDateFormatter = DateFormat(AppConstants.displayDateFormat);
  static final DateFormat _timeFormatter = DateFormat(AppConstants.timeFormat);
  
  /// Format date for database storage (yyyy-MM-dd)
  static String formatForDatabase(DateTime date) {
    return _dateFormatter.format(date);
  }
  
  /// Format date for display (MMM dd, yyyy)
  static String formatForDisplay(DateTime date) {
    return _displayDateFormatter.format(date);
  }
  
  /// Format time for display (HH:mm)
  static String formatTime(DateTime dateTime) {
    return _timeFormatter.format(dateTime);
  }
  
  /// Format date and time for display
  static String formatDateTime(DateTime dateTime) {
    return '${formatForDisplay(dateTime)} ${formatTime(dateTime)}';
  }
  
  /// Parse date string from database
  static DateTime? parseFromDatabase(String dateString) {
    try {
      return _dateFormatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Get relative date string (Today, Yesterday, etc.)
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date); // Day name
    } else if (dateOnly.year == today.year) {
      return DateFormat('MMM dd').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
  
  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }
  
  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysToSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysToSunday)));
  }
  
  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = date.month == 12 
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1));
  }
  
  /// Get start of year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }
  
  /// Get end of year
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }
  
  /// Get date range for a specific period
  static DateRange getDateRange(DateRangeType type, [DateTime? referenceDate]) {
    final date = referenceDate ?? DateTime.now();
    
    switch (type) {
      case DateRangeType.today:
        return DateRange(startOfDay(date), endOfDay(date));
      case DateRangeType.yesterday:
        final yesterday = date.subtract(const Duration(days: 1));
        return DateRange(startOfDay(yesterday), endOfDay(yesterday));
      case DateRangeType.thisWeek:
        return DateRange(startOfWeek(date), endOfWeek(date));
      case DateRangeType.lastWeek:
        final lastWeek = date.subtract(const Duration(days: 7));
        return DateRange(startOfWeek(lastWeek), endOfWeek(lastWeek));
      case DateRangeType.thisMonth:
        return DateRange(startOfMonth(date), endOfMonth(date));
      case DateRangeType.lastMonth:
        final lastMonth = DateTime(date.year, date.month - 1, date.day);
        return DateRange(startOfMonth(lastMonth), endOfMonth(lastMonth));
      case DateRangeType.thisYear:
        return DateRange(startOfYear(date), endOfYear(date));
      case DateRangeType.lastYear:
        final lastYear = DateTime(date.year - 1, date.month, date.day);
        return DateRange(startOfYear(lastYear), endOfYear(lastYear));
      case DateRangeType.last7Days:
        return DateRange(
          startOfDay(date.subtract(const Duration(days: 6))),
          endOfDay(date)
        );
      case DateRangeType.last30Days:
        return DateRange(
          startOfDay(date.subtract(const Duration(days: 29))),
          endOfDay(date)
        );
    }
  }
  
  /// Check if date is in range
  static bool isDateInRange(DateTime date, DateRange range) {
    return date.isAfter(range.start.subtract(const Duration(milliseconds: 1))) &&
           date.isBefore(range.end.add(const Duration(milliseconds: 1)));
  }
  
  /// Get month name in Nepali
  static String getMonthNameNepali(int month) {
    const monthNames = [
      'जनवरी', 'फेब्रुअरी', 'मार्च', 'अप्रिल', 'मे', 'जुन',
      'जुलाई', 'अगस्त', 'सेप्टेम्बर', 'अक्टोबर', 'नोभेम्बर', 'डिसेम्बर'
    ];
    return monthNames[month - 1];
  }
  
  /// Get day name in Nepali
  static String getDayNameNepali(int weekday) {
    const dayNames = [
      'सोमबार', 'मंगलबार', 'बुधबार', 'बिहिबार', 'शुक्रबार', 'शनिबार', 'आइतबार'
    ];
    return dayNames[weekday - 1];
  }
}

enum DateRangeType {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisYear,
  lastYear,
  last7Days,
  last30Days,
}

class DateRange {
  final DateTime start;
  final DateTime end;
  
  DateRange(this.start, this.end);
  
  bool contains(DateTime date) {
    return DateHelpers.isDateInRange(date, this);
  }
  
  Duration get duration => end.difference(start);
  
  int get days => duration.inDays + 1;
  
  @override
  String toString() {
    return 'DateRange(${DateHelpers.formatForDisplay(start)} - ${DateHelpers.formatForDisplay(end)})';
  }
}
