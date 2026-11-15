import 'dart:async';
import 'dart:io';
import '../../core/constants/supported_technologies.dart';
import '../../core/models/process_status.dart';
import '../../core/models/project.dart';
import '../../core/utils/command_runner.dart';
import '../../core/utils/port_detector.dart';

class ProcessManager {
  static final ProcessManager _instance = ProcessManager._internal();
  factory ProcessManager() => _instance;
  ProcessManager._internal();

  final Map<String, Process> _runningProcesses = {};
  final Map<String, ProjectProcessInfo> _processInfos = {};
  final Map<String, StreamController<LogEntry>> _logControllers = {};

  Stream<LogEntry>? getLogStream(String projectId) {
    return _logControllers[projectId]?.stream;
  }

  List<LogEntry> getLogs(String projectId) {
    return _processInfos[projectId]?.logs ?? [];
  }

  bool isRunning(String projectId) {
    return _runningProcesses.containsKey(projectId);
  }

  ProjectProcessInfo? getProcessInfo(String projectId) {
    return _processInfos[projectId];
  }

  Future<bool> startProject(
    Project project, {
    void Function(String line, bool isError)? onLog,
  }) async {
    final projectId = project.id;
    if (_runningProcesses.containsKey(projectId)) {
      onLog?.call('Project is already running.', false);
      return true;
    }

    final plan = project.installationPlan;
    if (plan == null) {
      onLog?.call('Error: Project has no installation or start plan configured.', true);
      return false;
    }

    // Check if the assigned port is occupied by another process
    final inUse = await PortDetector.isPortInUse(project.port);
    if (inUse) {
      // Find a new available port
      final newPort = await PortDetector.findAvailablePort(startPort: project.port + 1);
      project.port = newPort;
      project.localUrl = 'http://localhost:$newPort';
      onLog?.call('Note: Original port was in use. Assigned new port: $newPort', false);
    }

    _logControllers.putIfAbsent(projectId, () => StreamController<LogEntry>.broadcast());

    void logHandler(String line, bool isError) {
      final entry = LogEntry(
        timestamp: DateTime.now(),
        text: line,
        isError: isError,
      );
      _processInfos[projectId]?.logs.add(entry);
      _logControllers[projectId]?.add(entry);
      onLog?.call(line, isError);
    }

    logHandler('Starting ${project.name} on port ${project.port}...', false);
    logHandler('Command: ${plan.startCommand} ${plan.startArgs.join(" ")}', false);

    try {
      final env = <String, String>{
        ...project.envVariables,
        'PORT': project.port.toString(),
      };

      final process = await CommandRunner.startStreaming(
        plan.startCommand,
        plan.startArgs,
        workingDirectory: project.localPath,
        environment: env,
        onLine: (line, isError) => logHandler(line, isError),
      );

      _runningProcesses[projectId] = process;
      _processInfos[projectId] = ProjectProcessInfo(
        projectId: projectId,
        pid: process.pid,
        startedAt: DateTime.now(),
        port: project.port,
      );

      project.status = ProjectState.running;
      project.lastStartedAt = DateTime.now();

      // Listen for process exit or crash
      process.exitCode.then((code) {
        logHandler('Process exited with code $code', code != 0);
        _runningProcesses.remove(projectId);
        _processInfos.remove(projectId);
        project.status = code == 0 ? ProjectState.ready : ProjectState.error;
      });

      // Poll port to confirm health
      final portBound = await PortDetector.waitForPort(project.port, timeout: const Duration(seconds: 10));
      if (portBound) {
        logHandler('✓ Application is healthy and listening on http://localhost:${project.port}', false);
        _processInfos[projectId]?.isHealthy = true;
      }

      return true;
    } catch (e) {
      logHandler('Failed to start application: $e', true);
      project.status = ProjectState.error;
      project.lastError = e.toString();
      return false;
    }
  }

  Future<bool> stopProject(String projectId) async {
    final process = _runningProcesses[projectId];
    if (process == null) return true;

    try {
      final killed = process.kill(ProcessSignal.sigterm);
      if (!killed) {
        process.kill(ProcessSignal.sigkill);
      }
      _runningProcesses.remove(projectId);
      _processInfos.remove(projectId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restartProject(
    Project project, {
    void Function(String line, bool isError)? onLog,
  }) async {
    await stopProject(project.id);
    await Future.delayed(const Duration(milliseconds: 500));
    return await startProject(project, onLog: onLog);
  }

  void stopAll() {
    for (final pid in _runningProcesses.keys) {
      stopProject(pid);
    }
  }
}

