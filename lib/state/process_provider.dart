import 'package:flutter/material.dart';
import '../core/models/process_status.dart';
import '../services/execution/process_manager.dart';

class ProcessProvider extends ChangeNotifier {
  final ProcessManager _processManager = ProcessManager();
  final Map<String, List<LogEntry>> _projectLogs = {};

  List<LogEntry> getLogsForProject(String projectId) {
    return _projectLogs[projectId] ?? _processManager.getLogs(projectId);
  }

  void addLog(String projectId, String text, bool isError) {
    _projectLogs.putIfAbsent(projectId, () => []);
    _projectLogs[projectId]!.add(LogEntry(
      timestamp: DateTime.now(),
      text: text,
      isError: isError,
    ));
    notifyListeners();
  }

  void clearLogs(String projectId) {
    _projectLogs[projectId]?.clear();
    notifyListeners();
  }

  bool isRunning(String projectId) => _processManager.isRunning(projectId);

  ProjectProcessInfo? getProcessInfo(String projectId) => _processManager.getProcessInfo(projectId);
}
