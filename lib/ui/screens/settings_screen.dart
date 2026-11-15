import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SecureStorageService _storage = SecureStorageService();

  final TextEditingController _githubTokenController = TextEditingController();
  final TextEditingController _geminiKeyController = TextEditingController();
  final TextEditingController _openaiKeyController = TextEditingController();
  final TextEditingController _anthropicKeyController = TextEditingController();
  final TextEditingController _openrouterKeyController = TextEditingController();

  bool _obscureKeys = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    _githubTokenController.text = await _storage.read('github_token') ?? '';
    _geminiKeyController.text = await _storage.read('ai_key_gemini') ?? '';
    _openaiKeyController.text = await _storage.read('ai_key_openai') ?? '';
    _anthropicKeyController.text = await _storage.read('ai_key_anthropic') ?? '';
    _openrouterKeyController.text = await _storage.read('ai_key_openrouter') ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _saveKeys() async {
    setState(() => _isSaving = true);
    await _storage.write('github_token', _githubTokenController.text.trim());
    await _storage.write('ai_key_gemini', _geminiKeyController.text.trim());
    await _storage.write('ai_key_openai', _openaiKeyController.text.trim());
    await _storage.write('ai_key_anthropic', _anthropicKeyController.text.trim());
    await _storage.write('ai_key_openrouter', _openrouterKeyController.text.trim());

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.successGreen,
          content: Text('✓ Credentials securely saved!'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _githubTokenController.dispose();
    _geminiKeyController.dispose();
    _openaiKeyController.dispose();
    _anthropicKeyController.dispose();
    _openrouterKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    Widget keyField({
      required String label,
      required String hint,
      required TextEditingController controller,
      required IconData icon,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextField(
          controller: controller,
          obscureText: _obscureKeys,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: IconButton(
              icon: Icon(_obscureKeys ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureKeys = !_obscureKeys),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Application Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage GitHub authentication, AI model keys, security preferences, and display options',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 24),

            // Appearance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appearance & Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Dark Theme Mode'),
                      subtitle: const Text('Enable VS Code / Docker Desktop dark theme palette'),
                      value: appState.isDarkMode,
                      onChanged: (_) => appState.toggleTheme(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // GitHub Integration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GitHub Authentication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text(
                      'Provide a Personal Access Token (PAT) to clone private repositories and prevent API rate limiting.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    keyField(
                      label: 'GitHub Personal Access Token (PAT)',
                      hint: 'ghp_...',
                      controller: _githubTokenController,
                      icon: Icons.vpn_key,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // AI Providers Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Assistant Credentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text(
                      'Configure your own API keys. Keys are stored encrypted in local secure storage and never shared.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    keyField(
                      label: 'Google Gemini API Key',
                      hint: 'AIzaSy...',
                      controller: _geminiKeyController,
                      icon: Icons.auto_awesome,
                    ),
                    keyField(
                      label: 'OpenAI API Key',
                      hint: 'sk-...',
                      controller: _openaiKeyController,
                      icon: Icons.bolt,
                    ),
                    keyField(
                      label: 'Anthropic Claude API Key',
                      hint: 'sk-ant-...',
                      controller: _anthropicKeyController,
                      icon: Icons.chat,
                    ),
                    keyField(
                      label: 'OpenRouter API Key',
                      hint: 'sk-or-...',
                      controller: _openrouterKeyController,
                      icon: Icons.alt_route,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
              onPressed: _isSaving ? null : _saveKeys,
            ),
          ],
        ),
      ),
    );
  }
}

