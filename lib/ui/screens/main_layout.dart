import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../widgets/sidebar.dart';
import 'about_screen.dart';
import 'ai_assistant_screen.dart';
import 'dashboard_screen.dart';
import 'database_screen.dart';
import 'install_screen.dart';
import 'projects_screen.dart';
import 'running_screen.dart';
import 'runtime_screen.dart';
import 'settings_screen.dart';
import 'testing_screen.dart';
import 'tunnel_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    Widget getActiveScreen() {
      switch (appState.currentTab) {
        case NavigationTab.dashboard:
          return const DashboardScreen();
        case NavigationTab.installNew:
          return const InstallScreen();
        case NavigationTab.myProjects:
          return const ProjectsScreen();
        case NavigationTab.runningProjects:
          return const RunningScreen();
        case NavigationTab.databaseManager:
          return const DatabaseScreen();
        case NavigationTab.runtimeManager:
          return const RuntimeScreen();
        case NavigationTab.testingCenter:
          return const TestingScreen();
        case NavigationTab.tunnelManager:
          return const TunnelScreen();
        case NavigationTab.aiAssistant:
          return const AiAssistantScreen();
        case NavigationTab.settings:
          return const SettingsScreen();
        case NavigationTab.about:
          return const AboutScreen();
      }
    }

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1, thickness: 1, color: Colors.white10),
          Expanded(child: getActiveScreen()),
        ],
      ),
    );
  }
}

