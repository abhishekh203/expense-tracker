import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Information
  static String get appName => dotenv.env['APP_NAME'] ?? 'Expense Tracker Nepal';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Gemini AI Configuration
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Currency
  static const String defaultCurrency = 'NPR';
  static const String currencySymbol = 'रू ';
  
  // Default Categories for Nepali Users
  static const List<Map<String, dynamic>> defaultCategories = [
    // Expense Categories
    {
      'name': 'Food & Dining',
      'name_nepali': 'खाना र भोजन',
      'icon': '🍽️',
      'color': '#ef4444',
      'type': 'expense'
    },
    {
      'name': 'Transportation',
      'name_nepali': 'यातायात',
      'icon': '🚗',
      'color': '#3b82f6',
      'type': 'expense'
    },
    {
      'name': 'Shopping',
      'name_nepali': 'किनमेल',
      'icon': '🛍️',
      'color': '#8b5cf6',
      'type': 'expense'
    },
    {
      'name': 'Bills & Utilities',
      'name_nepali': 'बिल र उपयोगिता',
      'icon': '💡',
      'color': '#f59e0b',
      'type': 'expense'
    },
    {
      'name': 'Healthcare',
      'name_nepali': 'स्वास्थ्य सेवा',
      'icon': '🏥',
      'color': '#10b981',
      'type': 'expense'
    },
    {
      'name': 'Education',
      'name_nepali': 'शिक्षा',
      'icon': '📚',
      'color': '#6366f1',
      'type': 'expense'
    },
    {
      'name': 'Entertainment',
      'name_nepali': 'मनोरञ्जन',
      'icon': '🎬',
      'color': '#ec4899',
      'type': 'expense'
    },
    {
      'name': 'Groceries',
      'name_nepali': 'किराना',
      'icon': '🛒',
      'color': '#84cc16',
      'type': 'expense'
    },
    {
      'name': 'Fuel',
      'name_nepali': 'इन्धन',
      'icon': '⛽',
      'color': '#f97316',
      'type': 'expense'
    },
    {
      'name': 'Mobile & Internet',
      'name_nepali': 'मोबाइल र इन्टरनेट',
      'icon': '📱',
      'color': '#06b6d4',
      'type': 'expense'
    },
    {
      'name': 'Rent',
      'name_nepali': 'भाडा',
      'icon': '🏠',
      'color': '#8b5a2b',
      'type': 'expense'
    },
    {
      'name': 'Insurance',
      'name_nepali': 'बीमा',
      'icon': '🛡️',
      'color': '#7c3aed',
      'type': 'expense'
    },
    {
      'name': 'Personal Care',
      'name_nepali': 'व्यक्तिगत देखभाल',
      'icon': '💄',
      'color': '#e11d48',
      'type': 'expense'
    },
    {
      'name': 'Gifts & Donations',
      'name_nepali': 'उपहार र दान',
      'icon': '🎁',
      'color': '#dc2626',
      'type': 'expense'
    },
    {
      'name': 'Travel',
      'name_nepali': 'यात्रा',
      'icon': '✈️',
      'color': '#2563eb',
      'type': 'expense'
    },
    {
      'name': 'Miscellaneous',
      'name_nepali': 'विविध',
      'icon': '📦',
      'color': '#6b7280',
      'type': 'expense'
    },
    // Income Categories
    {
      'name': 'Salary',
      'name_nepali': 'तलब',
      'icon': '💰',
      'color': '#059669',
      'type': 'income'
    },
    {
      'name': 'Business',
      'name_nepali': 'व्यापार',
      'icon': '💼',
      'color': '#0891b2',
      'type': 'income'
    },
    {
      'name': 'Freelance',
      'name_nepali': 'फ्रिलान्स',
      'icon': '💻',
      'color': '#7c2d12',
      'type': 'income'
    },
    {
      'name': 'Investment',
      'name_nepali': 'लगानी',
      'icon': '📈',
      'color': '#166534',
      'type': 'income'
    },
    {
      'name': 'Gift Received',
      'name_nepali': 'प्राप्त उपहार',
      'icon': '🎉',
      'color': '#be185d',
      'type': 'income'
    },
    {
      'name': 'Refund',
      'name_nepali': 'फिर्ता',
      'icon': '↩️',
      'color': '#65a30d',
      'type': 'income'
    },
    {
      'name': 'Other Income',
      'name_nepali': 'अन्य आय',
      'icon': '💵',
      'color': '#059669',
      'type': 'income'
    },
  ];
  
  // Default Account Types
  static const List<Map<String, dynamic>> defaultAccountTypes = [
    {
      'name': 'Cash',
      'name_nepali': 'नगद',
      'icon': '💵',
      'type': 'cash'
    },
    {
      'name': 'Bank Account',
      'name_nepali': 'बैंक खाता',
      'icon': '🏦',
      'type': 'bank'
    },
    {
      'name': 'Credit Card',
      'name_nepali': 'क्रेडिट कार्ड',
      'icon': '💳',
      'type': 'credit_card'
    },
    {
      'name': 'Digital Wallet',
      'name_nepali': 'डिजिटल वालेट',
      'icon': '📱',
      'type': 'digital_wallet'
    },
  ];

  // Default Accounts for New Users
  static const List<Map<String, dynamic>> defaultAccounts = [
    {
      'name': 'Cash',
      'type': 'cash',
      'balance': 0.0,
    },
    {
      'name': 'Bank Account',
      'type': 'bank',
      'balance': 0.0,
    },
    {
      'name': 'eSewa',
      'type': 'digital_wallet',
      'balance': 0.0,
    },
    {
      'name': 'Khalti',
      'type': 'digital_wallet',
      'balance': 0.0,
    },
  ];
  
  // Popular Nepali Banks
  static const List<String> nepaliBanks = [
    'Nepal Rastra Bank',
    'Nepal Investment Bank',
    'Standard Chartered Bank Nepal',
    'Himalayan Bank',
    'Nepal SBI Bank',
    'Everest Bank',
    'Bank of Kathmandu',
    'Nepal Bangladesh Bank',
    'NABIL Bank',
    'Nepal Credit and Commerce Bank',
    'Laxmi Bank',
    'Citizens Bank International',
    'Prime Commercial Bank',
    'Sunrise Bank',
    'Century Commercial Bank',
    'Sanima Bank',
    'Machhapuchchhre Bank',
    'Kumari Bank',
    'Rastriya Banijya Bank',
    'Agricultural Development Bank',
  ];
  
  // Popular Digital Wallets in Nepal
  static const List<String> digitalWallets = [
    'eSewa',
    'Khalti',
    'IME Pay',
    'ConnectIPS',
    'Prabhu Pay',
    'SmartChoice Pay',
    'CellPay',
    'QPay',
  ];
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  
  // Shared Preferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keySelectedLanguage = 'selected_language';
  static const String keySelectedCurrency = 'selected_currency';
  static const String keyIsFirstTime = 'is_first_time';
  
  // Storage Buckets
  static const String receiptsBucket = 'receipts';
  static const String avatarsBucket = 'avatars';
  
  // Validation
  static const int maxDescriptionLength = 200;
  static const int maxNotesLength = 500;
  static const double maxTransactionAmount = 999999999.99;
  static const double minTransactionAmount = 0.01;
}
