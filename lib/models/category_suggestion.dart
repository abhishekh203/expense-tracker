class CategorySuggestion {
  final String category;
  final double confidence;
  final String reasoning;
  final List<String> alternatives;

  CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.reasoning,
    required this.alternatives,
  });

  factory CategorySuggestion.fromJson(Map<String, dynamic> json) {
    return CategorySuggestion(
      category: json['category'] as String? ?? 'Miscellaneous',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      reasoning: json['reasoning'] as String? ?? 'No reasoning provided',
      alternatives: json['alternatives'] != null 
          ? List<String>.from(json['alternatives'])
          : ['Shopping', 'Personal Care'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'confidence': confidence,
      'reasoning': reasoning,
      'alternatives': alternatives,
    };
  }

  /// Check if suggestion is high confidence
  bool get isHighConfidence => confidence >= 0.8;

  /// Check if suggestion is medium confidence
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;

  /// Check if suggestion is low confidence
  bool get isLowConfidence => confidence < 0.5;

  /// Get confidence level as string
  String get confidenceLevel {
    if (isHighConfidence) return 'High';
    if (isMediumConfidence) return 'Medium';
    return 'Low';
  }

  /// Get confidence color for UI
  String get confidenceColor {
    if (isHighConfidence) return '#10b981'; // Green
    if (isMediumConfidence) return '#f59e0b'; // Orange
    return '#ef4444'; // Red
  }

  /// Get confidence icon
  String get confidenceIcon {
    if (isHighConfidence) return '✅';
    if (isMediumConfidence) return '⚠️';
    return '❓';
  }

  /// Get display text for confidence
  String get confidenceDisplayText {
    return '${(confidence * 100).toStringAsFixed(0)}% confidence';
  }

  /// Check if this suggestion matches a given category
  bool matchesCategory(String categoryName) {
    return category.toLowerCase() == categoryName.toLowerCase();
  }

  /// Get the best alternative category (first one)
  String get bestAlternative {
    return alternatives.isNotEmpty ? alternatives.first : 'Shopping';
  }

  /// Get all suggested categories (primary + alternatives)
  List<String> get allSuggestions {
    return [category, ...alternatives];
  }

  @override
  String toString() {
    return 'CategorySuggestion(category: $category, confidence: ${(confidence * 100).toStringAsFixed(0)}%, reasoning: $reasoning)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategorySuggestion &&
        other.category == category &&
        other.confidence == confidence &&
        other.reasoning == reasoning;
  }

  @override
  int get hashCode {
    return category.hashCode ^
        confidence.hashCode ^
        reasoning.hashCode;
  }
}

/// Smart categorization status
enum SmartCategorizationStatus {
  idle,
  analyzing,
  success,
  error;

  String get displayName {
    switch (this) {
      case SmartCategorizationStatus.idle:
        return 'Ready';
      case SmartCategorizationStatus.analyzing:
        return 'Analyzing...';
      case SmartCategorizationStatus.success:
        return 'Success';
      case SmartCategorizationStatus.error:
        return 'Error';
    }
  }

  String get icon {
    switch (this) {
      case SmartCategorizationStatus.idle:
        return '🤖';
      case SmartCategorizationStatus.analyzing:
        return '⏳';
      case SmartCategorizationStatus.success:
        return '✅';
      case SmartCategorizationStatus.error:
        return '❌';
    }
  }
}
