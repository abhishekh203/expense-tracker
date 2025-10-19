import 'category.dart';

enum BudgetPeriod {
  monthly,
  weekly,
  yearly;

  String get displayName {
    switch (this) {
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }

  String get displayNameNepali {
    switch (this) {
      case BudgetPeriod.monthly:
        return 'मासिक';
      case BudgetPeriod.weekly:
        return 'साप्ताहिक';
      case BudgetPeriod.yearly:
        return 'वार्षिक';
    }
  }

  static BudgetPeriod fromString(String period) {
    switch (period.toLowerCase()) {
      case 'monthly':
        return BudgetPeriod.monthly;
      case 'weekly':
        return BudgetPeriod.weekly;
      case 'yearly':
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.monthly;
    }
  }

  String toJson() {
    switch (this) {
      case BudgetPeriod.monthly:
        return 'monthly';
      case BudgetPeriod.weekly:
        return 'weekly';
      case BudgetPeriod.yearly:
        return 'yearly';
    }
  }
}

class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool alertEnabled;
  final double alertThreshold; // Percentage (0.0 to 1.0)
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related objects (populated when needed)
  final Category? category;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.alertEnabled,
    required this.alertThreshold,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: BudgetPeriod.fromString(json['period'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      isActive: json['is_active'] as bool,
      alertEnabled: json['alert_enabled'] as bool,
      alertThreshold: (json['alert_threshold'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['categories'] != null 
          ? Category.fromJson(json['categories'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'period': period.toJson(),
      'start_date': startDate.toIso8601String().split('T')[0], // Date only
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_active': isActive,
      'alert_enabled': alertEnabled,
      'alert_threshold': alertThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? alertEnabled,
    double? alertThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }

  /// Get the current period start date based on budget period
  DateTime getCurrentPeriodStart() {
    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case BudgetPeriod.weekly:
        final weekday = now.weekday;
        return now.subtract(Duration(days: weekday - 1));
      case BudgetPeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  /// Get the current period end date based on budget period
  DateTime getCurrentPeriodEnd() {
    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case BudgetPeriod.weekly:
        final weekday = now.weekday;
        return now.add(Duration(days: 7 - weekday, hours: 23, minutes: 59, seconds: 59));
      case BudgetPeriod.yearly:
        return DateTime(now.year, 12, 31, 23, 59, 59);
    }
  }

  /// Check if budget is currently active for the current period
  bool get isCurrentlyActive {
    if (!isActive) return false;
    
    final now = DateTime.now();
    final periodStart = getCurrentPeriodStart();
    final periodEnd = getCurrentPeriodEnd();
    
    return now.isAfter(periodStart) && now.isBefore(periodEnd);
  }

  /// Get display text for the budget period
  String get periodDisplayText {
    switch (period) {
      case BudgetPeriod.monthly:
        final now = DateTime.now();
        return '${_getMonthName(now.month)} ${now.year}';
      case BudgetPeriod.weekly:
        final start = getCurrentPeriodStart();
        final end = getCurrentPeriodEnd();
        return '${start.day}/${start.month} - ${end.day}/${end.month}';
      case BudgetPeriod.yearly:
        return DateTime.now().year.toString();
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  String toString() {
    return 'Budget(id: $id, categoryId: $categoryId, amount: $amount, period: $period)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.userId == userId &&
        other.categoryId == categoryId &&
        other.amount == amount &&
        other.period == period &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.isActive == isActive &&
        other.alertEnabled == alertEnabled &&
        other.alertThreshold == alertThreshold;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        categoryId.hashCode ^
        amount.hashCode ^
        period.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        isActive.hashCode ^
        alertEnabled.hashCode ^
        alertThreshold.hashCode;
  }
}

/// Helper class for budget analysis
class BudgetUsage {
  final Budget budget;
  final double spent;
  final double remaining;
  final double percentage;
  final bool isOverBudget;
  final bool shouldAlert;

  BudgetUsage({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.isOverBudget,
    required this.shouldAlert,
  });

  factory BudgetUsage.fromBudgetAndSpent(Budget budget, double spent) {
    final remaining = budget.amount - spent;
    final percentage = budget.amount > 0 ? (spent / budget.amount) : 0.0;
    final isOverBudget = spent > budget.amount;
    final shouldAlert = budget.alertEnabled && percentage >= budget.alertThreshold;

    return BudgetUsage(
      budget: budget,
      spent: spent,
      remaining: remaining,
      percentage: percentage,
      isOverBudget: isOverBudget,
      shouldAlert: shouldAlert,
    );
  }

  /// Get status color based on usage
  String get statusColor {
    if (isOverBudget) return '#ef4444'; // Red
    if (percentage >= 0.8) return '#f59e0b'; // Orange
    if (percentage >= 0.6) return '#eab308'; // Yellow
    return '#10b981'; // Green
  }

  /// Get status message
  String get statusMessage {
    if (isOverBudget) return 'Over Budget';
    if (percentage >= 0.9) return 'Almost Exceeded';
    if (percentage >= 0.7) return 'High Usage';
    if (percentage >= 0.5) return 'Moderate Usage';
    return 'On Track';
  }

  @override
  String toString() {
    return 'BudgetUsage(spent: $spent, remaining: $remaining, percentage: ${(percentage * 100).toStringAsFixed(1)}%)';
  }
}
