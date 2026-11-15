import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/ai_message.dart';
import '../../core/models/project.dart';
import '../../core/storage/secure_storage.dart';

class AiAssistantService {
  static Future<String> sendMessage({
    required AiProviderType provider,
    required String prompt,
    Project? projectContext,
    String? customApiKey,
  }) async {
    final secureStorage = SecureStorageService();
    final apiKey = customApiKey ?? await secureStorage.read('ai_key_${provider.name}') ?? '';

    if (apiKey.isEmpty && provider != AiProviderType.ollama) {
      return 'Please configure your API key for ${provider.displayName} in Settings or the AI tab.';
    }

    // Build project context header
    final contextBuffer = StringBuffer();
    if (projectContext != null) {
      contextBuffer.writeln('--- Project Context ---');
      contextBuffer.writeln('Name: ${projectContext.name}');
      contextBuffer.writeln('Tech: ${projectContext.techStack.language.displayName} (${projectContext.techStack.framework.displayName})');
      contextBuffer.writeln('Port: ${projectContext.port}');
      contextBuffer.writeln('Path: ${projectContext.localPath}');
      if (projectContext.lastError != null) {
        contextBuffer.writeln('Recent Error: ${projectContext.lastError}');
      }
      contextBuffer.writeln('-----------------------\n');
    }

    final fullPrompt = '$contextBuffer$prompt';

    try {
      switch (provider) {
        case AiProviderType.gemini:
          return await _callGemini(apiKey, fullPrompt);
        case AiProviderType.openai:
          return await _callOpenAi(apiKey, fullPrompt);
        case AiProviderType.anthropic:
          return await _callAnthropic(apiKey, fullPrompt);
        case AiProviderType.openrouter:
          return await _callOpenRouter(apiKey, fullPrompt);
        case AiProviderType.ollama:
          return await _callOllama(fullPrompt);
      }
    } catch (e) {
      return 'Error querying ${provider.displayName}: $e';
    }
  }

  static Future<String> _callGemini(String apiKey, String prompt) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final text = json['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } else {
      throw Exception('Gemini API returned status ${response.statusCode}: ${response.body}');
    }
  }

  static Future<String> _callOpenAi(String apiKey, String prompt) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': 'You are an expert DevOps engineer and code troubleshooter assisting with GitHub projects.'},
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['choices'][0]['message']['content'];
    } else {
      throw Exception('OpenAI API returned status ${response.statusCode}: ${response.body}');
    }
  }

  static Future<String> _callAnthropic(String apiKey, String prompt) async {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-5-haiku-20241022',
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['content'][0]['text'];
    } else {
      throw Exception('Anthropic API returned status ${response.statusCode}: ${response.body}');
    }
  }

  static Future<String> _callOpenRouter(String apiKey, String prompt) async {
    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'meta-llama/llama-3.1-8b-instruct:free',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['choices'][0]['message']['content'];
    } else {
      throw Exception('OpenRouter API returned status ${response.statusCode}: ${response.body}');
    }
  }

  static Future<String> _callOllama(String prompt) async {
    final url = Uri.parse('http://127.0.0.1:11434/api/generate');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': 'llama3.2',
        'prompt': prompt,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['response'];
    } else {
      throw Exception('Ollama returned status ${response.statusCode}. Make sure Ollama is running locally on port 11434.');
    }
  }
}
