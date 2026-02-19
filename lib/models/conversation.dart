class ConversationMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ConversationMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ConversationHistory {
  final String conversationId;
  final List<ConversationMessage> messages;
  final int messageCount;

  ConversationHistory({
    required this.conversationId,
    required this.messages,
    required this.messageCount,
  });

  factory ConversationHistory.fromJson(Map<String, dynamic> json) {
    final msgs = (json['messages'] as List<dynamic>? ?? [])
        .map((m) => ConversationMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    return ConversationHistory(
      conversationId: json['conversation_id'] ?? '',
      messages: msgs,
      messageCount: json['message_count'] ?? msgs.length,
    );
  }
}

/// Lightweight summary model for displaying conversations in the sidebar.
class ConversationSummary {
  final String id;
  final String title;
  final DateTime? lastUpdated;
  final int messageCount;

  ConversationSummary({
    required this.id,
    required this.title,
    required this.lastUpdated,
    required this.messageCount,
  });

  ConversationSummary copyWith({
    String? id,
    String? title,
    DateTime? lastUpdated,
    int? messageCount,
  }) {
    return ConversationSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}
