enum AiProviderType {
  gemini,
  openai,
  anthropic,
  openrouter,
  ollama;

  String get displayName {
    switch (this) {
      case AiProviderType.gemini:
        return 'Google Gemini';
      case AiProviderType.openai:
        return 'OpenAI ChatGPT';
      case AiProviderType.anthropic:
        return 'Anthropic Claude';
      case AiProviderType.openrouter:
        return 'OpenRouter';
      case AiProviderType.ollama:
        return 'Ollama (Local)';
    }
  }

  String get defaultModel {
    switch (this) {
      case AiProviderType.gemini:
        return 'gemini-1.5-flash';
      case AiProviderType.openai:
        return 'gpt-4o-mini';
      case AiProviderType.anthropic:
        return 'claude-3-5-haiku-20241022';
      case AiProviderType.openrouter:
        return 'meta-llama/llama-3.1-8b-instruct:free';
      case AiProviderType.ollama:
        return 'llama3.2';
    }
  }
}

class AiMessage {
  final String id;
  final String sender; // 'user' or 'assistant' or 'system'
  final String content;
  final DateTime timestamp;
  final bool isCodeExplanation;

  AiMessage({
    required this.id,
    required this.sender,
    required this.content,
    DateTime? timestamp,
    this.isCodeExplanation = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'isCodeExplanation': isCodeExplanation,
  };

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id'] as String,
      sender: json['sender'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isCodeExplanation: json['isCodeExplanation'] as bool? ?? false,
    );
  }
}

