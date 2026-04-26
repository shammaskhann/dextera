/// Represents a single chat message in the conversation UI.
class ChatMessage {
  String text;
  final bool isUser;
  final String messageType; // 'text', 'document_summary', 'loading'
  final String? documentName;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.messageType = 'text',
    this.documentName,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Classify the message type for rendering purposes.
  /// Priority: type check → role check → default.
  MessageDisplayType get displayType {
    if (messageType == 'document_summary') {
      return MessageDisplayType.documentSummary;
    }
    if (messageType == 'loading') {
      return MessageDisplayType.loading;
    }
    if (isUser) {
      return MessageDisplayType.user;
    }
    return MessageDisplayType.assistant;
  }
}

/// Enum for message rendering classification.
enum MessageDisplayType {
  user,
  assistant,
  documentSummary,
  loading,
}
