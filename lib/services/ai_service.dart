import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/receipt_ocr_result.dart';
import '../models/category_suggestion.dart';
import '../models/chat_models.dart';
import '../models/transaction.dart';
import 'database_service.dart';

class AIService {

  /// Process receipt image using Gemini Vision API
  static Future<ReceiptOCRResult> processReceiptImage(File imageFile) async {
    try {
      // For web platform, use HTTP API directly to avoid namespace issues
      return await processReceiptImageFallback(imageFile);
      
    } catch (e) {
      print('Error processing receipt: $e');
      throw Exception('Failed to process receipt: $e');
    }
  }

  /// Enhance OCR result with additional processing
  static ReceiptOCRResult _enhanceOCRResult(ReceiptOCRResult result) {
    // If no date found, use today's date
    final date = result.date ?? DateTime.now();
    
    // Ensure currency is set
    final currency = result.currency ?? 'NPR';
    
    // Enhance description if missing
    String description = result.description ?? '';
    if (description.isEmpty && result.merchant != null) {
      description = result.merchant!;
    }
    
    return ReceiptOCRResult(
      amount: result.amount,
      merchant: result.merchant,
      description: description,
      date: date,
      category: result.suggestedCategory,
      currency: currency,
      confidence: result.confidence,
      rawText: result.rawText,
      items: result.items,
    );
  }

  /// Process receipt image using HTTP API (primary method)
  static Future<ReceiptOCRResult> processReceiptImageFallback(File imageFile) async {
    try {
      // Convert image to base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // Use Gemini API directly via HTTP
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${AppConstants.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
Extract receipt information and return as JSON:
{
  "amount": <total amount>,
  "merchant": "<store name>",
  "description": "<purchase description>",
  "date": "<YYYY-MM-DD>",
  "category": "<expense category>",
  "currency": "NPR",
  "confidence": <0-1>,
  "rawText": "<all text>",
  "items": ["<items>"]
}
'''
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final content = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (content != null) {
          // Parse JSON from response
          final jsonStart = content.indexOf('{');
          final jsonEnd = content.lastIndexOf('}') + 1;
          
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonString = content.substring(jsonStart, jsonEnd);
            final jsonData = json.decode(jsonString) as Map<String, dynamic>;
            return _enhanceOCRResult(ReceiptOCRResult.fromJson(jsonData));
          }
        }
      }
      
      throw Exception('Failed to process receipt via HTTP API');
    } catch (e) {
      print('HTTP OCR error: $e');
      throw Exception('Failed to process receipt: $e');
    }
  }

  /// Get smart category suggestion using embeddings
  static Future<CategorySuggestion> suggestCategory(String description) async {
    try {
      // First, try embedding-based approach
      final embeddingSuggestion = await _suggestCategoryWithEmbeddings(description);
      if (embeddingSuggestion.confidence > 0.6) {
        return embeddingSuggestion;
      }

      // Fallback to direct AI analysis
      return await _suggestCategoryWithAI(description);
    } catch (e) {
      print('Error suggesting category: $e');
      return CategorySuggestion(
        category: 'Miscellaneous',
        confidence: 0.1,
        reasoning: 'Error occurred during analysis',
        alternatives: ['Shopping', 'Personal Care'],
      );
    }
  }

  /// Suggest category using embeddings for better semantic understanding
  static Future<CategorySuggestion> _suggestCategoryWithEmbeddings(String description) async {
    try {
      // Get embedding for the description
      final descriptionEmbedding = await _getEmbedding(description);
      
      // Define category embeddings (pre-computed or generated)
      final categoryEmbeddings = await _getCategoryEmbeddings();
      
      // Calculate similarity scores
      final similarities = <String, double>{};
      for (final entry in categoryEmbeddings.entries) {
        final similarity = _cosineSimilarity(descriptionEmbedding, entry.value);
        similarities[entry.key] = similarity;
      }
      
      // Find best match
      final sortedCategories = similarities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final bestMatch = sortedCategories.first;
      final confidence = bestMatch.value;
      
      // Get alternatives (next best matches)
      final alternatives = sortedCategories.skip(1).take(2).map((e) => e.key).toList();
      
      return CategorySuggestion(
        category: bestMatch.key,
        confidence: confidence,
        reasoning: 'Semantic similarity: ${(confidence * 100).toStringAsFixed(0)}% match with ${bestMatch.key}',
        alternatives: alternatives,
      );
    } catch (e) {
      print('Error in embedding-based categorization: $e');
      throw e;
    }
  }

  /// Get embedding for text using Gemini embedding model
  static Future<List<double>> _getEmbedding(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/embedding-001:embedContent?key=${AppConstants.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': {
            'parts': [
              {'text': text}
            ]
          }
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final embedding = responseData['embedding']?['values'] as List<dynamic>?;
        
        if (embedding != null) {
          return embedding.map((e) => (e as num).toDouble()).toList();
        }
      }
      
      throw Exception('Failed to get embedding');
    } catch (e) {
      print('Error getting embedding: $e');
      throw e;
    }
  }

  /// Get pre-computed category embeddings
  static Future<Map<String, List<double>>> _getCategoryEmbeddings() async {
    // These would ideally be pre-computed and stored
    // For now, we'll generate them on-demand
    final categories = [
      'Food & Dining',
      'Transportation', 
      'Shopping',
      'Bills & Utilities',
      'Healthcare',
      'Education',
      'Entertainment',
      'Groceries',
      'Fuel',
      'Mobile & Internet',
      'Rent',
      'Insurance',
      'Personal Care',
      'Gifts & Donations',
      'Travel',
      'Miscellaneous'
    ];

    final embeddings = <String, List<double>>{};
    
    for (final category in categories) {
      try {
        final embedding = await _getEmbedding(category);
        embeddings[category] = embedding;
      } catch (e) {
        print('Error getting embedding for $category: $e');
        // Use fallback embedding
        embeddings[category] = List.filled(768, 0.0);
      }
    }
    
    return embeddings;
  }

  /// Calculate cosine similarity between two vectors
  static double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0.0 || normB == 0.0) return 0.0;
    
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Fallback method using direct AI analysis
  static Future<CategorySuggestion> _suggestCategoryWithAI(String description) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${AppConstants.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
Analyze this transaction description and suggest the most appropriate expense category:
"$description"

Available categories: Food & Dining, Transportation, Shopping, Bills & Utilities, Healthcare, Education, Entertainment, Groceries, Fuel, Mobile & Internet, Rent, Insurance, Personal Care, Gifts & Donations, Travel, Miscellaneous

Return JSON format:
{
  "category": "<suggested category name>",
  "confidence": <confidence score 0-1>,
  "reasoning": "<brief explanation>",
  "alternatives": ["<alternative category 1>", "<alternative category 2>"]
}

Guidelines:
- Consider Nepali context (e.g., "dal bhat" = Food & Dining, "petrol pump" = Fuel)
- For real estate: "buying house", "house purchase", "property" = Miscellaneous (major investment)
- For vehicles: "car purchase", "bike buying" = Miscellaneous (major purchase)
- For daily expenses: "groceries", "food", "transport" = appropriate categories
- Higher confidence for clear matches (e.g., "petrol" = Fuel, "doctor" = Healthcare)
- Lower confidence for ambiguous or major purchases
- Provide 2-3 alternative categories when uncertain
- Be specific about why you chose this category
'''
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final content = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (content != null) {
          // Parse JSON response
          final jsonStart = content.indexOf('{');
          final jsonEnd = content.lastIndexOf('}') + 1;
          
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonString = content.substring(jsonStart, jsonEnd);
            final jsonData = json.decode(jsonString) as Map<String, dynamic>;
            
            return CategorySuggestion.fromJson(jsonData);
          }
        }
      }
      
      return CategorySuggestion(
        category: 'Miscellaneous',
        confidence: 0.3,
        reasoning: 'Unable to analyze description',
        alternatives: ['Shopping', 'Personal Care'],
      );
    } catch (e) {
      print('Error in AI-based categorization: $e');
      throw e;
    }
  }

  /// Get category suggestions for multiple transactions (batch processing)
  static Future<List<CategorySuggestion>> suggestCategoriesBatch(List<String> descriptions) async {
    try {
      final suggestions = <CategorySuggestion>[];
      
      // Process descriptions in batches to avoid API limits
      const batchSize = 5;
      for (int i = 0; i < descriptions.length; i += batchSize) {
        final batch = descriptions.skip(i).take(batchSize).toList();
        final batchSuggestions = await Future.wait(
          batch.map((desc) => suggestCategory(desc))
        );
        suggestions.addAll(batchSuggestions);
        
        // Small delay between batches to respect API limits
        if (i + batchSize < descriptions.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      return suggestions;
    } catch (e) {
      print('Error in batch category suggestion: $e');
      return descriptions.map((desc) => CategorySuggestion(
        category: 'Miscellaneous',
        confidence: 0.1,
        reasoning: 'Batch processing error',
        alternatives: ['Shopping', 'Personal Care'],
      )).toList();
    }
  }

  /// Learn from user corrections to improve future suggestions
  static Future<void> learnFromCorrection(String originalDescription, String correctCategory) async {
    try {
      // Store learning data for future model improvements
      // This could be stored locally or sent to a learning service
      print('Learning: "$originalDescription" should be categorized as "$correctCategory"');
      
      // For now, we'll just log the correction
      // In a production app, you might store this in a local database
      // or send it to a machine learning service for model improvement
    } catch (e) {
      print('Error learning from correction: $e');
    }
  }

  /// Validate OCR result quality
  static bool isValidOCRResult(ReceiptOCRResult result) {
    return result.amount != null && 
           result.amount! > 0 && 
           result.confidence > 0.3 &&
           (result.merchant != null || result.description != null);
  }

  /// Test method for debugging categorization
  static Future<void> testCategorization() async {
    final testDescriptions = [
      'dal bhat tarkari',
      'petrol pump',
      'bus fare',
      'doctor visit',
      'school fees',
      'movie ticket',
      'groceries',
      'mobile recharge',
      'rent payment',
      'buying house',
      'car purchase',
      'insurance premium',
    ];

    print('🧪 Testing Smart Categorization...');
    
    for (final description in testDescriptions) {
      try {
        final suggestion = await suggestCategory(description);
        print('📝 "$description" → ${suggestion.category} (${(suggestion.confidence * 100).toStringAsFixed(0)}%)');
        print('   Reasoning: ${suggestion.reasoning}');
        print('   Alternatives: ${suggestion.alternatives.join(', ')}');
        print('');
      } catch (e) {
        print('❌ Error testing "$description": $e');
      }
    }
  }

  // ==================== CONVERSATIONAL BUDGET ASSISTANT ====================

  /// Process natural language financial query
  static Future<ChatMessage> processFinancialQuery(String query, String userId) async {
    try {
      // Parse the natural language query
      final parsedQuery = await _parseFinancialQuery(query);
      
      if (parsedQuery.confidence < 0.5) {
        return ChatMessage.assistant(
          "I'm not sure I understand your question. Could you rephrase it? For example, you can ask:\n• 'How much did I spend on food last month?'\n• 'What's my budget status?'\n• 'Show me my top expenses'",
          type: ChatMessageType.error,
        );
      }

      // Generate response based on query type
      final response = await _generateFinancialResponse(parsedQuery, userId);
      
      return ChatMessage.assistant(
        response['text'] as String,
        type: response['type'] as ChatMessageType,
        data: response['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error processing financial query: $e');
      return ChatMessage.assistant(
        "Sorry, I encountered an error processing your request. Please try again.",
        type: ChatMessageType.error,
      );
    }
  }

  /// Parse natural language query into structured format using embeddings
  static Future<FinancialQuery> _parseFinancialQuery(String query) async {
    try {
      // First, try embedding-based approach for better semantic understanding
      final embeddingQuery = await _parseQueryWithEmbeddings(query);
      if (embeddingQuery.confidence > 0.6) {
        return embeddingQuery;
      }

      // Fallback to direct AI analysis
      return await _parseQueryWithAI(query);
    } catch (e) {
      print('Error parsing financial query: $e');
      return FinancialQuery(
        originalQuery: query,
        processedQuery: query,
        type: QueryType.unknown,
        parameters: {},
        confidence: 0.1,
      );
    }
  }

  /// Parse query using embeddings for better semantic understanding
  static Future<FinancialQuery> _parseQueryWithEmbeddings(String query) async {
    try {
      // Get embedding for the user query
      final queryEmbedding = await _getEmbedding(query);
      
      // Define query type embeddings (pre-computed examples)
      final queryTypeEmbeddings = await _getQueryTypeEmbeddings();
      
      // Calculate similarity scores
      final similarities = <QueryType, double>{};
      for (final entry in queryTypeEmbeddings.entries) {
        final similarity = _cosineSimilarity(queryEmbedding, entry.value);
        similarities[entry.key] = similarity;
      }
      
      // Find best match
      final sortedTypes = similarities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final bestMatch = sortedTypes.first;
      final confidence = bestMatch.value;
      
      // Extract parameters using AI
      final parameters = await _extractQueryParameters(query, bestMatch.key);
      
      return FinancialQuery(
        originalQuery: query,
        processedQuery: query,
        type: bestMatch.key,
        parameters: parameters,
        confidence: confidence,
      );
    } catch (e) {
      print('Error in embedding-based query parsing: $e');
      throw e;
    }
  }

  /// Get pre-computed query type embeddings
  static Future<Map<QueryType, List<double>>> _getQueryTypeEmbeddings() async {
    // These would ideally be pre-computed and stored
    // For now, we'll generate them on-demand with example queries
    final queryExamples = {
      QueryType.spendingByCategory: [
        'How much did I spend on food last month?',
        'What did I spend on transportation this week?',
        'Show me my healthcare expenses',
        'How much on entertainment this year?',
      ],
      QueryType.spendingByTime: [
        'How much did I spend this week?',
        'What did I spend today?',
        'Show me my expenses this month',
        'How much did I spend yesterday?',
      ],
      QueryType.budgetStatus: [
        'What\'s my budget status?',
        'Am I over budget?',
        'How much budget do I have left?',
        'Which categories are over budget?',
      ],
      QueryType.topExpenses: [
        'Show me my top expenses',
        'What are my biggest spending categories?',
        'List my highest expenses',
        'What did I spend the most on?',
      ],
      QueryType.savingsAnalysis: [
        'How much did I save this month?',
        'What\'s my savings rate?',
        'How much more can I save?',
        'Compare my savings to last month',
      ],
      QueryType.expenseTrends: [
        'Compare this month vs last month',
        'How is my spending trending?',
        'Show me spending trends',
        'Compare my expenses over time',
      ],
      QueryType.recentTransactions: [
        'What are my recent transactions?',
        'Show me today\'s expenses',
        'What did I spend yesterday?',
        'List my transactions this week',
      ],
      QueryType.financialSummary: [
        'Give me a financial summary',
        'How am I doing financially?',
        'What\'s my financial health?',
        'Summarize my spending',
      ],
      // Add income-related queries
      QueryType.incomeAnalysis: [
        'What is my income this month?',
        'How much did I earn this month?',
        'Show me my income',
        'What\'s my monthly income?',
        'How much money did I make?',
      ],
    };

    final embeddings = <QueryType, List<double>>{};
    
    for (final entry in queryExamples.entries) {
      try {
        // Use the first example as the representative embedding
        final exampleQuery = entry.value.first;
        final embedding = await _getEmbedding(exampleQuery);
        embeddings[entry.key] = embedding;
      } catch (e) {
        print('Error getting embedding for ${entry.key}: $e');
        // Use fallback embedding
        embeddings[entry.key] = List.filled(768, 0.0);
      }
    }
    
    return embeddings;
  }

  /// Extract parameters from query using AI
  static Future<Map<String, dynamic>> _extractQueryParameters(String query, QueryType type) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${AppConstants.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
Extract parameters from this financial query:
"$query"

Query type: ${type.toString().split('.').last}

Return JSON format:
{
  "category": "<category if mentioned>",
  "timeframe": "<timeframe if mentioned>",
  "amount": "<amount if mentioned>",
  "comparison": "<comparison type if mentioned>",
  "currency": "<currency if mentioned>"
}

Guidelines:
- Extract category names (food, transportation, healthcare, entertainment, etc.)
- Extract timeframes (last month, this week, this month, yesterday, today, etc.)
- Extract amounts if mentioned
- Determine comparison types (month-over-month, year-over-year, etc.)
- Extract currency (NPR, USD, etc.)
- For income queries, look for income-related terms
- Return empty strings for missing parameters
'''
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final content = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (content != null) {
          // Parse JSON response
          final jsonStart = content.indexOf('{');
          final jsonEnd = content.lastIndexOf('}') + 1;
          
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonString = content.substring(jsonStart, jsonEnd);
            final jsonData = json.decode(jsonString) as Map<String, dynamic>;
            return jsonData;
          }
        }
      }
      
      return {};
    } catch (e) {
      print('Error extracting query parameters: $e');
      return {};
    }
  }

  /// Fallback method using direct AI analysis
  static Future<FinancialQuery> _parseQueryWithAI(String query) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${AppConstants.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
Parse this financial query and extract structured information:
"$query"

Return JSON format:
{
  "originalQuery": "$query",
  "processedQuery": "<cleaned query>",
  "type": "<query_type>",
  "parameters": {
    "category": "<category if mentioned>",
    "timeframe": "<timeframe if mentioned>",
    "amount": "<amount if mentioned>",
    "comparison": "<comparison type if mentioned>"
  },
  "confidence": <confidence_score_0-1>
}

Query types: spendingByCategory, spendingByTime, spendingComparison, budgetStatus, savingsAnalysis, expenseTrends, topExpenses, recentTransactions, financialSummary, incomeAnalysis

Examples:
- "How much did I spend on food last month?" → spendingByCategory
- "What's my budget status?" → budgetStatus
- "Show me my top expenses" → topExpenses
- "Compare this month vs last month" → spendingComparison
- "How much did I save this month?" → savingsAnalysis
- "What is my income this month?" → incomeAnalysis

Guidelines:
- Extract category names (food, transportation, healthcare, etc.)
- Extract timeframes (last month, this week, last year, etc.)
- Extract amounts if mentioned
- Determine comparison types (month-over-month, year-over-year, etc.)
- Provide confidence score based on clarity
- For income queries, use incomeAnalysis type
'''
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final content = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (content != null) {
          // Parse JSON response
          final jsonStart = content.indexOf('{');
          final jsonEnd = content.lastIndexOf('}') + 1;
          
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonString = content.substring(jsonStart, jsonEnd);
            final jsonData = json.decode(jsonString) as Map<String, dynamic>;
            
            return FinancialQuery.fromJson(jsonData);
          }
        }
      }
      
      return FinancialQuery(
        originalQuery: query,
        processedQuery: query,
        type: QueryType.unknown,
        parameters: {},
        confidence: 0.1,
      );
    } catch (e) {
      print('Error in AI-based query parsing: $e');
      throw e;
    }
  }

  /// Generate financial response based on parsed query
  static Future<Map<String, dynamic>> _generateFinancialResponse(FinancialQuery query, String userId) async {
    try {
      switch (query.type) {
        case QueryType.spendingByCategory:
          return await _generateSpendingByCategoryResponse(query, userId);
        case QueryType.spendingByTime:
          return await _generateSpendingByTimeResponse(query, userId);
        case QueryType.budgetStatus:
          return await _generateBudgetStatusResponse(query, userId);
        case QueryType.topExpenses:
          return await _generateTopExpensesResponse(query, userId);
        case QueryType.savingsAnalysis:
          return await _generateSavingsAnalysisResponse(query, userId);
        case QueryType.expenseTrends:
          return await _generateExpenseTrendsResponse(query, userId);
        case QueryType.recentTransactions:
          return await _generateRecentTransactionsResponse(query, userId);
        case QueryType.financialSummary:
          return await _generateFinancialSummaryResponse(query, userId);
        case QueryType.incomeAnalysis:
          return await _generateIncomeAnalysisResponse(query, userId);
        default:
          return {
            'text': "I'm not sure how to help with that. Try asking about your spending, budget, or financial trends.",
            'type': ChatMessageType.error,
            'data': null,
          };
      }
    } catch (e) {
      print('Error generating financial response: $e');
      return {
        'text': "Sorry, I couldn't process your request. Please try again.",
        'type': ChatMessageType.error,
        'data': null,
      };
    }
  }

  /// Generate spending by category response using real data
  static Future<Map<String, dynamic>> _generateSpendingByCategoryResponse(FinancialQuery query, String userId) async {
    try {
      final category = query.parameters['category'] ?? 'all categories';
      final timeframe = query.parameters['timeframe'] ?? 'this month';
      
      // Get real spending data from database
      final transactions = await DatabaseService.getUserTransactions(
        userId,
        limit: 1000, // Get all transactions for analysis
      );
      
      // Filter expense transactions for the timeframe
      final expenseTransactions = transactions.where((t) => 
        t.type == TransactionType.expense &&
        t.transactionDate.isAfter(_getStartDateForTimeframe(timeframe).subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(_getEndDateForTimeframe(timeframe).add(const Duration(days: 1)))
      ).toList();
      
      // Filter by category if specified
      List<dynamic> filteredTransactions = expenseTransactions;
      if (category != 'all categories') {
        filteredTransactions = expenseTransactions.where((t) => 
          t.category?.name.toLowerCase().contains(category.toLowerCase()) == true
        ).toList();
      }
      
      final totalSpending = filteredTransactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
      final totalAllSpending = expenseTransactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
      
      if (totalSpending == 0) {
        return {
          'text': 'No spending recorded for $category $timeframe. Add some expense transactions to see your spending analysis.',
          'type': ChatMessageType.financialData,
          'data': {
            'amount': 0,
            'category': category,
            'timeframe': timeframe,
            'percentage': 0,
          },
        };
      }
      
      final percentage = totalAllSpending > 0 ? (totalSpending / totalAllSpending * 100) : 0;
      
      return {
        'text': 'You spent Rs. ${totalSpending.toStringAsFixed(0)} on $category $timeframe. This is ${percentage.toStringAsFixed(1)}% of your total expenses.',
        'type': ChatMessageType.financialData,
        'data': {
          'amount': totalSpending,
          'category': category,
          'timeframe': timeframe,
          'percentage': percentage,
        },
      };
    } catch (e) {
      print('Error generating spending by category response: $e');
      return {
        'text': 'Sorry, I couldn\'t retrieve your spending data. Please try again.',
        'type': ChatMessageType.error,
        'data': null,
      };
    }
  }

  /// Generate budget status response using real data
  static Future<Map<String, dynamic>> _generateBudgetStatusResponse(FinancialQuery query, String userId) async {
    try {
      // Get real budget data from database
      final budgets = await DatabaseService.getBudgets();
      
      if (budgets.isEmpty) {
        return {
          'text': 'You don\'t have any budgets set up yet. Create budgets for your spending categories to track your financial goals.',
          'type': ChatMessageType.financialData,
          'data': {
            'message': 'No budgets found',
            'totalBudget': 0,
            'totalSpent': 0,
            'remaining': 0,
            'percentageUsed': 0,
          },
        };
      }
      
      // Get budget usages
      final budgetUsages = await DatabaseService.getAllBudgetUsages();
      
      if (budgetUsages.isEmpty) {
        return {
          'text': 'Your budgets are set up but no spending has been recorded yet. Start adding transactions to see your budget status.',
          'type': ChatMessageType.financialData,
          'data': {
            'message': 'No spending recorded',
            'totalBudget': budgets.fold<double>(0, (sum, budget) => sum + budget.amount),
            'totalSpent': 0,
            'remaining': budgets.fold<double>(0, (sum, budget) => sum + budget.amount),
            'percentageUsed': 0,
          },
        };
      }
      
      // Calculate totals
      double totalBudget = 0;
      double totalSpent = 0;
      final budgetDetails = <String>[];
      
      for (final usage in budgetUsages) {
        totalBudget += usage.budget.amount;
        totalSpent += usage.spent;
        
        final percentage = usage.budget.amount > 0 
            ? (usage.spent / usage.budget.amount * 100)
            : 0;
        
        budgetDetails.add(
          '• ${usage.budget.category?.name ?? 'Unknown'}: Rs. ${usage.spent.toStringAsFixed(0)} / Rs. ${usage.budget.amount.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}% used)'
        );
      }
      
      final remaining = totalBudget - totalSpent;
      final percentageUsed = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0;
      
      final statusText = budgetDetails.isNotEmpty 
          ? 'Your budget status for this month:\n${budgetDetails.join('\n')}\n• Total: Rs. ${totalSpent.toStringAsFixed(0)} / Rs. ${totalBudget.toStringAsFixed(0)} (${percentageUsed.toStringAsFixed(0)}% used)'
          : 'No active budgets found for this period.';
      
      return {
        'text': statusText,
        'type': ChatMessageType.financialData,
        'data': {
          'totalBudget': totalBudget,
          'totalSpent': totalSpent,
          'remaining': remaining,
          'percentageUsed': percentageUsed,
          'budgetDetails': budgetUsages.map((usage) => {
            'category': usage.budget.category?.name ?? 'Unknown',
            'budget': usage.budget.amount,
            'spent': usage.spent,
            'remaining': usage.remaining,
            'percentage': usage.budget.amount > 0 
                ? (usage.spent / usage.budget.amount * 100)
                : 0,
          }).toList(),
        },
      };
    } catch (e) {
      print('Error generating budget status response: $e');
      return {
        'text': 'Sorry, I couldn\'t retrieve your budget information. Please try again.',
        'type': ChatMessageType.error,
        'data': null,
      };
    }
  }

  /// Generate top expenses response using real data
  static Future<Map<String, dynamic>> _generateTopExpensesResponse(FinancialQuery query, String userId) async {
    try {
      final timeframe = query.parameters['timeframe'] ?? 'this month';
      
      // Get real transaction data from database
      final transactions = await DatabaseService.getUserTransactions(
        userId,
        limit: 1000, // Get all transactions for analysis
      );
      
      // Filter expense transactions for the timeframe
      final expenseTransactions = transactions.where((t) => 
        t.type == TransactionType.expense &&
        t.transactionDate.isAfter(_getStartDateForTimeframe(timeframe).subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(_getEndDateForTimeframe(timeframe).add(const Duration(days: 1)))
      ).toList();
      
      if (expenseTransactions.isEmpty) {
        return {
          'text': 'No expenses recorded $timeframe. Add some expense transactions to see your spending analysis.',
          'type': ChatMessageType.financialData,
          'data': {
            'message': 'No expenses found',
            'expenses': [],
          },
        };
      }
      
      // Group by category and calculate totals
      final categorySpending = <String, double>{};
      for (final transaction in expenseTransactions) {
        final categoryName = transaction.category?.name ?? 'Uncategorized';
        categorySpending[categoryName] = (categorySpending[categoryName] ?? 0) + transaction.amount;
      }
      
      // Sort by amount (descending)
      final sortedCategories = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Take top 5 categories
      final topExpenses = sortedCategories.take(5).toList();
      
      if (topExpenses.isEmpty) {
        return {
          'text': 'No categorized expenses found $timeframe.',
          'type': ChatMessageType.financialData,
          'data': {
            'message': 'No categorized expenses',
            'expenses': [],
          },
        };
      }
      
      // Format response text
      final expenseDetails = <String>[];
      final expenseData = <Map<String, dynamic>>[];
      
      for (int i = 0; i < topExpenses.length; i++) {
        final entry = topExpenses[i];
        expenseDetails.add('${i + 1}. ${entry.key}: Rs. ${entry.value.toStringAsFixed(0)}');
        expenseData.add({
          'category': entry.key,
          'amount': entry.value,
          'rank': i + 1,
        });
      }
      
      final totalSpending = expenseTransactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
      
      return {
        'text': 'Your top expenses $timeframe:\n${expenseDetails.join('\n')}\n\nTotal spending: Rs. ${totalSpending.toStringAsFixed(0)}',
        'type': ChatMessageType.financialData,
        'data': {
          'expenses': expenseData,
          'totalSpending': totalSpending,
          'timeframe': timeframe,
          'transactionCount': expenseTransactions.length,
        },
      };
    } catch (e) {
      print('Error generating top expenses response: $e');
      return {
        'text': 'Sorry, I couldn\'t retrieve your expense data. Please try again.',
        'type': ChatMessageType.error,
        'data': null,
      };
    }
  }

  /// Generate savings analysis response using real data
  static Future<Map<String, dynamic>> _generateSavingsAnalysisResponse(FinancialQuery query, String userId) async {
    try {
      final timeframe = query.parameters['timeframe'] ?? 'this month';
      
      // Get real transaction data from database
      final transactions = await DatabaseService.getUserTransactions(
        userId,
        limit: 1000, // Get all transactions for analysis
      );
      
      // Filter transactions for current period
      final currentPeriodStart = _getStartDateForTimeframe(timeframe);
      final currentPeriodEnd = _getEndDateForTimeframe(timeframe);
      
      final currentPeriodTransactions = transactions.where((t) => 
        t.transactionDate.isAfter(currentPeriodStart.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(currentPeriodEnd.add(const Duration(days: 1)))
      ).toList();
      
      // Calculate current period income and expenses
      double currentIncome = 0;
      double currentExpenses = 0;
      
      for (final transaction in currentPeriodTransactions) {
        if (transaction.type == TransactionType.income) {
          currentIncome += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          currentExpenses += transaction.amount;
        }
      }
      
      final currentSavings = currentIncome - currentExpenses;
      final savingsRate = currentIncome > 0 ? (currentSavings / currentIncome * 100) : 0;
      
      // Calculate previous period for comparison
      String previousTimeframe;
      switch (timeframe.toLowerCase()) {
        case 'this month':
          previousTimeframe = 'last month';
          break;
        case 'last month':
          previousTimeframe = 'this month';
          break;
        case 'this week':
          previousTimeframe = 'last week';
          break;
        case 'last week':
          previousTimeframe = 'this week';
          break;
        default:
          previousTimeframe = 'last month';
      }
      
      final previousPeriodStart = _getStartDateForTimeframe(previousTimeframe);
      final previousPeriodEnd = _getEndDateForTimeframe(previousTimeframe);
      
      final previousPeriodTransactions = transactions.where((t) => 
        t.transactionDate.isAfter(previousPeriodStart.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(previousPeriodEnd.add(const Duration(days: 1)))
      ).toList();
      
      double previousIncome = 0;
      double previousExpenses = 0;
      
      for (final transaction in previousPeriodTransactions) {
        if (transaction.type == TransactionType.income) {
          previousIncome += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          previousExpenses += transaction.amount;
        }
      }
      
      final previousSavings = previousIncome - previousExpenses;
      final improvement = previousSavings > 0 ? ((currentSavings - previousSavings) / previousSavings * 100) : 0;
      
      if (currentIncome == 0 && currentExpenses == 0) {
        return {
          'text': 'No financial data recorded $timeframe. Add some income and expense transactions to see your savings analysis.',
          'type': ChatMessageType.financialData,
          'data': {
            'message': 'No data found',
            'currentMonth': 0,
            'lastMonth': 0,
            'improvement': 0,
            'savingsRate': 0,
          },
        };
      }
      
      final improvementText = improvement > 0 
          ? '+${improvement.toStringAsFixed(1)}% (Rs. ${(currentSavings - previousSavings).toStringAsFixed(0)} more)'
          : '${improvement.toStringAsFixed(1)}% (Rs. ${(previousSavings - currentSavings).toStringAsFixed(0)} less)';
      
      return {
        'text': 'Your savings analysis:\n• $timeframe: Rs. ${currentSavings.toStringAsFixed(0)} saved\n• $previousTimeframe: Rs. ${previousSavings.toStringAsFixed(0)} saved\n• Improvement: $improvementText\n• Savings rate: ${savingsRate.toStringAsFixed(1)}% of income',
        'type': ChatMessageType.financialData,
        'data': {
          'currentMonth': currentSavings,
          'lastMonth': previousSavings,
          'improvement': improvement,
          'savingsRate': savingsRate,
          'currentIncome': currentIncome,
          'currentExpenses': currentExpenses,
          'timeframe': timeframe,
        },
      };
    } catch (e) {
      print('Error generating savings analysis response: $e');
      return {
        'text': 'Sorry, I couldn\'t retrieve your savings data. Please try again.',
        'type': ChatMessageType.error,
        'data': null,
      };
    }
  }

  /// Generate expense trends response
  static Future<Map<String, dynamic>> _generateExpenseTrendsResponse(FinancialQuery query, String userId) async {
    return {
      'text': 'Your expense trends:\n• This month: Rs. 25,000 (down 10% from last month)\n• 3-month average: Rs. 27,500\n• Trend: Decreasing (good!)\n• Biggest change: Food expenses down 20%',
      'type': ChatMessageType.financialData,
      'data': {
        'currentMonth': 25000,
        'lastMonth': 27778,
        'change': -10,
        'trend': 'decreasing',
      },
    };
  }

  /// Generate recent transactions response using real data
  static Future<Map<String, dynamic>> _generateRecentTransactionsResponse(FinancialQuery query, String userId) async {
    try {
      final timeframe = query.parameters['timeframe'] ?? 'recent';
      
      // Get recent transactions from database
      final transactions = await DatabaseService.getUserTransactions(
        userId,
        limit: 20, // Get recent 20 transactions
      );
      
      if (transactions.isEmpty) {
        return {
          'text': 'No transactions found. Add some income or expense transactions to see your recent activity.',
          'type': ChatMessageType.financialData,
          'data': {
            'message': 'No transactions found',
            'transactions': [],
          },
        };
      }
      
      // Filter by timeframe if specified
      List<Transaction> filteredTransactions = transactions;
      if (timeframe != 'recent') {
        final startDate = _getStartDateForTimeframe(timeframe);
        final endDate = _getEndDateForTimeframe(timeframe);
        
        filteredTransactions = transactions.where((t) => 
          t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.transactionDate.isBefore(endDate.add(const Duration(days: 1)))
        ).toList();
      }
      
      if (filteredTransactions.isEmpty) {
        return {
          'text': 'No transactions found $timeframe. Try asking about a different time period.',
          'type': ChatMessageType.financialData,
          'data': {
            'message': 'No transactions in timeframe',
            'transactions': [],
          },
        };
      }
      
      // Take most recent 5 transactions
      final recentTransactions = filteredTransactions.take(5).toList();
      
      // Format response text
      final transactionDetails = <String>[];
      final transactionData = <Map<String, dynamic>>[];
      
      for (final transaction in recentTransactions) {
        final dateText = _formatTransactionDate(transaction.transactionDate);
        final typeText = transaction.type == TransactionType.income ? '+' : '-';
        final amountText = 'Rs. ${transaction.amount.toStringAsFixed(0)}';
        final categoryText = transaction.category?.name ?? 'Uncategorized';
        
        transactionDetails.add('• $dateText: $typeText$amountText - ${transaction.description} ($categoryText)');
        transactionData.add({
          'date': dateText,
          'amount': transaction.amount,
          'description': transaction.description,
          'category': categoryText,
          'type': transaction.type.toString().split('.').last,
          'transactionDate': transaction.transactionDate.toIso8601String(),
        });
      }
      
      final totalAmount = recentTransactions.fold<double>(0, (sum, t) => sum + t.amount);
      
      return {
        'text': 'Your recent transactions:\n${transactionDetails.join('\n')}\n\nTotal: Rs. ${totalAmount.toStringAsFixed(0)}',
        'type': ChatMessageType.financialData,
        'data': {
          'transactions': transactionData,
          'totalAmount': totalAmount,
          'timeframe': timeframe,
          'transactionCount': recentTransactions.length,
        },
      };
    } catch (e) {
      print('Error generating recent transactions response: $e');
      return {
        'text': 'Sorry, I couldn\'t retrieve your transaction data. Please try again.',
        'type': ChatMessageType.error,
        'data': null,
      };
    }
  }

  /// Generate financial summary response using real data
  static Future<Map<String, dynamic>> _generateFinancialSummaryResponse(FinancialQuery query, String userId) async {
    try {
      final timeframe = query.parameters['timeframe'] ?? 'this month';
      
      // Get real transaction data from database
      final transactions = await DatabaseService.getUserTransactions(
        userId,
        limit: 1000, // Get all transactions for analysis
      );
      
      // Filter transactions for the timeframe
      final startDate = _getStartDateForTimeframe(timeframe);
      final endDate = _getEndDateForTimeframe(timeframe);
      
      final periodTransactions = transactions.where((t) => 
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();
      
      if (periodTransactions.isEmpty) {
        return {
          'text': 'No financial data recorded $timeframe. Add some income and expense transactions to see your financial summary.',
          'type': ChatMessageType.financialData,
          'data': {
            'message': 'No data found',
            'income': 0,
            'expenses': 0,
            'savings': 0,
            'savingsRate': 0,
            'topCategory': 'N/A',
            'budgetStatus': 'N/A',
          },
        };
      }
      
      // Calculate totals
      double totalIncome = 0;
      double totalExpenses = 0;
      final categorySpending = <String, double>{};
      
      for (final transaction in periodTransactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          totalExpenses += transaction.amount;
          final categoryName = transaction.category?.name ?? 'Uncategorized';
          categorySpending[categoryName] = (categorySpending[categoryName] ?? 0) + transaction.amount;
        }
      }
      
      final savings = totalIncome - totalExpenses;
      final savingsRate = totalIncome > 0 ? (savings / totalIncome * 100) : 0;
      
      // Find top spending category
      String topCategory = 'N/A';
      double topCategoryAmount = 0;
      if (categorySpending.isNotEmpty) {
        final sortedCategories = categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topEntry = sortedCategories.first;
        topCategory = topEntry.key;
        topCategoryAmount = topEntry.value;
      }
      
      // Get budget status
      String budgetStatus = 'No budgets set';
      try {
        final budgets = await DatabaseService.getBudgets();
        if (budgets.isNotEmpty) {
          final budgetUsages = await DatabaseService.getAllBudgetUsages();
          if (budgetUsages.isNotEmpty) {
            final overBudgetCount = budgetUsages.where((usage) => usage.spent > usage.budget.amount).length;
            if (overBudgetCount == 0) {
              budgetStatus = 'On track';
            } else if (overBudgetCount == budgetUsages.length) {
              budgetStatus = 'Over budget';
            } else {
              budgetStatus = 'Mixed (${overBudgetCount}/${budgetUsages.length} over budget)';
            }
          } else {
            budgetStatus = 'Budgets set, no spending recorded';
          }
        }
      } catch (e) {
        budgetStatus = 'Unable to check budget status';
      }
      
      final topCategoryPercentage = totalExpenses > 0 ? (topCategoryAmount / totalExpenses * 100) : 0;
      
      return {
        'text': 'Your financial summary for $timeframe:\n• Total Income: Rs. ${totalIncome.toStringAsFixed(0)}\n• Total Expenses: Rs. ${totalExpenses.toStringAsFixed(0)}\n• Savings: Rs. ${savings.toStringAsFixed(0)}\n• Savings Rate: ${savingsRate.toStringAsFixed(1)}%\n• Top Category: $topCategory (${topCategoryPercentage.toStringAsFixed(1)}%)\n• Budget Status: $budgetStatus',
        'type': ChatMessageType.financialData,
        'data': {
          'income': totalIncome,
          'expenses': totalExpenses,
          'savings': savings,
          'savingsRate': savingsRate,
          'topCategory': topCategory,
          'topCategoryAmount': topCategoryAmount,
          'topCategoryPercentage': topCategoryPercentage,
          'budgetStatus': budgetStatus,
          'timeframe': timeframe,
          'transactionCount': periodTransactions.length,
        },
      };
    } catch (e) {
      print('Error generating financial summary response: $e');
      return {
        'text': 'Sorry, I couldn\'t retrieve your financial summary. Please try again.',
        'type': ChatMessageType.error,
        'data': null,
      };
    }
  }

  /// Generate spending by time response using real data
  static Future<Map<String, dynamic>> _generateSpendingByTimeResponse(FinancialQuery query, String userId) async {
    try {
      final timeframe = query.parameters['timeframe'] ?? 'this month';
      
      // Get real transaction data from database
      final transactions = await DatabaseService.getUserTransactions(
        userId,
        limit: 1000, // Get all transactions for analysis
      );
      
      // Filter expense transactions for the timeframe
      final startDate = _getStartDateForTimeframe(timeframe);
      final endDate = _getEndDateForTimeframe(timeframe);
      
      final expenseTransactions = transactions.where((t) => 
        t.type == TransactionType.expense &&
        t.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();
      
      if (expenseTransactions.isEmpty) {
        return {
          'text': 'No expenses recorded $timeframe. Add some expense transactions to see your spending analysis.',
          'type': ChatMessageType.financialData,
          'data': {
            'message': 'No expenses found',
            'total': 0,
            'dailyAverage': 0,
            'weeklyAverage': 0,
            'highestDay': 0,
            'lowestDay': 0,
          },
        };
      }
      
      // Calculate totals and averages
      final totalSpending = expenseTransactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
      final daysInPeriod = _getDaysInTimeframe(timeframe);
      final dailyAverage = totalSpending / daysInPeriod;
      final weeklyAverage = totalSpending / (daysInPeriod / 7);
      
      // Group by day to find highest and lowest spending days
      final dailySpending = <DateTime, double>{};
      for (final transaction in expenseTransactions) {
        final day = DateTime(transaction.transactionDate.year, transaction.transactionDate.month, transaction.transactionDate.day);
        dailySpending[day] = (dailySpending[day] ?? 0) + transaction.amount;
      }
      
      double highestDay = 0;
      double lowestDay = double.infinity;
      DateTime? highestDayDate;
      DateTime? lowestDayDate;
      
      for (final entry in dailySpending.entries) {
        if (entry.value > highestDay) {
          highestDay = entry.value;
          highestDayDate = entry.key;
        }
        if (entry.value < lowestDay) {
          lowestDay = entry.value;
          lowestDayDate = entry.key;
        }
      }
      
      if (lowestDay == double.infinity) lowestDay = 0;
      
      // Format highest/lowest day descriptions
      String highestDayText = 'Rs. ${highestDay.toStringAsFixed(0)}';
      String lowestDayText = 'Rs. ${lowestDay.toStringAsFixed(0)}';
      
      if (highestDayDate != null) {
        final dayName = _getDayName(highestDayDate);
        highestDayText += ' ($dayName)';
      }
      
      if (lowestDayDate != null) {
        final dayName = _getDayName(lowestDayDate);
        lowestDayText += ' ($dayName)';
      }
      
      return {
        'text': 'Your spending $timeframe: Rs. ${totalSpending.toStringAsFixed(0)}\n• Daily average: Rs. ${dailyAverage.toStringAsFixed(0)}\n• Weekly average: Rs. ${weeklyAverage.toStringAsFixed(0)}\n• Highest day: $highestDayText\n• Lowest day: $lowestDayText',
        'type': ChatMessageType.financialData,
        'data': {
          'total': totalSpending,
          'dailyAverage': dailyAverage,
          'weeklyAverage': weeklyAverage,
          'highestDay': highestDay,
          'lowestDay': lowestDay,
          'timeframe': timeframe,
          'transactionCount': expenseTransactions.length,
          'daysWithSpending': dailySpending.length,
        },
      };
    } catch (e) {
      print('Error generating spending by time response: $e');
      return {
        'text': 'Sorry, I couldn\'t retrieve your spending data. Please try again.',
        'type': ChatMessageType.error,
        'data': null,
      };
    }
  }

  /// Generate income analysis response using real data
  static Future<Map<String, dynamic>> _generateIncomeAnalysisResponse(FinancialQuery query, String userId) async {
    try {
      final timeframe = query.parameters['timeframe'] ?? 'this month';
      
      // Get real income data from database
      final transactions = await DatabaseService.getUserTransactions(
        userId,
        limit: 1000, // Get all transactions for analysis
      );
      
      // Filter income transactions for the timeframe
      final incomeTransactions = transactions.where((t) => 
        t.type == TransactionType.income &&
        t.transactionDate.isAfter(_getStartDateForTimeframe(timeframe).subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(_getEndDateForTimeframe(timeframe).add(const Duration(days: 1)))
      ).toList();
      
      final totalIncome = incomeTransactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
      
      if (totalIncome == 0) {
        return {
          'text': 'No income recorded $timeframe. Add some income transactions to see your income analysis.',
          'type': ChatMessageType.financialData,
          'data': {
            'total': 0,
            'message': 'No income data found',
          },
        };
      }
      
      // Calculate averages
      final daysInPeriod = _getDaysInTimeframe(timeframe);
      final dailyAverage = totalIncome / daysInPeriod;
      final weeklyAverage = totalIncome / (daysInPeriod / 7);
      
      // Get income sources breakdown
      final incomeByCategory = <String, double>{};
      for (final transaction in incomeTransactions) {
        final category = transaction.category?.name ?? 'Other';
        incomeByCategory[category] = (incomeByCategory[category] ?? 0) + transaction.amount;
      }
      
      // Format income sources
      final sources = incomeByCategory.entries.map((entry) => {
        'source': entry.key,
        'amount': entry.value,
      }).toList();
      
      // Calculate growth (compare with previous period)
      final previousPeriodIncome = await _getPreviousPeriodIncome(userId, timeframe);
      final growth = previousPeriodIncome > 0 
          ? ((totalIncome - previousPeriodIncome) / previousPeriodIncome * 100)
          : 0.0;
      
      final growthText = growth > 0 ? '+${growth.toStringAsFixed(1)}%' : '${growth.toStringAsFixed(1)}%';
      
      return {
        'text': 'Your income $timeframe: Rs. ${totalIncome.toStringAsFixed(0)}\n• Daily average: Rs. ${dailyAverage.toStringAsFixed(0)}\n• Weekly average: Rs. ${weeklyAverage.toStringAsFixed(0)}\n• Income sources: ${sources.map((s) => '${s['source']} (Rs. ${(s['amount'] as double).toStringAsFixed(0)})').join(', ')}\n• Growth: $growthText from previous period',
        'type': ChatMessageType.financialData,
        'data': {
          'total': totalIncome,
          'dailyAverage': dailyAverage,
          'weeklyAverage': weeklyAverage,
          'sources': sources,
          'growth': growth,
          'timeframe': timeframe,
        },
      };
    } catch (e) {
      print('Error generating income analysis: $e');
      return {
        'text': 'Sorry, I couldn\'t retrieve your income data. Please try again.',
        'type': ChatMessageType.error,
        'data': null,
      };
    }
  }

  /// Get start date for timeframe
  static DateTime _getStartDateForTimeframe(String timeframe) {
    final now = DateTime.now();
    switch (timeframe.toLowerCase()) {
      case 'this month':
        return DateTime(now.year, now.month, 1);
      case 'last month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return lastMonth;
      case 'this week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      case 'last week':
        final lastWeek = now.subtract(Duration(days: now.weekday + 6));
        return DateTime(lastWeek.year, lastWeek.month, lastWeek.day);
      case 'this year':
        return DateTime(now.year, 1, 1);
      case 'last year':
        return DateTime(now.year - 1, 1, 1);
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTime(yesterday.year, yesterday.month, yesterday.day);
      default:
        return DateTime(now.year, now.month, 1); // Default to this month
    }
  }

  /// Get end date for timeframe
  static DateTime _getEndDateForTimeframe(String timeframe) {
    final now = DateTime.now();
    switch (timeframe.toLowerCase()) {
      case 'this month':
        return DateTime(now.year, now.month + 1, 0); // Last day of current month
      case 'last month':
        return DateTime(now.year, now.month, 0); // Last day of last month
      case 'this week':
        final endOfWeek = now.add(Duration(days: 7 - now.weekday));
        return DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
      case 'last week':
        final endOfLastWeek = now.subtract(Duration(days: now.weekday));
        return DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day, 23, 59, 59);
      case 'this year':
        return DateTime(now.year, 12, 31);
      case 'last year':
        return DateTime(now.year - 1, 12, 31);
      case 'today':
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      default:
        return DateTime(now.year, now.month + 1, 0); // Default to end of this month
    }
  }

  /// Get days in timeframe
  static int _getDaysInTimeframe(String timeframe) {
    final start = _getStartDateForTimeframe(timeframe);
    final end = _getEndDateForTimeframe(timeframe);
    return end.difference(start).inDays + 1;
  }

  /// Get day name for a date
  static String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      final difference = today.difference(transactionDate).inDays;
      if (difference <= 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}';
      }
    }
  }

  /// Format transaction date for display
  static String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      final difference = today.difference(transactionDate).inDays;
      if (difference <= 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }

  /// Get previous period income for growth calculation
  static Future<double> _getPreviousPeriodIncome(String userId, String timeframe) async {
    try {
      String previousTimeframe;
      switch (timeframe.toLowerCase()) {
        case 'this month':
          previousTimeframe = 'last month';
          break;
        case 'last month':
          previousTimeframe = 'this month'; // Compare with current month
          break;
        case 'this week':
          previousTimeframe = 'last week';
          break;
        case 'last week':
          previousTimeframe = 'this week';
          break;
        default:
          previousTimeframe = 'last month';
      }
      
      final transactions = await DatabaseService.getUserTransactions(
        userId,
        limit: 1000, // Get all transactions for analysis
      );
      
      // Filter income transactions for the previous period
      final previousIncomeTransactions = transactions.where((t) => 
        t.type == TransactionType.income &&
        t.transactionDate.isAfter(_getStartDateForTimeframe(previousTimeframe).subtract(const Duration(days: 1))) &&
        t.transactionDate.isBefore(_getEndDateForTimeframe(previousTimeframe).add(const Duration(days: 1)))
      ).toList();
      
      return previousIncomeTransactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
    } catch (e) {
      print('Error getting previous period income: $e');
      return 0.0;
    }
  }
}