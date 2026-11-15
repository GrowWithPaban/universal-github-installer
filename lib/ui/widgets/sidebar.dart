import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../state/projects_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final projectsProvider = context.watch<ProjectsProvider>();
    final isDark = appState.isDarkMode;

    final bgColor = isDark ? AppTheme.darkSidebar : AppTheme.lightSidebar;
    const textColor = Colors.white;

    Widget navItem({
      required NavigationTab tab,
      required IconData icon,
      required String label,
      int? badgeCount,
    }) {
      final isSelected = appState.currentTab == tab;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Material(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            leading: Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            title: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: badgeCount != null && badgeCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppTheme.successGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () => appState.setTab(tab),
          ),
        ),
      );
    }

    return Container(
      width: 250,
      color: bgColor,
      child: Column(
        children: [
          // Header / Logo
          Container(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.install_desktop, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GitHub Installer',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Universal Dev Manager',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                navItem(
                  tab: NavigationTab.dashboard,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                ),
                navItem(
                  tab: NavigationTab.installNew,
                  icon: Icons.add_circle_outline,
                  label: 'Install New Project',
                ),
                navItem(
                  tab: NavigationTab.myProjects,
                  icon: Icons.folder_outlined,
                  label: 'My Projects',
                  badgeCount: projectsProvider.projects.length,
                ),
                navItem(
                  tab: NavigationTab.runningProjects,
                  icon: Icons.play_circle_outline,
                  label: 'Running Projects',
                  badgeCount: projectsProvider.runningCount,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'DEVELOPMENT',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                navItem(
                  tab: NavigationTab.databaseManager,
                  icon: Icons.storage_outlined,
                  label: 'Database Manager',
                ),
                navItem(
                  tab: NavigationTab.runtimeManager,
                  icon: Icons.miscellaneous_services_outlined,
                  label: 'Runtime Manager',
                ),
                navItem(
                  tab: NavigationTab.testingCenter,
                  icon: Icons.fact_check_outlined,
                  label: 'Testing Center',
                ),
                navItem(
                  tab: NavigationTab.tunnelManager,
                  icon: Icons.public_outlined,
                  label: 'Tunnel Manager',
                ),
                navItem(
                  tab: NavigationTab.aiAssistant,
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI Assistant',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'SYSTEM',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                navItem(
                  tab: NavigationTab.settings,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                ),
                navItem(
                  tab: NavigationTab.about,
                  icon: Icons.info_outline,
                  label: 'About',
                ),
              ],
            ),
          ),

          // Footer info & Theme toggle
          const Divider(color: Colors.white12, height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
                  onPressed: () => appState.toggleTheme(),
                ),
                const Spacer(),
                const Text(
                  'v${AppConstants.appVersion}',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
