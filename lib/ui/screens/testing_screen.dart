import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/process_provider.dart';
import '../../state/projects_provider.dart';

class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final projectsProvider = context.watch<ProjectsProvider>();
    final processProvider = context.watch<ProcessProvider>();

    if (_selectedProjectId == null && projectsProvider.projects.isNotEmpty) {
      _selectedProjectId = appState.selectedProjectId ?? projectsProvider.projects.first.id;
    }

    final selectedProject = projectsProvider.getProjectById(_selectedProjectId);
    final report = projectsProvider.lastTestReport;
    final isRunning = projectsProvider.isRunningTests;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automated Testing Center',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Run test suites, perform HTTP endpoint checks, and verify database connectivity',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                if (selectedProject != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    icon: isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(isRunning ? 'Running Tests...' : 'Run All Tests'),
                    onPressed: isRunning
                        ? null
                        : () => projectsProvider.runTests(selectedProject, processProvider),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Select project dropdown
            if (projectsProvider.projects.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.fact_check_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No projects installed to run tests on.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => appState.setTab(NavigationTab.installNew),
                          child: const Text('Install a Project'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Target Project: ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedProjectId,
                          items: projectsProvider.projects.map((p) {
                            return DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.name} (${p.techStack.framework.displayName}) - Port ${p.port}'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedProjectId = val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Test Results Card
              if (report != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: report.allPassed
                            ? AppTheme.successGreen.withValues(alpha: 0.1)
                            : AppTheme.errorRed.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Icon(
                                report.allPassed ? Icons.check_circle : Icons.warning_amber_rounded,
                                color: report.allPassed ? AppTheme.successGreen : AppTheme.errorRed,
                                size: 36,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report.allPassed ? 'ALL TESTS PASSED' : 'SOME TESTS FAILED',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: report.allPassed ? AppTheme.successGreen : AppTheme.errorRed,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${report.passedCount} passed • ${report.failedCount} failed (${report.totalDuration.inMilliseconds} ms)',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                const Text(
                  'Executed Test Cases & Checks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                ...report.tests.map(
                  (t) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        t.passed ? Icons.check_circle_outline : Icons.cancel_outlined,
                        color: t.passed ? AppTheme.successGreen : AppTheme.errorRed,
                      ),
                      title: Text(t.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: t.failureMessage != null
                          ? Text(
                              t.failureMessage!,
                              style: const TextStyle(color: AppTheme.errorRed, fontSize: 11, fontFamily: 'monospace'),
                            )
                          : null,
                      trailing: Text(
                        t.passed ? 'PASSED' : 'FAILED',
                        style: TextStyle(
                          color: t.passed ? AppTheme.successGreen : AppTheme.errorRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (report.rawOutput.isNotEmpty) ...[
                  const Text(
                    'Raw Test Runner Output',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkTerminal,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        report.rawOutput,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
