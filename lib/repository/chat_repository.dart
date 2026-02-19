import 'dart:async';
import 'dart:convert';

import 'package:dextera/models/conversation.dart';
import 'package:http/http.dart' as http;

class ChatRepository {
  static const String _baseUrl =
      'https://8000-01ke9hsffzevnjzywv4gx41ax2.cloudspaces.litng.ai';

  /// Streams word/phrase chunks from the chat endpoint (SSE-style "data:" lines).
  /// NOTE: The parsing/structuring of the SSE stream is intentionally left unchanged.
  Stream<String> streamChat(
    String message, {
    required String conversationId,
    bool useRag = true,
  }) async* {
    final uri = Uri.parse('$_baseUrl/api/v1/chat');

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      })
      ..body = jsonEncode({
        'message': message,
        'conversation_id': conversationId,
        'use_rag': useRag,
      });

    final response = await request.send();

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Chat request failed (${response.statusCode}): $body');
    }

    // Parse line-by-line SSE chunks. Only forward lines starting with "data:".
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.isEmpty) continue;
      if (!line.startsWith('data:')) continue;

      final data = line.substring(5).trimLeft();
      if (data.isEmpty) continue;
      if (data.toLowerCase() == '[done]') break;

      yield data;
    }
  }

  /// Fetch full conversation history for a given conversation id.
  Future<ConversationHistory> fetchConversation(String conversationId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/conversation/$conversationId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return ConversationHistory.fromJson(jsonMap);
    } else if (response.statusCode == 404) {
      throw Exception('Conversation not found');
    } else {
      throw Exception(
        'Failed to load conversation (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Delete a conversation by id.
  Future<void> deleteConversation(String conversationId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/conversation/$conversationId');
    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Conversation not found');
    } else {
      throw Exception(
        'Failed to delete conversation (${response.statusCode}): ${response.body}',
      );
    }
  }
}
