enum AccountType {
  cash,
  bank,
  creditCard,
  digitalWallet;

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.digitalWallet:
        return 'Digital Wallet';
    }
  }

  String get displayNameNepali {
    switch (this) {
      case AccountType.cash:
        return 'नगद';
      case AccountType.bank:
        return 'बैंक खाता';
      case AccountType.creditCard:
        return 'क्रेडिट कार्ड';
      case AccountType.digitalWallet:
        return 'डिजिटल वालेट';
    }
  }

  String get icon {
    switch (this) {
      case AccountType.cash:
        return '💵';
      case AccountType.bank:
        return '🏦';
      case AccountType.creditCard:
        return '💳';
      case AccountType.digitalWallet:
        return '📱';
    }
  }

  static AccountType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return AccountType.cash;
      case 'bank':
        return AccountType.bank;
      case 'credit_card':
        return AccountType.creditCard;
      case 'digital_wallet':
        return AccountType.digitalWallet;
      default:
        return AccountType.cash;
    }
  }

  String toJson() {
    switch (this) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bank:
        return 'bank';
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.digitalWallet:
        return 'digital_wallet';
    }
  }
}

class Account {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final bool isActive;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.currency = 'NPR',
    this.isActive = true,
    required this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: AccountType.fromString(json['type'] as String),
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'NPR',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.toJson(),
      'balance': balance,
      'currency': currency,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Account copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get display name with type
  String get displayNameWithType => '$name (${type.displayName})';

  /// Get display name with type in Nepali
  String get displayNameWithTypeNepali => '$name (${type.displayNameNepali})';

  /// Check if account has sufficient balance for a transaction
  bool hasSufficientBalance(double amount) {
    return balance >= amount;
  }

  /// Get account after adding amount (for income/transfer in)
  Account addAmount(double amount) {
    return copyWith(balance: balance + amount);
  }

  /// Get account after subtracting amount (for expense/transfer out)
  Account subtractAmount(double amount) {
    return copyWith(balance: balance - amount);
  }

  @override
  String toString() {
    return 'Account(id: $id, name: $name, type: $type, balance: $balance, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.type == type &&
        other.balance == balance &&
        other.currency == currency &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        type.hashCode ^
        balance.hashCode ^
        currency.hashCode ^
        isActive.hashCode;
  }
}
