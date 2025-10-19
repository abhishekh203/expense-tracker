class Lending {
  final String id;
  final String userId;
  final String personName;
  final String? personContact;
  final double amount;
  final double amountPaid;
  final LendingType type;
  final LendingStatus status;
  final String? accountId;
  final DateTime lendingDate;
  final DateTime? dueDate;
  final double? interestRate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lending({
    required this.id,
    required this.userId,
    required this.personName,
    this.personContact,
    required this.amount,
    this.amountPaid = 0.0,
    required this.type,
    this.status = LendingStatus.active,
    this.accountId,
    required this.lendingDate,
    this.dueDate,
    this.interestRate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters for calculated fields
  double get remainingAmount => amount - amountPaid;
  bool get isFullyPaid => remainingAmount <= 0;
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && !isFullyPaid;
  }
  
  double get totalWithInterest {
    if (interestRate == null || interestRate == 0) return amount;
    return amount + (amount * interestRate! / 100);
  }

  factory Lending.fromJson(Map<String, dynamic> json) {
    return Lending(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      personName: json['person_name'] as String,
      personContact: json['person_contact'] as String?,
      amount: (json['amount'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      type: LendingType.fromString(json['type'] as String),
      status: LendingStatus.fromString(json['status'] as String),
      accountId: json['account_id'] as String?,
      lendingDate: DateTime.parse(json['lending_date'] as String),
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String) 
          : null,
      interestRate: json['interest_rate'] != null 
          ? (json['interest_rate'] as num).toDouble() 
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'person_name': personName,
      'person_contact': personContact,
      'amount': amount,
      'amount_paid': amountPaid,
      'type': type.toJson(),
      'status': status.toJson(),
      'account_id': accountId,
      'lending_date': lendingDate.toIso8601String().split('T')[0], // Date only
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'interest_rate': interestRate,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Lending copyWith({
    String? id,
    String? userId,
    String? personName,
    String? personContact,
    double? amount,
    double? amountPaid,
    LendingType? type,
    LendingStatus? status,
    String? accountId,
    DateTime? lendingDate,
    DateTime? dueDate,
    double? interestRate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lending(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personName: personName ?? this.personName,
      personContact: personContact ?? this.personContact,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      type: type ?? this.type,
      status: status ?? this.status,
      accountId: accountId ?? this.accountId,
      lendingDate: lendingDate ?? this.lendingDate,
      dueDate: dueDate ?? this.dueDate,
      interestRate: interestRate ?? this.interestRate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Lending(id: $id, personName: $personName, amount: $amount, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lending && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum LendingType {
  lent('lent'),
  borrowed('borrowed');

  const LendingType(this.value);
  final String value;

  String toJson() => value;
  
  static LendingType fromString(String value) {
    switch (value) {
      case 'lent':
        return LendingType.lent;
      case 'borrowed':
        return LendingType.borrowed;
      default:
        throw ArgumentError('Invalid lending type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case LendingType.lent:
        return 'Lent to';
      case LendingType.borrowed:
        return 'Borrowed from';
    }
  }

  String get nepaliDisplayName {
    switch (this) {
      case LendingType.lent:
        return 'उधार दिएको';
      case LendingType.borrowed:
        return 'उधार लिएको';
    }
  }
}

enum LendingStatus {
  active('active'),
  completed('completed'),
  cancelled('cancelled');

  const LendingStatus(this.value);
  final String value;

  String toJson() => value;
  
  static LendingStatus fromString(String value) {
    switch (value) {
      case 'active':
        return LendingStatus.active;
      case 'completed':
        return LendingStatus.completed;
      case 'cancelled':
        return LendingStatus.cancelled;
      default:
        throw ArgumentError('Invalid lending status: $value');
    }
  }

  String get displayName {
    switch (this) {
      case LendingStatus.active:
        return 'Active';
      case LendingStatus.completed:
        return 'Completed';
      case LendingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get nepaliDisplayName {
    switch (this) {
      case LendingStatus.active:
        return 'सक्रिय';
      case LendingStatus.completed:
        return 'पूरा भएको';
      case LendingStatus.cancelled:
        return 'रद्द भएको';
    }
  }
}
