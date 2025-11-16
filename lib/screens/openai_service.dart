import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String _apiKey = ''; // replace with your actual key

  Future<String?> getMatchingCategory(String userInput, List<String> categories) async {
    final uri = Uri.parse('');

    final prompt = '''
You are a smart AI that matches a user's spoken request to the most relevant category from this list:
${categories.join(", ")}

User said: "$userInput"

Which category best matches? Reply with only the category name.
''';

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {"role": "system", "content": "You are a helpful assistant."},
          {"role": "user", "content": prompt},
        ],
        'max_tokens': 20,
        'temperature': 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['choices'][0]['message']['content'].trim();
      return result;
    } else {
      print("❌ OpenAI API Error: ${response.body}");
      return null;
    }
  }
}
