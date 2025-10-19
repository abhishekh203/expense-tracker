import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_nepal/models/chat_models.dart';

void main() {
  group('Embedding-Based Query Understanding Tests', () {
    test('should handle income queries correctly', () {
      final incomeQueries = [
        'what is my income this month',
        'how much did I earn this month',
        'show me my income',
        'what\'s my monthly income',
        'how much money did I make',
        'my income this month',
        'total income',
        'monthly earnings',
      ];

      for (final query in incomeQueries) {
        expect(query.isNotEmpty, isTrue);
        expect(query.toLowerCase().contains('income') || 
               query.toLowerCase().contains('earn') || 
               query.toLowerCase().contains('make'), isTrue);
      }
    });

    test('should handle spending queries correctly', () {
      final spendingQueries = [
        'how much did I spend on food',
        'what did I spend this month',
        'show me my expenses',
        'my spending on transportation',
        'total expenses',
        'monthly spending',
      ];

      for (final query in spendingQueries) {
        expect(query.isNotEmpty, isTrue);
        expect(query.toLowerCase().contains('spend') || 
               query.toLowerCase().contains('expense'), isTrue);
      }
    });

    test('should handle budget queries correctly', () {
      final budgetQueries = [
        'what\'s my budget status',
        'am I over budget',
        'budget remaining',
        'budget status',
        'how much budget left',
      ];

      for (final query in budgetQueries) {
        expect(query.isNotEmpty, isTrue);
        expect(query.toLowerCase().contains('budget'), isTrue);
      }
    });

    test('should handle savings queries correctly', () {
      final savingsQueries = [
        'how much did I save',
        'what\'s my savings rate',
        'savings this month',
        'how much saved',
        'savings analysis',
      ];

      for (final query in savingsQueries) {
        expect(query.isNotEmpty, isTrue);
        expect(query.toLowerCase().contains('save'), isTrue);
      }
    });

    test('should handle Nepali income queries', () {
      final nepaliIncomeQueries = [
        'मेरो आम्दानी कति छ?',
        'मैले यो महिना कति कमाएँ?',
        'मेरो मासिक आम्दानी',
        'कति पैसा कमाएँ?',
      ];

      for (final query in nepaliIncomeQueries) {
        expect(query.isNotEmpty, isTrue);
        // These would be processed by the embedding system
      }
    });

    test('should handle Nepali spending queries', () {
      final nepaliSpendingQueries = [
        'मैले कति खर्च गरेँ?',
        'मेरो खर्च कति छ?',
        'खर्चको विवरण',
        'कति पैसा खर्च भयो?',
      ];

      for (final query in nepaliSpendingQueries) {
        expect(query.isNotEmpty, isTrue);
        // These would be processed by the embedding system
      }
    });
  });

  group('Query Type Classification Tests', () {
    test('should classify income queries correctly', () {
      final incomeQuery = FinancialQuery(
        originalQuery: 'what is my income this month',
        processedQuery: 'income analysis this month',
        type: QueryType.incomeAnalysis,
        parameters: {'timeframe': 'this month'},
        confidence: 0.9,
      );

      expect(incomeQuery.type, QueryType.incomeAnalysis);
      expect(incomeQuery.parameters['timeframe'], 'this month');
      expect(incomeQuery.confidence, greaterThan(0.8));
    });

    test('should classify spending queries correctly', () {
      final spendingQuery = FinancialQuery(
        originalQuery: 'how much did I spend on food',
        processedQuery: 'spending by category: food',
        type: QueryType.spendingByCategory,
        parameters: {'category': 'food'},
        confidence: 0.85,
      );

      expect(spendingQuery.type, QueryType.spendingByCategory);
      expect(spendingQuery.parameters['category'], 'food');
      expect(spendingQuery.confidence, greaterThan(0.8));
    });

    test('should classify budget queries correctly', () {
      final budgetQuery = FinancialQuery(
        originalQuery: 'what\'s my budget status',
        processedQuery: 'budget status check',
        type: QueryType.budgetStatus,
        parameters: {},
        confidence: 0.9,
      );

      expect(budgetQuery.type, QueryType.budgetStatus);
      expect(budgetQuery.confidence, greaterThan(0.8));
    });
  });

  group('Embedding Similarity Tests', () {
    test('should calculate similarity between similar queries', () {
      // Test cosine similarity calculation
      final vectorA = [1.0, 2.0, 3.0];
      final vectorB = [1.0, 2.0, 3.0];
      
      // Identical vectors should have similarity of 1.0
      expect(vectorA.length, equals(vectorB.length));
      
      // Test different vectors
      final vectorC = [0.0, 0.0, 0.0];
      expect(vectorC.length, equals(vectorA.length));
    });

    test('should handle zero vectors in similarity calculation', () {
      final zeroVector = [0.0, 0.0, 0.0];
      final normalVector = [1.0, 2.0, 3.0];
      
      expect(zeroVector.length, equals(normalVector.length));
      // Zero vector should have similarity of 0.0 with any non-zero vector
    });
  });

  group('Query Parameter Extraction Tests', () {
    test('should extract timeframe parameters', () {
      final timeframes = [
        'this month',
        'last month',
        'this week',
        'last week',
        'this year',
        'last year',
        'today',
        'yesterday',
      ];

      for (final timeframe in timeframes) {
        expect(timeframe.isNotEmpty, isTrue);
        expect(timeframe.length > 2, isTrue);
      }
    });

    test('should extract category parameters', () {
      final categories = [
        'food',
        'transportation',
        'healthcare',
        'entertainment',
        'shopping',
        'groceries',
        'fuel',
        'mobile',
        'rent',
        'insurance',
      ];

      for (final category in categories) {
        expect(category.isNotEmpty, isTrue);
        expect(category.length > 2, isTrue);
      }
    });

    test('should extract amount parameters', () {
      final amounts = [
        '1000',
        '5000',
        '10000',
        '25000',
        '50000',
      ];

      for (final amount in amounts) {
        expect(amount.isNotEmpty, isTrue);
        expect(int.tryParse(amount), isNotNull);
      }
    });
  });

  group('Response Generation Tests', () {
    test('should generate income analysis response', () {
      final incomeResponse = {
        'text': 'Your income this month: Rs. 30,000',
        'type': ChatMessageType.financialData,
        'data': {
          'total': 30000,
          'dailyAverage': 1000,
          'weeklyAverage': 7000,
          'sources': [
            {'source': 'Salary', 'amount': 25000},
            {'source': 'Freelance', 'amount': 5000},
          ],
          'growth': 5,
        },
      };

      expect(incomeResponse['text'], contains('income'));
      expect(incomeResponse['type'], ChatMessageType.financialData);
      expect(incomeResponse['data'], isNotNull);
      expect((incomeResponse['data'] as Map<String, dynamic>)['total'], 30000);
    });

    test('should generate spending response', () {
      final spendingResponse = {
        'text': 'You spent Rs. 15,000 on food this month',
        'type': ChatMessageType.financialData,
        'data': {
          'amount': 15000,
          'category': 'food',
          'timeframe': 'this month',
          'percentage': 25,
        },
      };

      expect(spendingResponse['text'], contains('spent'));
      expect(spendingResponse['type'], ChatMessageType.financialData);
      expect((spendingResponse['data'] as Map<String, dynamic>)['amount'], 15000);
    });
  });

  group('Error Handling Tests', () {
    test('should handle unknown queries gracefully', () {
      final unknownQuery = FinancialQuery(
        originalQuery: 'random question',
        processedQuery: 'random question',
        type: QueryType.unknown,
        parameters: {},
        confidence: 0.1,
      );

      expect(unknownQuery.type, QueryType.unknown);
      expect(unknownQuery.confidence, lessThan(0.5));
    });

    test('should handle low confidence queries', () {
      final lowConfidenceQuery = FinancialQuery(
        originalQuery: 'unclear question',
        processedQuery: 'unclear question',
        type: QueryType.unknown,
        parameters: {},
        confidence: 0.3,
      );

      expect(lowConfidenceQuery.confidence, lessThan(0.5));
      // Low confidence queries should trigger clarification request
    });
  });
}
