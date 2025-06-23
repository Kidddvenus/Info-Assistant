import 'package:http/http.dart' as http;
import 'dart:convert';

class JKUATAssistant {
  static final baseUrl = "https://info-assistant-qhctotcy8-reggie-s-projects.vercel.app";
  List<Map<String, String>> _chatHistory = []; // Stores conversation history

  Future<String> askQuestion(String question) async {
    try {
      // Prepare the request with current question and full history
      final response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'question': question,
          'chat_history': _chatHistory,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final String answer = jsonResponse['answer'];

        // Update chat history with new exchange
        _chatHistory.add({'role': 'user', 'content': question});
        _chatHistory.add({'role': 'assistant', 'content': answer});

        return answer;
      } else {
        throw Exception('Failed to get answer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the assistant: $e');
    }
  }

  // Optional: Getter for current chat history
  List<Map<String, String>> get chatHistory => _chatHistory;
}