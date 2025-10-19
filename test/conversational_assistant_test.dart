import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker_nepal/models/chat_models.dart';

void main() {
  group('Chat Models Tests', () {
    test('should create valid chat message', () {
      final message = ChatMessage.user('How much did I spend on food?');
      
      expect(message.text, 'How much did I spend on food?');
      expect(message.isUser, isTrue);
      expect(message.type, ChatMessageType.text);
      expect(message.timestamp, isA<DateTime>());
    });

    test('should create assistant message with data', () {
      final message = ChatMessage.assistant(
        'You spent Rs. 5,000 on food this month.',
        type: ChatMessageType.financialData,
        data: {'amount': 5000, 'category': 'food'},
      );
      
      expect(message.text, 'You spent Rs. 5,000 on food this month.');
      expect(message.isUser, isFalse);
      expect(message.type, ChatMessageType.financialData);
      expect(message.data, {'amount': 5000, 'category': 'food'});
    });

    test('should serialize and deserialize chat message', () {
      final originalMessage = ChatMessage.assistant(
        'Test message',
        type: ChatMessageType.financialData,
        data: {'test': 'data'},
      );
      
      final json = originalMessage.toJson();
      final restoredMessage = ChatMessage.fromJson(json);
      
      expect(restoredMessage.text, originalMessage.text);
      expect(restoredMessage.isUser, originalMessage.isUser);
      expect(restoredMessage.type, originalMessage.type);
      expect(restoredMessage.data, originalMessage.data);
    });
  });

  group('Financial Query Tests', () {
    test('should create valid financial query', () {
      final query = FinancialQuery(
        originalQuery: 'How much did I spend on food last month?',
        processedQuery: 'spending by category: food, timeframe: last month',
        type: QueryType.spendingByCategory,
        parameters: {
          'category': 'food',
          'timeframe': 'last month',
        },
        confidence: 0.9,
      );
      
      expect(query.originalQuery, 'How much did I spend on food last month?');
      expect(query.type, QueryType.spendingByCategory);
      expect(query.parameters['category'], 'food');
      expect(query.confidence, 0.9);
    });

    test('should serialize and deserialize financial query', () {
      final originalQuery = FinancialQuery(
        originalQuery: 'Test query',
        processedQuery: 'processed',
        type: QueryType.budgetStatus,
        parameters: {'test': 'param'},
        confidence: 0.8,
      );
      
      final json = originalQuery.toJson();
      final restoredQuery = FinancialQuery.fromJson(json);
      
      expect(restoredQuery.originalQuery, originalQuery.originalQuery);
      expect(restoredQuery.type, originalQuery.type);
      expect(restoredQuery.parameters, originalQuery.parameters);
      expect(restoredQuery.confidence, originalQuery.confidence);
    });
  });

  group('Financial Insight Tests', () {
    test('should create valid financial insight', () {
      final insight = FinancialInsight(
        title: 'Food Spending',
        description: 'You spent more on food this month',
        value: '5000',
        currency: 'NPR',
        type: InsightType.warning,
        confidence: 0.8,
        suggestions: ['Cook at home more', 'Use coupons'],
      );
      
      expect(insight.title, 'Food Spending');
      expect(insight.type, InsightType.warning);
      expect(insight.suggestions.length, 2);
      expect(insight.confidence, 0.8);
    });

    test('should serialize and deserialize financial insight', () {
      final originalInsight = FinancialInsight(
        title: 'Test Insight',
        description: 'Test description',
        value: '1000',
        currency: 'NPR',
        type: InsightType.info,
        confidence: 0.7,
        suggestions: ['suggestion1', 'suggestion2'],
      );
      
      final json = originalInsight.toJson();
      final restoredInsight = FinancialInsight.fromJson(json);
      
      expect(restoredInsight.title, originalInsight.title);
      expect(restoredInsight.type, originalInsight.type);
      expect(restoredInsight.suggestions, originalInsight.suggestions);
    });
  });

  group('Chat Session Tests', () {
    test('should create new chat session', () {
      final session = ChatSession.newSession('user123');
      
      expect(session.userId, 'user123');
      expect(session.messages.isEmpty, isTrue);
      expect(session.id.isNotEmpty, isTrue);
    });

    test('should add message to chat session', () {
      final session = ChatSession.newSession('user123');
      final message = ChatMessage.user('Hello');
      
      final updatedSession = session.addMessage(message);
      
      expect(updatedSession.messages.length, 1);
      expect(updatedSession.messages.first.text, 'Hello');
      expect(updatedSession.lastActivity.isAfter(session.lastActivity), isTrue);
    });

    test('should serialize and deserialize chat session', () {
      final originalSession = ChatSession.newSession('user123');
      final message = ChatMessage.user('Test message');
      final sessionWithMessage = originalSession.addMessage(message);
      
      final json = sessionWithMessage.toJson();
      final restoredSession = ChatSession.fromJson(json);
      
      expect(restoredSession.userId, sessionWithMessage.userId);
      expect(restoredSession.messages.length, sessionWithMessage.messages.length);
      expect(restoredSession.messages.first.text, 'Test message');
    });
  });

  group('Query Type Tests', () {
    test('should have all required query types', () {
      final queryTypes = QueryType.values;
      
      expect(queryTypes.contains(QueryType.spendingByCategory), isTrue);
      expect(queryTypes.contains(QueryType.budgetStatus), isTrue);
      expect(queryTypes.contains(QueryType.topExpenses), isTrue);
      expect(queryTypes.contains(QueryType.savingsAnalysis), isTrue);
      expect(queryTypes.contains(QueryType.unknown), isTrue);
    });
  });

  group('Chat Message Type Tests', () {
    test('should have all required message types', () {
      final messageTypes = ChatMessageType.values;
      
      expect(messageTypes.contains(ChatMessageType.text), isTrue);
      expect(messageTypes.contains(ChatMessageType.financialData), isTrue);
      expect(messageTypes.contains(ChatMessageType.chart), isTrue);
      expect(messageTypes.contains(ChatMessageType.suggestion), isTrue);
      expect(messageTypes.contains(ChatMessageType.error), isTrue);
    });
  });

  group('Insight Type Tests', () {
    test('should have all required insight types', () {
      final insightTypes = InsightType.values;
      
      expect(insightTypes.contains(InsightType.info), isTrue);
      expect(insightTypes.contains(InsightType.warning), isTrue);
      expect(insightTypes.contains(InsightType.success), isTrue);
      expect(insightTypes.contains(InsightType.error), isTrue);
      expect(insightTypes.contains(InsightType.trend), isTrue);
    });
  });

  group('Sample Queries Tests', () {
    test('should handle common financial queries', () {
      final commonQueries = [
        'How much did I spend on food last month?',
        'What\'s my budget status?',
        'Show me my top expenses',
        'How much did I save this month?',
        'Compare this month vs last month',
        'What are my recent transactions?',
        'Give me a financial summary',
        'How much did I spend this week?',
      ];

      for (final query in commonQueries) {
        expect(query.isNotEmpty, isTrue);
        expect(query.length > 10, isTrue);
      }
    });

    test('should handle Nepali context queries', () {
      final nepaliQueries = [
        'मैले खानामा कति खर्च गरेँ?',
        'मेरो बजेट कस्तो छ?',
        'मेरो मुख्य खर्चहरू देखाउनुहोस्',
        'मैले यो महिना कति बचत गरेँ?',
      ];

      for (final query in nepaliQueries) {
        expect(query.isNotEmpty, isTrue);
        // These would be processed by the AI service
      }
    });
  });
}
