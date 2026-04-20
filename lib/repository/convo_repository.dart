import 'dart:convert';
import 'dart:developer';

import 'package:dextera/core/api_endpoint.dart' as api;
import 'package:dextera/models/local_conversation.dart';
import 'package:dextera/utils/token_store.dart';
import 'package:http/http.dart' as http;

class ConvoRepository {
  Map<String, String> _headers() {
    final token = TokenStore.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<LocalConversation>> fetchAll() async {
    try {
      final headers = _headers();
      log('Fetching conversations from: ${api.convo}');
      log('Headers: ${headers.keys.join(", ")}');

      final response = await http
          .get(Uri.parse(api.convo), headers: headers)
          .timeout(const Duration(seconds: 15));

      log('fetchAll Response: ${response.statusCode}');

      if (response.body.isEmpty) {
        log('Error: Empty response body');
        return [];
      }

      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && (jsonMap['status'] == true)) {
        final data = (jsonMap['data'] as List<dynamic>? ?? []);
        return data
            .map((e) => LocalConversation.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final errorMsg =
          jsonMap['message'] ?? 'Server error (${response.statusCode})';
      log('API Error in fetchAll: $errorMsg');
      throw Exception(errorMsg);
    } on FormatException catch (e) {
      log('JSON parse error in fetchAll: $e');
      log('Raw body: ${api.convo}');
      return [];
    } catch (e, stack) {
      log('Unexpected error in fetchAll: $e');
      log(stack.toString());
      if (e.toString().contains('Cannot send Null')) {
        return [];
      }
      rethrow;
    }
  }

  Future<LocalConversation> create({required String title}) async {
    try {
      final body = jsonEncode({'title': title});
      final headers = _headers();

      log('Creating conversation at: ${api.convoCreate}');

      final response = await http
          .post(Uri.parse(api.convoCreate), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.body.isEmpty) {
        log('Error: Empty response body from server');
        throw Exception('Server returned empty response');
      }

      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && (jsonMap['status'] == true)) {
        return LocalConversation.fromJson(
          jsonMap['data'] as Map<String, dynamic>,
        );
      }

      final errorMsg =
          jsonMap['message'] ??
          'Failed to create conversation (${response.statusCode})';
      log('API Error in create: $errorMsg');
      throw Exception(errorMsg);
    } on FormatException catch (e) {
      log('JSON parse error in create: $e');
      throw Exception('Invalid server response format');
    } catch (e, stack) {
      log('Unexpected error in create: $e');
      log(stack.toString());
      if (e.toString().contains('Cannot send Null')) {
        throw Exception('Network error: Invalid request');
      }
      rethrow;
    }
  }

  Future<void> delete({required String conversationId}) async {
    try {
      final body = jsonEncode({'conversationId': conversationId});
      final headers = _headers();

      log('Deleting conversation at: ${api.convoDelete}');

      final response = await http
          .delete(Uri.parse(api.convoDelete), headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.body.isEmpty) {
        log('Error: Empty response body from server');
        throw Exception('Server returned empty response');
      }

      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && (jsonMap['status'] == true)) {
        return;
      }

      final errorMsg =
          jsonMap['message'] ??
          'Failed to delete conversation (${response.statusCode})';
      log('API Error in delete: $errorMsg');
      throw Exception(errorMsg);
    } on FormatException catch (e) {
      log('JSON parse error in delete: $e');
      throw Exception('Invalid server response format');
    } catch (e, stack) {
      log('Unexpected error in delete: $e');
      log(stack.toString());
      if (e.toString().contains('Cannot send Null')) {
        throw Exception('Network error: Invalid request');
      }
      rethrow;
    }
  }
}
