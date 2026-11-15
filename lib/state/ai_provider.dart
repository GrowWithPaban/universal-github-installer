import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/models/ai_message.dart';
import '../core/models/project.dart';
import '../services/ai/ai_assistant_service.dart';

class AiProvider extends ChangeNotifier {
  AiProviderType _selectedProvider = AiProviderType.gemini;
  final List<AiMessage> _messages = [];
  bool _isGenerating = false;

  AiProviderType get selectedProvider => _selectedProvider;
  List<AiMessage> get messages => _messages;
  bool get isGenerating => _isGenerating;

  void setProvider(AiProviderType provider) {
    _selectedProvider = provider;
    notifyListeners();
  }

  void clearConversation() {
    _messages.clear();
    notifyListeners();
  }

  Future<void> sendPrompt(String text, {Project? projectContext}) async {
    if (text.trim().isEmpty) return;

    final userMsg = AiMessage(
      id: const Uuid().v4(),
      sender: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isGenerating = true;
    notifyListeners();

    try {
      final reply = await AiAssistantService.sendMessage(
        provider: _selectedProvider,
        prompt: text,
        projectContext: projectContext,
      );

      final assistantMsg = AiMessage(
        id: const Uuid().v4(),
        sender: 'assistant',
        content: reply,
        timestamp: DateTime.now(),
        isCodeExplanation: reply.contains('```'),
      );
      _messages.add(assistantMsg);
    } catch (e) {
      _messages.add(AiMessage(
        id: const Uuid().v4(),
        sender: 'assistant',
        content: 'Error: $e',
        timestamp: DateTime.now(),
      ));
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
