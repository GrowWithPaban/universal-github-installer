import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/installation_plan.dart';
import '../../core/models/process_status.dart';
import '../../core/theme/app_theme.dart';
import '../../services/github/github_service.dart';
import '../../services/github/repo_analyzer.dart';
import '../../state/app_state.dart';
import '../../state/process_provider.dart';
import '../../state/projects_provider.dart';
import '../widgets/command_approval_dialog.dart';
import '../widgets/terminal_view.dart';

class InstallScreen extends StatefulWidget {
  const InstallScreen({super.key});

  @override
  State<InstallScreen> createState() => _InstallScreenState();
}

class _InstallScreenState extends State<InstallScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final List<LogEntry> _screenLogs = [];
  bool _isInstalling = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _addLog(String text, bool isError) {
    if (mounted) {
      setState(() {
        _screenLogs.add(LogEntry(
          timestamp: DateTime.now(),
          text: text,
          isError: isError,
        ));
      });
    }
  }

  Future<void> _startAnalysis() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final projectsProvider = context.read<ProjectsProvider>();
    _screenLogs.clear();

    final parsed = GitHubService.parseUrl(url);
    if (parsed != null && _nameController.text.isEmpty) {
      _nameController.text = parsed.repo;
    }

    await projectsProvider.analyzeRepository(url, onLog: (line, isError) {
      _addLog(line, isError);
    });
  }

  Future<void> _runInstallation(RepoAnalysisResult analysis) async {
    final projectsProvider = context.read<ProjectsProvider>();
    final processProvider = context.read<ProcessProvider>();
    final appState = context.read<AppState>();

    final projectName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Project-${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _isInstalling = true);

    try {
      final project = await projectsProvider.installProject(
        name: projectName,
        githubUrl: _urlController.text.trim(),
        analysis: analysis,
        processProvider: processProvider,
        requestApproval: (InstallationStep step) async {
          return await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => CommandApprovalDialog(step: step),
              ) ??
              false;
        },
      );

      _addLog('✓ Project setup finished. Starting application...', false);
      await projectsProvider.startProject(project, processProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successGreen,
            content: Text('✓ ${project.name} installed and started successfully!'),
          ),
        );
        appState.setTab(NavigationTab.runningProjects, projectId: project.id);
      }
    } catch (e) {
      _addLog('Installation error: $e', true);
    } finally {
      if (mounted) {
        setState(() => _isInstalling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsProvider = context.watch<ProjectsProvider>();
    final analysis = projectsProvider.currentAnalysis;
    final isAnalyzing = projectsProvider.isAnalyzing;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Install New GitHub Project',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter any public or private GitHub repository to automatically detect framework, dependencies, and launch locally.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 24),

            // URL input & actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GitHub Repository URL',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              hintText: 'https://github.com/username/project-name',
                              prefixIcon: Icon(Icons.link),
                            ),
                            onSubmitted: (_) => _startAnalysis(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          icon: isAnalyzing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.analytics_outlined),
                          label: Text(isAnalyzing ? 'Analyzing...' : 'Analyze Repository'),
                          onPressed: isAnalyzing ? null : _startAnalysis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.code, size: 14),
                          label: const Text('Try Laravel Demo'),
                          onPressed: () {
                            _urlController.text = 'https://github.com/laravel/laravel';
                            _startAnalysis();
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.javascript, size: 14),
                          label: const Text('Try Next.js Demo'),
                          onPressed: () {
                            _urlController.text = 'https://github.com/vercel/next-learn';
                            _startAnalysis();
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.terminal, size: 14),
                          label: const Text('Try FastAPI Demo'),
                          onPressed: () {
                            _urlController.text = 'https://github.com/tiangolo/fastapi';
                            _startAnalysis();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (projectsProvider.analysisError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorRed),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorRed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        projectsProvider.analysisError!,
                        style: const TextStyle(color: AppTheme.errorRed),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Analysis Results Display
            if (analysis != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Repository Analysis & Execution Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Name field
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Project Display Name',
                                prefixIcon: Icon(Icons.title),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            ),
                            icon: _isInstalling
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.rocket_launch),
                            label: Text(
                              _isInstalling ? 'Installing...' : 'Install & Run',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isInstalling ? null : () => _runInstallation(analysis),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Tech Spec Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _detailTile(
                              title: 'Language',
                              value: analysis.techStack.language.displayName,
                              icon: Icons.code,
                            ),
                          ),
                          Expanded(
                            child: _detailTile(
                              title: 'Framework',
                              value: analysis.techStack.framework.displayName,
                              icon: Icons.layers,
                            ),
                          ),
                          Expanded(
                            child: _detailTile(
                              title: 'Database Requirement',
                              value: analysis.techStack.databaseRequirement.displayName,
                              icon: Icons.storage,
                            ),
                          ),
                          Expanded(
                            child: _detailTile(
                              title: 'Target Port',
                              value: '${analysis.techStack.recommendedPort}',
                              icon: Icons.numbers,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (analysis.techStack.dependencyFiles.isNotEmpty) ...[
                        Text(
                          'Dependency Files: ${analysis.techStack.dependencyFiles.join(", ")}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                      ],

                      if (analysis.techStack.detectedTestFrameworks.isNotEmpty) ...[
                        Text(
                          'Detected Test Suites: ${analysis.techStack.detectedTestFrameworks.join(", ")}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                      ],

                      if (analysis.readmeSummary.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'README Excerpt:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            analysis.readmeSummary,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Live Analysis/Install Terminal
            SizedBox(
              height: 260,
              child: TerminalView(
                title: 'Installation Output & Live Logs',
                logs: _screenLogs,
                onClear: () => setState(() => _screenLogs.clear()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile({required String title, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.accentCyan),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
