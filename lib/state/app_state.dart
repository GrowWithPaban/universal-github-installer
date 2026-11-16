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
  settings,
  about,
}

class AppState extends ChangeNotifier {
  NavigationTab _currentTab = NavigationTab.dashboard;
  ThemeMode _themeMode = ThemeMode.dark;
  String? _selectedProjectId;
  String? _pendingInstallUrl;

  NavigationTab get currentTab => _currentTab;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String? get selectedProjectId => _selectedProjectId;
  String? get pendingInstallUrl => _pendingInstallUrl;

  void setTab(NavigationTab tab, {String? projectId}) {
    _currentTab = tab;
    if (projectId != null) {
      _selectedProjectId = projectId;
    }
    notifyListeners();
  }

  void startInstall(String url) {
    _pendingInstallUrl = url;
    _currentTab = NavigationTab.installNew;
    notifyListeners();
  }

  void clearPendingInstallUrl() {
    _pendingInstallUrl = null;
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
