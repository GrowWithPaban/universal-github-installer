import 'package:flutter/material.dart';

enum NavigationTab {
  dashboard,
  installNew,
  myProjects,
  runningProjects,
  databaseManager,
  runtimeManager,
  testingCenter,
  tunnelManager,
  aiAssistant,
  settings,
  about,
}

class AppState extends ChangeNotifier {
  NavigationTab _currentTab = NavigationTab.dashboard;
  ThemeMode _themeMode = ThemeMode.dark;
  String? _selectedProjectId;

  NavigationTab get currentTab => _currentTab;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String? get selectedProjectId => _selectedProjectId;

  void setTab(NavigationTab tab, {String? projectId}) {
    _currentTab = tab;
    if (projectId != null) {
      _selectedProjectId = projectId;
    }
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void selectProject(String? id) {
    _selectedProjectId = id;
    notifyListeners();
  }
}
