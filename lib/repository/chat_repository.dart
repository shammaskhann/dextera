import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatRepository {
  // Streams word/phrase chunks from the chat endpoint (SSE-style "data:" lines).
  Stream<String> streamChat(String message) async* {
    final uri = Uri.parse(
      'https://8000-01ke9hsffzevnjzywv4gx41ax2.cloudspaces.litng.ai/api/v1/chat',
    );

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      })
      ..body = jsonEncode({'message': message});

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
}
