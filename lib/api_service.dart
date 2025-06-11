import 'package:http/http.dart' as http;
import 'dart:convert';

class JKUATAssistant {
  static final baseUrl = "";

  Future<String> askQuestion(String question) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'question': question,
          'chat_history': [], // Include empty chat history for now
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['answer'];
      } else {
        throw Exception('Failed to get answer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the assistant: $e');
    }
  }
}