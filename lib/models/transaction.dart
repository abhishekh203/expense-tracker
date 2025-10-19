import 'category.dart';
import 'account.dart';

enum TransactionType {
  expense,
  income,
  transfer;

  String get displayName {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  String get displayNameNepali {
    switch (this) {
      case TransactionType.expense:
        return 'खर्च';
      case TransactionType.income:
        return 'आम्दानी';
      case TransactionType.transfer:
        return 'स्थानान्तरण';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.expense:
        return '💸';
      case TransactionType.income:
        return '💰';
      case TransactionType.transfer:
        return '🔄';
    }
  }

  static TransactionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'expense':
        return TransactionType.expense;
      case 'income':
        return TransactionType.income;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  String toJson() {
    switch (this) {
      case TransactionType.expense:
        return 'expense';
      case TransactionType.income:
        return 'income';
      case TransactionType.transfer:
        return 'transfer';
    }
  }
}

class Transaction {
  final String id;
  final String userId;
  final String accountId;
  final String? categoryId;
  final double amount;
  final TransactionType type;
  final String? description;
  final String? notes;
  final String? receiptUrl;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related objects (populated when needed)
  final Category? category;
  final Account? account;

  Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    this.notes,
    this.receiptUrl,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.account,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.fromString(json['type'] as String),
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['categories'] != null 
          ? Category.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
      account: json['accounts'] != null
          ? Account.fromJson(json['accounts'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'type': type.toJson(),
      'description': description,
      'notes': notes,
      'receipt_url': receiptUrl,
      'transaction_date': transactionDate.toIso8601String().split('T')[0], // Date only
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? categoryId,
    double? amount,
    TransactionType? type,
    String? description,
    String? notes,
    String? receiptUrl,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
    Account? account,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      account: account ?? this.account,
    );
  }

  /// Get display title for the transaction
  String get displayTitle {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }
    if (category != null) {
      return category!.name;
    }
    return type.displayName;
  }

  /// Get display subtitle for the transaction
  String get displaySubtitle {
    final parts = <String>[];
    
    if (account != null) {
      parts.add(account!.name);
    }
    
    if (category != null && description != null && description!.isNotEmpty) {
      parts.add(category!.name);
    }
    
    return parts.join(' • ');
  }

  /// Check if transaction has receipt
  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  /// Get signed amount (negative for expenses, positive for income)
  double get signedAmount {
    switch (type) {
      case TransactionType.expense:
        return -amount;
      case TransactionType.income:
        return amount;
      case TransactionType.transfer:
        return amount; // Context dependent
    }
  }

  /// Check if transaction is recent (within last 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  /// Check if transaction is today
  bool get isToday {
    final now = DateTime.now();
    return transactionDate.year == now.year &&
           transactionDate.month == now.month &&
           transactionDate.day == now.day;
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, type: $type, description: $description, date: $transactionDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.userId == userId &&
        other.accountId == accountId &&
        other.categoryId == categoryId &&
        other.amount == amount &&
        other.type == type &&
        other.description == description &&
        other.notes == notes &&
        other.receiptUrl == receiptUrl &&
        other.transactionDate == transactionDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        accountId.hashCode ^
        categoryId.hashCode ^
        amount.hashCode ^
        type.hashCode ^
        description.hashCode ^
        notes.hashCode ^
        receiptUrl.hashCode ^
        transactionDate.hashCode;
  }
}

/// Helper class for transaction summaries
class TransactionSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;

  TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
  });

  factory TransactionSummary.fromTransactions(List<Transaction> transactions) {
    double income = 0;
    double expense = 0;
    
    for (final transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          income += transaction.amount;
          break;
        case TransactionType.expense:
          expense += transaction.amount;
          break;
        case TransactionType.transfer:
          // Transfers don't affect overall balance in summary
          break;
      }
    }
    
    return TransactionSummary(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      transactionCount: transactions.length,
    );
  }

  @override
  String toString() {
    return 'TransactionSummary(income: $totalIncome, expense: $totalExpense, balance: $balance, count: $transactionCount)';
  }
}
