class ReceiptOCRResult {
  final double? amount;
  final String? merchant;
  final String? description;
  final DateTime? date;
  final String? category;
  final String? currency;
  final double confidence;
  final String rawText;
  final List<String> items;

  ReceiptOCRResult({
    this.amount,
    this.merchant,
    this.description,
    this.date,
    this.category,
    this.currency,
    required this.confidence,
    required this.rawText,
    this.items = const [],
  });

  factory ReceiptOCRResult.fromJson(Map<String, dynamic> json) {
    return ReceiptOCRResult(
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      merchant: json['merchant'] as String?,
      description: json['description'] as String?,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      category: json['category'] as String?,
      currency: json['currency'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rawText: json['rawText'] as String? ?? '',
      items: json['items'] != null ? List<String>.from(json['items']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'merchant': merchant,
      'description': description,
      'date': date?.toIso8601String(),
      'category': category,
      'currency': currency,
      'confidence': confidence,
      'rawText': rawText,
      'items': items,
    };
  }

  /// Check if the OCR result has sufficient data to create a transaction
  bool get isValidForTransaction {
    return amount != null && amount! > 0 && confidence > 0.5;
  }

  /// Get display text for the transaction description
  String get displayDescription {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }
    if (merchant != null && merchant!.isNotEmpty) {
      return merchant!;
    }
    return 'Receipt Transaction';
  }

  /// Get suggested category based on merchant/description
  String get suggestedCategory {
    if (category != null && category!.isNotEmpty) {
      return category!;
    }
    
    // Basic category mapping based on common merchants/descriptions
    final merchantLower = merchant?.toLowerCase() ?? '';
    final descriptionLower = description?.toLowerCase() ?? '';
    final combined = '$merchantLower $descriptionLower';
    
    if (combined.contains('restaurant') || combined.contains('cafe') || 
        combined.contains('food') || combined.contains('dining')) {
      return 'Food & Dining';
    }
    if (combined.contains('fuel') || combined.contains('petrol') || 
        combined.contains('gas') || combined.contains('station')) {
      return 'Fuel';
    }
    if (combined.contains('grocery') || combined.contains('supermarket') || 
        combined.contains('mart') || combined.contains('store')) {
      return 'Groceries';
    }
    if (combined.contains('transport') || combined.contains('taxi') || 
        combined.contains('bus') || combined.contains('metro')) {
      return 'Transportation';
    }
    if (combined.contains('medical') || combined.contains('hospital') || 
        combined.contains('pharmacy') || combined.contains('doctor')) {
      return 'Healthcare';
    }
    if (combined.contains('mobile') || combined.contains('internet') || 
        combined.contains('telecom') || combined.contains('phone')) {
      return 'Mobile & Internet';
    }
    if (combined.contains('rent') || combined.contains('housing') || 
        combined.contains('apartment')) {
      return 'Rent';
    }
    if (combined.contains('electricity') || combined.contains('water') || 
        combined.contains('utility') || combined.contains('bill')) {
      return 'Bills & Utilities';
    }
    
    return 'Miscellaneous';
  }

  @override
  String toString() {
    return 'ReceiptOCRResult(amount: $amount, merchant: $merchant, description: $description, date: $date, category: $category, confidence: $confidence)';
  }
}

/// OCR processing status
enum OCRStatus {
  idle,
  processing,
  success,
  error;

  String get displayName {
    switch (this) {
      case OCRStatus.idle:
        return 'Ready';
      case OCRStatus.processing:
        return 'Processing...';
      case OCRStatus.success:
        return 'Success';
      case OCRStatus.error:
        return 'Error';
    }
  }
}
