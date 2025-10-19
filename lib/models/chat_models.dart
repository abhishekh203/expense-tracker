class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;
  final Map<String, dynamic>? data;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = ChatMessageType.text,
    this.data,
  });

  factory ChatMessage.user(String text) {
    return ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );
  }

  factory ChatMessage.assistant(String text, {ChatMessageType type = ChatMessageType.text, Map<String, dynamic>? data}) {
    return ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: type,
      data: data,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp']),
      type: ChatMessageType.values.firstWhere(
        (e) => e.toString() == 'ChatMessageType.${json['type']}',
        orElse: () => ChatMessageType.text,
      ),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'data': data,
    };
  }
}

enum ChatMessageType {
  text,
  financialData,
  chart,
  suggestion,
  error,
}

class FinancialQuery {
  final String originalQuery;
  final String processedQuery;
  final QueryType type;
  final Map<String, dynamic> parameters;
  final double confidence;

  FinancialQuery({
    required this.originalQuery,
    required this.processedQuery,
    required this.type,
    required this.parameters,
    required this.confidence,
  });

  factory FinancialQuery.fromJson(Map<String, dynamic> json) {
    return FinancialQuery(
      originalQuery: json['originalQuery'] as String,
      processedQuery: json['processedQuery'] as String,
      type: QueryType.values.firstWhere(
        (e) => e.toString() == 'QueryType.${json['type']}',
        orElse: () => QueryType.unknown,
      ),
      parameters: json['parameters'] as Map<String, dynamic>,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalQuery': originalQuery,
      'processedQuery': processedQuery,
      'type': type.toString().split('.').last,
      'parameters': parameters,
      'confidence': confidence,
    };
  }
}

enum QueryType {
  spendingByCategory,
  spendingByTime,
  spendingComparison,
  budgetStatus,
  savingsAnalysis,
  expenseTrends,
  topExpenses,
  recentTransactions,
  financialSummary,
  incomeAnalysis,
  unknown,
}

class FinancialInsight {
  final String title;
  final String description;
  final String value;
  final String currency;
  final InsightType type;
  final double confidence;
  final List<String> suggestions;
  final Map<String, dynamic>? chartData;

  FinancialInsight({
    required this.title,
    required this.description,
    required this.value,
    required this.currency,
    required this.type,
    required this.confidence,
    required this.suggestions,
    this.chartData,
  });

  factory FinancialInsight.fromJson(Map<String, dynamic> json) {
    return FinancialInsight(
      title: json['title'] as String,
      description: json['description'] as String,
      value: json['value'] as String,
      currency: json['currency'] as String,
      type: InsightType.values.firstWhere(
        (e) => e.toString() == 'InsightType.${json['type']}',
        orElse: () => InsightType.info,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      suggestions: List<String>.from(json['suggestions'] ?? []),
      chartData: json['chartData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'value': value,
      'currency': currency,
      'type': type.toString().split('.').last,
      'confidence': confidence,
      'suggestions': suggestions,
      'chartData': chartData,
    };
  }
}

enum InsightType {
  info,
  warning,
  success,
  error,
  trend,
}

class ChatSession {
  final String id;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastActivity;
  final String userId;

  ChatSession({
    required this.id,
    required this.messages,
    required this.createdAt,
    required this.lastActivity,
    required this.userId,
  });

  factory ChatSession.newSession(String userId) {
    return ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      messages: [],
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
      userId: userId,
    );
  }

  ChatSession addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(messages)..add(message);
    return ChatSession(
      id: id,
      messages: updatedMessages,
      createdAt: createdAt,
      lastActivity: DateTime.now(),
      userId: userId,
    );
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastActivity: DateTime.parse(json['lastActivity']),
      userId: json['userId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'userId': userId,
    };
  }
}
