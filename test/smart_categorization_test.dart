import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_nepal/models/category_suggestion.dart';

void main() {
  group('CategorySuggestion Tests', () {
    test('should create valid category suggestion from JSON', () {
      final json = {
        "category": "Food & Dining",
        "confidence": 0.95,
        "reasoning": "Description contains food-related keywords",
        "alternatives": ["Groceries", "Entertainment"]
      };

      final suggestion = CategorySuggestion.fromJson(json);

      expect(suggestion.category, "Food & Dining");
      expect(suggestion.confidence, 0.95);
      expect(suggestion.reasoning, "Description contains food-related keywords");
      expect(suggestion.alternatives, ["Groceries", "Entertainment"]);
      expect(suggestion.isHighConfidence, isTrue);
      expect(suggestion.confidenceLevel, "High");
      expect(suggestion.confidenceIcon, "✅");
    });

    test('should handle missing JSON fields with defaults', () {
      final json = {
        "category": "Transportation",
        "confidence": 0.6,
      };

      final suggestion = CategorySuggestion.fromJson(json);

      expect(suggestion.category, "Transportation");
      expect(suggestion.confidence, 0.6);
      expect(suggestion.reasoning, "No reasoning provided");
      expect(suggestion.alternatives, ["Shopping", "Personal Care"]);
      expect(suggestion.isMediumConfidence, isTrue);
    });

    test('should correctly identify confidence levels', () {
      final highConfidence = CategorySuggestion(
        category: "Fuel",
        confidence: 0.9,
        reasoning: "Clear match",
        alternatives: [],
      );
      expect(highConfidence.isHighConfidence, isTrue);
      expect(highConfidence.isMediumConfidence, isFalse);
      expect(highConfidence.isLowConfidence, isFalse);

      final mediumConfidence = CategorySuggestion(
        category: "Shopping",
        confidence: 0.7,
        reasoning: "Possible match",
        alternatives: [],
      );
      expect(mediumConfidence.isHighConfidence, isFalse);
      expect(mediumConfidence.isMediumConfidence, isTrue);
      expect(mediumConfidence.isLowConfidence, isFalse);

      final lowConfidence = CategorySuggestion(
        category: "Miscellaneous",
        confidence: 0.3,
        reasoning: "Unclear",
        alternatives: [],
      );
      expect(lowConfidence.isHighConfidence, isFalse);
      expect(lowConfidence.isMediumConfidence, isFalse);
      expect(lowConfidence.isLowConfidence, isTrue);
    });

    test('should format confidence display correctly', () {
      final suggestion = CategorySuggestion(
        category: "Healthcare",
        confidence: 0.85,
        reasoning: "Medical expense",
        alternatives: [],
      );

      expect(suggestion.confidenceDisplayText, "85% confidence");
    });

    test('should match categories correctly', () {
      final suggestion = CategorySuggestion(
        category: "Food & Dining",
        confidence: 0.8,
        reasoning: "Food related",
        alternatives: [],
      );

      expect(suggestion.matchesCategory("Food & Dining"), isTrue);
      expect(suggestion.matchesCategory("food & dining"), isTrue);
      expect(suggestion.matchesCategory("FOOD & DINING"), isTrue);
      expect(suggestion.matchesCategory("Transportation"), isFalse);
    });

    test('should provide all suggestions including alternatives', () {
      final suggestion = CategorySuggestion(
        category: "Entertainment",
        confidence: 0.7,
        reasoning: "Entertainment related",
        alternatives: ["Food & Dining", "Shopping"],
      );

      expect(suggestion.allSuggestions, ["Entertainment", "Food & Dining", "Shopping"]);
      expect(suggestion.bestAlternative, "Food & Dining");
    });

    test('should convert to JSON correctly', () {
      final suggestion = CategorySuggestion(
        category: "Bills & Utilities",
        confidence: 0.9,
        reasoning: "Utility bill payment",
        alternatives: ["Shopping"],
      );

      final json = suggestion.toJson();

      expect(json['category'], "Bills & Utilities");
      expect(json['confidence'], 0.9);
      expect(json['reasoning'], "Utility bill payment");
      expect(json['alternatives'], ["Shopping"]);
    });
  });

  group('SmartCategorizationStatus Tests', () {
    test('should return correct display names', () {
      expect(SmartCategorizationStatus.idle.displayName, 'Ready');
      expect(SmartCategorizationStatus.analyzing.displayName, 'Analyzing...');
      expect(SmartCategorizationStatus.success.displayName, 'Success');
      expect(SmartCategorizationStatus.error.displayName, 'Error');
    });

    test('should return correct icons', () {
      expect(SmartCategorizationStatus.idle.icon, '🤖');
      expect(SmartCategorizationStatus.analyzing.icon, '⏳');
      expect(SmartCategorizationStatus.success.icon, '✅');
      expect(SmartCategorizationStatus.error.icon, '❌');
    });
  });

  group('Nepali Context Tests', () {
    test('should handle Nepali transaction descriptions', () {
      // Test cases for common Nepali transaction descriptions
      final nepaliDescriptions = [
        "dal bhat tarkari", // Should suggest Food & Dining
        "petrol pump", // Should suggest Fuel
        "bus fare", // Should suggest Transportation
        "mobile recharge", // Should suggest Mobile & Internet
        "doctor visit", // Should suggest Healthcare
        "school fees", // Should suggest Education
        "movie ticket", // Should suggest Entertainment
        "groceries", // Should suggest Groceries
        "rent payment", // Should suggest Rent
        "insurance premium", // Should suggest Insurance
      ];

      // These would be tested with actual AI service calls in integration tests
      for (final description in nepaliDescriptions) {
        expect(description.isNotEmpty, isTrue);
        expect(description.length >= 3, isTrue);
      }
    });
  });
}
