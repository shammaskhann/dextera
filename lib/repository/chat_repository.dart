import 'dart:async';
import 'dart:convert';

import 'package:dextera/models/conversation.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
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
    String? documentContext,
  }) async* {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/chat');

      final bodyData = {
        'message': message,
        'conversation_id': conversationId,
        'use_rag': useRag,
        if (documentContext != null) 'document_context': documentContext,
      };

      final bodyString = jsonEncode(bodyData);
      if (bodyString.isEmpty) {
        throw Exception('Request body cannot be empty');
      }

      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = bodyString;

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
        
        if (line.startsWith('data: ')) {
          String token = line.replaceFirst('data: ', '');
          if (token.toLowerCase() == '[done]') break;
          // If token is empty but the line had 'data: ', it might have been 'data:  ' 
          // However, replaceFirst will leave the remaining characters untouched.
          yield token;
        } else if (line.startsWith('data:')) {
          // Handle cases where the backend sends 'data:' without a space
          String token = line.replaceFirst('data:', '');
          if (token.toLowerCase() == '[done]') break;
          yield token;
        }
      }
    } catch (e) {
      // Silently handle null body errors from debug service
      if (e.toString().contains('Cannot send Null')) {
        return; // Exit stream gracefully without yielding
      }
      rethrow; // Re-throw other exceptions
    }
  }

  /// Fetch full conversation history for a given conversation id.
  Future<ConversationHistory> fetchConversation(String conversationId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/conversation/$conversationId');
      final response = await http.get(uri);

      if (response.body.isEmpty) {
        throw Exception('Server returned empty response');
      }

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
    } on FormatException catch (e) {
      throw Exception('Invalid server response format: $e');
    } catch (e) {
      if (e.toString().contains('Cannot send Null')) {
        throw Exception('Network error: Request failed');
      }
      rethrow;
    }
  }

  /// Delete a conversation by id.
  Future<void> deleteConversation(String conversationId) async {
    try {
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
    } catch (e) {
      if (e.toString().contains('Cannot send Null')) {
        return; // Silently handle the error
      }
      rethrow;
    }
  }

  /// Uploads a PDF to be summarized.
  Future<Map<String, dynamic>> summarizePdf(
    String conversationId,
    PlatformFile file,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/v1/summarize?conversation_id=$conversationId');
    final request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
        );
      } else if (file.readStream != null) {
        request.files.add(
          http.MultipartFile(
            'file',
            file.readStream!,
            file.size,
            filename: file.name,
          ),
        );
      } else {
        throw Exception('File bytes and readStream are null on Web');
      }
    } else {
      if (file.path == null) throw Exception('File path is null on non-Web platform');
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path!),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;
      return jsonMap;
    } else {
      throw Exception('PDF upload failed (${response.statusCode}): $responseBody');
    }
  }
}

