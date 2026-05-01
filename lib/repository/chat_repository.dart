import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dextera/models/conversation.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ChatRepository {
  static const String _baseUrl =
      'https://8000-01ke9hsffzevnjzywv4gx41ax2.cloudspaces.litng.ai';

  /// SSE streaming timeout – 10 minutes for complex LLM queries.
  static const Duration _streamTimeout = Duration(minutes: 10);

  /// Streams word/phrase chunks from the chat endpoint (SSE-style "data:" lines).
  ///
  /// The stream yields individual content tokens. Special signals:
  ///  - `[DONE]` → ends the stream
  ///  - `ERROR: <msg>` → throws an exception
  ///  - `--RELEVANT JUDICIAL PRECEDENT--` → yielded as-is for delimiter handling
  ///
  /// An [AbortController]-style timeout of 10 minutes is applied via
  /// [_streamTimeout]. On timeout, the stream ends gracefully with whatever
  /// content has been accumulated.
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

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        // Try to extract 'detail' field from JSON error responses
        String errorMessage;
        try {
          final jsonBody = jsonDecode(body) as Map<String, dynamic>;
          errorMessage = jsonBody['detail']?.toString() ?? body;
        } catch (_) {
          errorMessage = body;
        }
        throw ChatException(
          'Chat request failed (${response.statusCode})',
          detail: errorMessage,
          statusCode: response.statusCode,
        );
      }

      // Parse line-by-line SSE chunks with timeout.
      // Buffer approach: accumulate lines delimited by \n\n frames.
      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .timeout(
                _streamTimeout,
                onTimeout: (sink) {
                  log('SSE stream timed out after $_streamTimeout');
                  sink.close();
                },
              )) {
        String? token;

        if (line.startsWith('data: ')) {
          token = line.replaceFirst('data: ', '');
        } else if (line.startsWith('data:')) {
          // Handle cases where the backend sends 'data:' without a space
          token = line.replaceFirst('data:', '');
        }

        if (token == null) continue;

        // End signal
        if (token.toLowerCase() == '[done]') break;

        // Error signal from backend
        if (token.startsWith('ERROR:')) {
          throw ChatException(
            token.replaceFirst('ERROR:', '').trim(),
            isStreamError: true,
          );
        }

        // Normal token (including delimiters like --RELEVANT JUDICIAL PRECEDENT--)
        yield token;
      }
    } on TimeoutException {
      throw ChatException(
        'Request timed out. Please try again.',
        isTimeout: true,
      );
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
      log("Conversation ID: $conversationId");
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
    final uri = Uri.parse(
      '$_baseUrl/api/v2/summarize?conversation_id=$conversationId',
    );
    final request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
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
      if (file.path == null) {
        throw Exception('File path is null on non-Web platform');
      }
      request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    log("responseBody: $responseBody , statsuCode: ${response.statusCode}");
    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;
      return jsonMap;
    } else {
      // Try to extract 'detail' field
      String errorMessage;
      try {
        final jsonBody = jsonDecode(responseBody) as Map<String, dynamic>;
        errorMessage = jsonBody['detail']?.toString() ?? responseBody;
      } catch (_) {
        errorMessage = responseBody;
      }
      throw ChatException(
        'PDF upload failed (${response.statusCode})',
        detail: errorMessage,
        statusCode: response.statusCode,
      );
    }
  }
}

/// Structured exception for chat-related errors with additional context.
class ChatException implements Exception {
  final String message;
  final String? detail;
  final int? statusCode;
  final bool isTimeout;
  final bool isStreamError;

  ChatException(
    this.message, {
    this.detail,
    this.statusCode,
    this.isTimeout = false,
    this.isStreamError = false,
  });

  /// Returns the most user-friendly error message available.
  String get displayMessage => detail ?? message;

  @override
  String toString() {
    if (detail != null) return '$message: $detail';
    return message;
  }
}
