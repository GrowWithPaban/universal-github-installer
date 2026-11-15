import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/ai_message.dart';
import '../../core/models/project.dart';
import '../../core/theme/app_theme.dart';
import '../../state/ai_provider.dart';
import '../../state/app_state.dart';
import '../../state/projects_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedProjectId;

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitPrompt(AiProvider aiProvider, Project? project) {
    final text = _promptController.text.trim();
    if (text.isEmpty || aiProvider.isGenerating) return;
    _promptController.clear();
    aiProvider.sendPrompt(text, projectContext: project);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final projectsProvider = context.watch<ProjectsProvider>();
    final aiProvider = context.watch<AiProvider>();

    if (_selectedProjectId == null && projectsProvider.projects.isNotEmpty) {
      _selectedProjectId = appState.selectedProjectId ?? projectsProvider.projects.first.id;
    }

    final selectedProject = projectsProvider.getProjectById(_selectedProjectId);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Development Assistant',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Code analysis, bug diagnosis, architecture explanation, and test generation',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                // Provider Selector
                DropdownButton<AiProviderType>(
                  value: aiProvider.selectedProvider,
                  items: AiProviderType.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(p.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) aiProvider.setProvider(val);
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Clear Conversation',
                  onPressed: () => aiProvider.clearConversation(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Project Context Selector Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_special, size: 18, color: AppTheme.accentCyan),
                  const SizedBox(width: 10),
                  const Text('Active Project Context:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  DropdownButton<String?>(
                    value: _selectedProjectId,
                    hint: const Text('None (General Assistant)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None (General Assistant)')),
                      ...projectsProvider.projects.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.name} (${p.techStack.framework.displayName})'),
                          )),
                    ],
                    onChanged: (val) => setState(() => _selectedProjectId = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Quick Prompt Chips
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.architecture, size: 14),
                  label: const Text('Explain Project Architecture'),
                  onPressed: () {
                    aiProvider.sendPrompt(
                      'Explain the architecture, structure, and best practices of this project based on its detected tech stack.',
                      projectContext: selectedProject,
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.bug_report, size: 14),
                  label: const Text('Diagnose Potential Errors / Bugs'),
                  onPressed: () {
                    aiProvider.sendPrompt(
                      'Inspect recent logs or standard error points for this framework and advise on troubleshooting.',
                      projectContext: selectedProject,
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.fact_check, size: 14),
                  label: const Text('Suggest Automated Tests'),
                  onPressed: () {
                    aiProvider.sendPrompt(
                      'Suggest a suite of automated unit and integration tests for this application.',
                      projectContext: selectedProject,
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.security, size: 14),
                  label: const Text('Security Audit Checklist'),
                  onPressed: () {
                    aiProvider.sendPrompt(
                      'Perform a quick security checklist for this tech stack (environment vars, SQL injection, CORS, credentials).',
                      projectContext: selectedProject,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Messages View
            Expanded(
              child: aiProvider.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 48, color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'AI Assistant is Ready',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Select a prompt above or ask any question regarding code, setup, or errors.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: aiProvider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = aiProvider.messages[index];
                        final isUser = msg.sender == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 750),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUser ? AppTheme.primaryBlue : AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(10),
                              border: isUser ? null : Border.all(color: AppTheme.darkBorder),
                            ),
                            child: SelectableText(
                              msg.content,
                              style: TextStyle(
                                color: isUser ? Colors.white : AppTheme.darkTextPrimary,
                                fontSize: 13.5,
                                height: 1.5,
                                fontFamily: msg.isCodeExplanation ? 'monospace' : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (aiProvider.isGenerating) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('AI is thinking...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Prompt Input Box
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      hintText: 'Ask anything about ${selectedProject?.name ?? "your project"}...',
                      prefixIcon: const Icon(Icons.chat_bubble_outline),
                    ),
                    onSubmitted: (_) => _submitPrompt(aiProvider, selectedProject),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Ask'),
                  onPressed: aiProvider.isGenerating
                      ? null
                      : () => _submitPrompt(aiProvider, selectedProject),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

