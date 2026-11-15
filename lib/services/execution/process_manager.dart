import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
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

  Future<bool> _ensureDependenciesInstalled(
    Project project,
    void Function(String line, bool isError) logHandler,
  ) async {
    final localPath = project.localPath;
    if (!Directory(localPath).existsSync()) return true;

    // 1. Node.js dependencies check
    final packageJson = File(p.join(localPath, 'package.json'));
    if (packageJson.existsSync()) {
      final nodeModules = Directory(p.join(localPath, 'node_modules'));
      bool needsInstall = !nodeModules.existsSync();
      if (!needsInstall) {
        try {
          needsInstall = nodeModules.listSync().isEmpty;
        } catch (_) {
          needsInstall = true;
        }
      }

      if (needsInstall) {
        final pkgMgr = project.techStack.packageManager ?? 'npm';
        logHandler('📦 Dependencies missing in node_modules. Automatically installing with "$pkgMgr install"...', false);
        final res = await CommandRunner.run(
          pkgMgr,
          ['install'],
          workingDirectory: localPath,
          onLine: logHandler,
        );
        if (!res.isSuccess) {
          logHandler('⚠️ Warning: "$pkgMgr install" exited with code ${res.exitCode}. Output:\n${res.stderr}', true);
        } else {
          logHandler('✓ Dependencies installed successfully.', false);
        }
      }
    }

    // 2. Python dependencies check
    final reqTxt = File(p.join(localPath, 'requirements.txt'));
    final pyProj = File(p.join(localPath, 'pyproject.toml'));
    if (reqTxt.existsSync() || pyProj.existsSync()) {
      final venvDir = Directory(p.join(localPath, '.venv'));
      if (!venvDir.existsSync()) {
        logHandler('📦 Python virtual environment not found. Creating .venv...', false);
        final pyCmd = Platform.isWindows ? 'python' : 'python3';
        await CommandRunner.run(pyCmd, ['-m', 'venv', '.venv'], workingDirectory: localPath, onLine: logHandler);
        final venvPip = Platform.isWindows
            ? p.join(localPath, '.venv', 'Scripts', 'pip.exe')
            : p.join(localPath, '.venv', 'bin', 'pip');
        if (reqTxt.existsSync()) {
          logHandler('Installing Python dependencies from requirements.txt...', false);
          await CommandRunner.run(venvPip, ['install', '-r', 'requirements.txt'], workingDirectory: localPath, onLine: logHandler);
        } else if (pyProj.existsSync()) {
          logHandler('Installing Python package dependencies...', false);
          await CommandRunner.run(venvPip, ['install', '.'], workingDirectory: localPath, onLine: logHandler);
        }
        logHandler('✓ Python environment configured.', false);
      }
    }

    // 3. PHP / Composer dependencies check
    final composerJson = File(p.join(localPath, 'composer.json'));
    if (composerJson.existsSync()) {
      final vendorDir = Directory(p.join(localPath, 'vendor'));
      if (!vendorDir.existsSync()) {
        logHandler('📦 Composer vendor folder not found. Running "composer install"...', false);
        await CommandRunner.run(
          'composer',
          ['install', '--no-interaction', '--prefer-dist'],
          workingDirectory: localPath,
          onLine: logHandler,
        );
        logHandler('✓ Composer dependencies installed.', false);
      }
    }

    return true;
  }

  Future<bool> reinstallDependencies(
    Project project, {
    void Function(String line, bool isError)? onLog,
  }) async {
    final localPath = project.localPath;
    final log = onLog ?? (line, isError) {};

    log('Starting clean dependency installation for ${project.name}...', false);

    final packageJson = File(p.join(localPath, 'package.json'));
    if (packageJson.existsSync()) {
      final pkgMgr = project.techStack.packageManager ?? 'npm';
      log('Executing: $pkgMgr install in $localPath', false);
      final res = await CommandRunner.run(
        pkgMgr,
        ['install'],
        workingDirectory: localPath,
        onLine: log,
      );
      if (res.isSuccess) {
        log('✓ Node dependencies installed successfully.', false);
      } else {
        log('✗ Dependency installation failed: ${res.stderr}', true);
      }
      return res.isSuccess;
    }

    final reqTxt = File(p.join(localPath, 'requirements.txt'));
    if (reqTxt.existsSync()) {
      final venvPip = Platform.isWindows
          ? p.join(localPath, '.venv', 'Scripts', 'pip.exe')
          : p.join(localPath, '.venv', 'bin', 'pip');
      log('Executing: $venvPip install -r requirements.txt', false);
      final res = await CommandRunner.run(
        venvPip,
        ['install', '-r', 'requirements.txt'],
        workingDirectory: localPath,
        onLine: log,
      );
      return res.isSuccess;
    }

    final composerJson = File(p.join(localPath, 'composer.json'));
    if (composerJson.existsSync()) {
      log('Executing: composer install in $localPath', false);
      final res = await CommandRunner.run(
        'composer',
        ['install', '--no-interaction', '--prefer-dist'],
        workingDirectory: localPath,
        onLine: log,
      );
      return res.isSuccess;
    }

    log('No package.json, requirements.txt, or composer.json found in project directory.', false);
    return true;
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

    // Verify dependencies before starting
    await _ensureDependenciesInstalled(project, logHandler);

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

