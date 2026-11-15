import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/tunnel_info.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/projects_provider.dart';
import '../../state/tunnel_provider.dart';

class TunnelScreen extends StatefulWidget {
  const TunnelScreen({super.key});

  @override
  State<TunnelScreen> createState() => _TunnelScreenState();
}

class _TunnelScreenState extends State<TunnelScreen> {
  String? _selectedProjectId;

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Public URL copied to clipboard!'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final projectsProvider = context.watch<ProjectsProvider>();
    final tunnelProvider = context.watch<TunnelProvider>();

    if (_selectedProjectId == null && projectsProvider.projects.isNotEmpty) {
      _selectedProjectId = appState.selectedProjectId ?? projectsProvider.projects.first.id;
    }

    final selectedProject = projectsProvider.getProjectById(_selectedProjectId);
    final activeTunnel = selectedProject != null
        ? tunnelProvider.getTunnelForProject(selectedProject.id)
        : null;

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
                      'Expose My Project (Tunnel Manager)',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Securely expose locally running development servers to the internet via Cloudflare Tunnels',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 14, color: AppTheme.accentCyan),
                      const SizedBox(width: 6),
                      Text(
                        '${tunnelProvider.activeTunnels.length} Active Tunnels',
                        style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Security Warning Callout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Public Access Security Advisory',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.warningOrange),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Exposing a project provides a publicly accessible HTTPS link. Ensure your application has appropriate authentication or does not expose private database records or API secrets.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (projectsProvider.projects.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.public_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No installed projects available to expose.'),
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Project to Expose',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedProjectId,
                              items: projectsProvider.projects.map((p) {
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.name} (Port ${p.port}) - ${p.techStack.framework.displayName}'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedProjectId = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (activeTunnel == null || activeTunnel.status != TunnelStatus.active)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                              icon: tunnelProvider.isLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.rocket),
                              label: const Text('Start Public Tunnel'),
                              onPressed: (selectedProject != null && !tunnelProvider.isLoading)
                                  ? () => tunnelProvider.exposeProject(selectedProject)
                                  : null,
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop Tunnel'),
                              onPressed: () => tunnelProvider.stopTunnel(selectedProject!.id),
                            ),
                        ],
                      ),

                      if (tunnelProvider.statusMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          tunnelProvider.statusMessage!,
                          style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Active Tunnel Live Box
              if (activeTunnel != null && activeTunnel.publicUrl != null) ...[
                Card(
                  color: AppTheme.successGreen.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppTheme.successGreen),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.successGreen),
                            const SizedBox(width: 10),
                            Text(
                              'Tunnel Active for ${activeTunnel.projectName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ONLINE',
                                style: TextStyle(
                                  color: AppTheme.successGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link, color: AppTheme.accentCyan, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SelectableText(
                                  activeTunnel.publicUrl!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.accentCyan,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copy Public URL',
                                onPressed: () => _copyUrl(activeTunnel.publicUrl!),
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_browser),
                                tooltip: 'Open in Browser',
                                onPressed: () async {
                                  final uri = Uri.parse(activeTunnel.publicUrl!);
                                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        Text(
                          'Traffic from this URL forwards locally to http://127.0.0.1:${activeTunnel.localPort}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
