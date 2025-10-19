import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_nepal/models/receipt_ocr_result.dart';

void main() {
  group('ReceiptOCRResult Tests', () {
    test('should create valid OCR result from JSON', () {
      final json = {
        'amount': 150.50,
        'merchant': 'Cafe Soma',
        'description': 'Coffee and pastry',
        'date': '2024-01-15',
        'category': 'Food & Dining',
        'currency': 'NPR',
        'confidence': 0.85,
        'rawText': 'Cafe Soma\nCoffee: 120.00\nPastry: 30.50\nTotal: 150.50',
        'items': ['Coffee', 'Pastry'],
      };

      final result = ReceiptOCRResult.fromJson(json);

      expect(result.amount, 150.50);
      expect(result.merchant, 'Cafe Soma');
      expect(result.description, 'Coffee and pastry');
      expect(result.date, DateTime(2024, 1, 15));
      expect(result.category, 'Food & Dining');
      expect(result.confidence, 0.85);
      expect(result.isValidForTransaction, true);
    });

    test('should suggest correct category based on merchant', () {
      final result = ReceiptOCRResult(
        amount: 100.0,
        merchant: 'Shell Petrol Station',
        description: 'Fuel purchase',
        confidence: 0.9,
        rawText: 'Shell Station\nPetrol: 100.00',
      );

      expect(result.suggestedCategory, 'Fuel');
    });

    test('should suggest correct category based on description', () {
      final result = ReceiptOCRResult(
        amount: 500.0,
        merchant: 'Local Restaurant',
        description: 'Dinner with friends',
        confidence: 0.8,
        rawText: 'Restaurant\nDinner: 500.00',
      );

      expect(result.suggestedCategory, 'Food & Dining');
    });

    test('should return false for invalid transaction when amount is null', () {
      final result = ReceiptOCRResult(
        amount: null,
        merchant: 'Test Store',
        description: 'Test purchase',
        confidence: 0.5,
        rawText: 'Test receipt',
      );

      expect(result.isValidForTransaction, false);
    });

    test('should return false for invalid transaction when confidence is low', () {
      final result = ReceiptOCRResult(
        amount: 100.0,
        merchant: 'Test Store',
        description: 'Test purchase',
        confidence: 0.2,
        rawText: 'Test receipt',
      );

      expect(result.isValidForTransaction, false);
    });
  });

  group('OCRStatus Tests', () {
    test('should return correct display names', () {
      expect(OCRStatus.idle.displayName, 'Ready');
      expect(OCRStatus.processing.displayName, 'Processing...');
      expect(OCRStatus.success.displayName, 'Success');
      expect(OCRStatus.error.displayName, 'Error');
    });
  });
}
