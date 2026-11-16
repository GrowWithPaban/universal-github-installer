import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/projects_provider.dart';
import '../../state/runtime_provider.dart';
import '../../state/tunnel_provider.dart';
import '../widgets/project_card.dart';
import '../widgets/webotapp_catalog_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final projectsProvider = context.watch<ProjectsProvider>();
    final runtimeProvider = context.watch<RuntimeProvider>();
    final tunnelProvider = context.watch<TunnelProvider>();

    Widget metricCard({
      required String title,
      required String value,
      required IconData icon,
      required Color color,
      VoidCallback? onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            // Top Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Development Dashboard',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage, run, test, and expose your GitHub repositories locally',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Install New Project'),
                  onPressed: () => appState.setTab(NavigationTab.installNew),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Metrics row
            Row(
              children: [
                metricCard(
                  title: 'Installed Projects',
                  value: '${projectsProvider.projects.length}',
                  icon: Icons.folder,
                  color: AppTheme.primaryBlue,
                  onTap: () => appState.setTab(NavigationTab.myProjects),
                ),
                const SizedBox(width: 14),
                metricCard(
                  title: 'Running Locally',
                  value: '${projectsProvider.runningCount}',
                  icon: Icons.play_circle_filled,
                  color: AppTheme.successGreen,
                  onTap: () => appState.setTab(NavigationTab.runningProjects),
                ),
                const SizedBox(width: 14),
                metricCard(
                  title: 'Active Tunnels',
                  value: '${tunnelProvider.activeTunnels.length}',
                  icon: Icons.public,
                  color: AppTheme.accentCyan,
                  onTap: () => appState.setTab(NavigationTab.tunnelManager),
                ),
                const SizedBox(width: 14),
                metricCard(
                  title: 'Runtimes Detected',
                  value: '${runtimeProvider.installedCount}',
                  icon: Icons.miscellaneous_services,
                  color: AppTheme.warningOrange,
                  onTap: () => appState.setTab(NavigationTab.runtimeManager),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Active / Running Projects Highlight
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Projects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => appState.setTab(NavigationTab.myProjects),
                  child: const Text('View All'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (projectsProvider.projects.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.download_for_offline_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 14),
                        const Text(
                          'No Projects Installed Yet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Paste a GitHub URL to analyze and automatically install your first project.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Install Project from GitHub'),
                          onPressed: () => appState.setTab(NavigationTab.installNew),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...projectsProvider.projects.take(4).map((p) => ProjectCard(project: p)),

            const WebotAppCatalogSection(),
          ],
        ),
      ),
    );
  }
}
