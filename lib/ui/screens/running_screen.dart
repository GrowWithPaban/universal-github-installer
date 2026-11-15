import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/supported_technologies.dart';
import '../../core/models/process_status.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/process_provider.dart';
import '../../state/projects_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/terminal_view.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final projectsProvider = context.watch<ProjectsProvider>();
    final processProvider = context.watch<ProcessProvider>();

    final runningProjects = projectsProvider.projects
        .where((p) => p.status == ProjectState.running || p.id == appState.selectedProjectId)
        .toList();

    if (_selectedProjectId == null && runningProjects.isNotEmpty) {
      _selectedProjectId = appState.selectedProjectId ?? runningProjects.first.id;
    }

    final currentProject = projectsProvider.getProjectById(_selectedProjectId);
    final List<LogEntry> currentLogs = _selectedProjectId != null
        ? processProvider.getLogsForProject(_selectedProjectId!)
        : <LogEntry>[];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Running Projects & Process Manager',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${projectsProvider.runningCount} active background services and application processes',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                if (currentProject != null)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_browser, size: 16),
                        label: Text('Open ${currentProject.displayUrl}'),
                        onPressed: () async {
                          final uri = Uri.parse(currentProject.displayUrl);
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorRed),
                        icon: const Icon(Icons.stop, size: 16),
                        label: const Text('Stop Process'),
                        onPressed: () => projectsProvider.stopProject(currentProject, processProvider),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 18),

            // Running Project Selector Tabs
            if (runningProjects.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pause_circle_outline, size: 54, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No Projects Currently Running',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start any installed project from "My Projects" or install a new one.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => appState.setTab(NavigationTab.myProjects),
                        child: const Text('Go to My Projects'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: runningProjects.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final p = runningProjects[index];
                    final isSel = p.id == _selectedProjectId;
                    return ChoiceChip(
                      selected: isSel,
                      avatar: Icon(
                        p.status == ProjectState.running ? Icons.play_circle_fill : Icons.circle,
                        color: p.status == ProjectState.running ? AppTheme.successGreen : Colors.grey,
                        size: 14,
                      ),
                      label: Text('${p.name} (Port ${p.port})'),
                      onSelected: (_) => setState(() => _selectedProjectId = p.id),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Active Project Info Banner
              if (currentProject != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        currentProject.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: currentProject.status),
                      const SizedBox(width: 16),
                      Text(
                        'Local: ${currentProject.displayUrl}',
                        style: const TextStyle(color: AppTheme.accentCyan, fontFamily: 'monospace', fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        'Path: ${currentProject.localPath}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // Terminal View
              Expanded(
                child: TerminalView(
                  title: 'Process Output - ${currentProject?.name ?? "Terminal"}',
                  logs: currentLogs,
                  onClear: () {
                    if (_selectedProjectId != null) {
                      processProvider.clearLogs(_selectedProjectId!);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
