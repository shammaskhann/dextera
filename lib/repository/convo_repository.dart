import 'dart:convert';
import 'dart:developer';

import 'package:dextera/core/api_endpoint.dart' as api;
import 'package:dextera/models/local_conversation.dart';
import 'package:dextera/utils/token_store.dart';
import 'package:http/http.dart' as http;

class ConvoRepository {
  Map<String, String> _headers() {
    final token = TokenStore.token;
    log(token ?? 'No token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<LocalConversation>> fetchAll() async {
    final response = await http.get(Uri.parse(api.convo), headers: _headers());
    log(response.body);
    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && (jsonMap['status'] == true)) {
      final data = (jsonMap['data'] as List<dynamic>? ?? []);
      return data
          .map((e) => LocalConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(jsonMap['message'] ?? 'Failed to fetch conversations');
  }

  Future<LocalConversation> create({required String title}) async {
    final response = await http.post(
      Uri.parse(api.convoCreate),
      headers: _headers(),
      body: jsonEncode({'title': title}),
    );
    log(response.body);
    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && (jsonMap['status'] == true)) {
      return LocalConversation.fromJson(
        jsonMap['data'] as Map<String, dynamic>,
      );
    }

    throw Exception(jsonMap['message'] ?? 'Failed to create conversation');
  }

  Future<void> delete({required String conversationId}) async {
    final response = await http.delete(
      Uri.parse(api.convoDelete),
      headers: _headers(),
      body: jsonEncode({'conversationId': conversationId}),
    );
    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && (jsonMap['status'] == true)) {
      return;
    }

    throw Exception(jsonMap['message'] ?? 'Failed to delete conversation');
  }
}
