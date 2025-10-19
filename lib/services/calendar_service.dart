import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:intl/intl.dart';

enum CalendarType {
  english,
  nepali,
}

class CalendarService {
  static CalendarType _currentCalendar = CalendarType.english;
  
  /// Get current calendar type
  static CalendarType get currentCalendar => _currentCalendar;
  
  /// Set calendar type
  static void setCalendarType(CalendarType type) {
    _currentCalendar = type;
  }
  
  /// Toggle between English and Nepali calendar
  static void toggleCalendar() {
    _currentCalendar = _currentCalendar == CalendarType.english 
        ? CalendarType.nepali 
        : CalendarType.english;
  }
  
  /// Get current date in the selected calendar format
  static String getCurrentDateString() {
    if (_currentCalendar == CalendarType.nepali) {
      final nepaliDate = NepaliDateTime.now();
      return NepaliDateFormat('yyyy-MM-dd').format(nepaliDate);
    } else {
      final englishDate = DateTime.now();
      return DateFormat('yyyy-MM-dd').format(englishDate);
    }
  }
  
  /// Get current date as DateTime object
  static DateTime getCurrentDate() {
    if (_currentCalendar == CalendarType.nepali) {
      final nepaliDate = NepaliDateTime.now();
      return nepaliDate.toDateTime();
    } else {
      return DateTime.now();
    }
  }
  
  /// Format date for display
  static String formatDateForDisplay(DateTime date) {
    if (_currentCalendar == CalendarType.nepali) {
      final nepaliDate = date.toNepaliDateTime();
      return NepaliDateFormat('yyyy-MM-dd').format(nepaliDate);
    } else {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }
  
  /// Format date with month name
  static String formatDateWithMonth(DateTime date) {
    if (_currentCalendar == CalendarType.nepali) {
      final nepaliDate = date.toNepaliDateTime();
      return NepaliDateFormat('MMMM dd, yyyy').format(nepaliDate);
    } else {
      return DateFormat('MMMM dd, yyyy').format(date);
    }
  }
  
  /// Format date for short display
  static String formatDateShort(DateTime date) {
    if (_currentCalendar == CalendarType.nepali) {
      final nepaliDate = date.toNepaliDateTime();
      return NepaliDateFormat('MMM dd').format(nepaliDate);
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
  
  /// Get calendar type display name
  static String getCalendarTypeName() {
    return _currentCalendar == CalendarType.nepali ? 'नेपाली' : 'English';
  }
  
  /// Get calendar type display name in English
  static String getCalendarTypeNameEnglish() {
    return _currentCalendar == CalendarType.nepali ? 'Nepali' : 'English';
  }
  
  /// Convert DateTime to NepaliDateTime
  static NepaliDateTime toNepaliDate(DateTime date) {
    return date.toNepaliDateTime();
  }
  
  /// Convert NepaliDateTime to DateTime
  static DateTime toEnglishDate(NepaliDateTime nepaliDate) {
    return nepaliDate.toDateTime();
  }
  
  /// Get month names in current calendar
  static List<String> getMonthNames() {
    if (_currentCalendar == CalendarType.nepali) {
      return [
        'बैशाख', 'जेष्ठ', 'आषाढ', 'श्रावण', 'भाद्र', 'आश्विन',
        'कार्तिक', 'मंसिर', 'पौष', 'माघ', 'फाल्गुन', 'चैत्र'
      ];
    } else {
      return [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
    }
  }
  
  /// Get day names in current calendar
  static List<String> getDayNames() {
    if (_currentCalendar == CalendarType.nepali) {
      return ['आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहिबार', 'शुक्रबार', 'शनिबार'];
    } else {
      return ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    }
  }
  
  /// Get short day names in current calendar
  static List<String> getShortDayNames() {
    if (_currentCalendar == CalendarType.nepali) {
      return ['आइत', 'सोम', 'मंगल', 'बुध', 'बिहि', 'शुक्र', 'शनि'];
    } else {
      return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    }
  }
}
