import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/supported_technologies.dart';
import '../core/models/installation_plan.dart';
import '../core/models/project.dart';
import '../core/models/test_result.dart';
import '../core/storage/database_helper.dart';
import '../core/utils/port_detector.dart';
import '../services/execution/process_manager.dart';
import '../services/github/github_service.dart';
import '../services/github/repo_analyzer.dart';
import '../services/runtime/dependency_installer.dart';
import '../services/testing/testing_engine.dart';
import 'process_provider.dart';

class ProjectsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final ProcessManager _processManager = ProcessManager();

  List<Project> _projects = [];
  bool _isLoading = false;
  RepoAnalysisResult? _currentAnalysis;
  bool _isAnalyzing = false;
  String? _analysisError;
  TestSuiteReport? _lastTestReport;
  bool _isRunningTests = false;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  RepoAnalysisResult? get currentAnalysis => _currentAnalysis;
  bool get isAnalyzing => _isAnalyzing;
  String? get analysisError => _analysisError;
  TestSuiteReport? get lastTestReport => _lastTestReport;
  bool get isRunningTests => _isRunningTests;

  int get runningCount => _projects.where((p) => p.status == ProjectState.running).length;
  int get stoppedCount => _projects.where((p) => p.status != ProjectState.running).length;

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();

    _projects = await _db.loadProjects();

    // Verify process states
    for (final p in _projects) {
      if (_processManager.isRunning(p.id)) {
        p.status = ProjectState.running;
      } else if (p.status == ProjectState.running) {
        p.status = ProjectState.ready;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<RepoAnalysisResult?> analyzeRepository(
    String url, {
    void Function(String output, bool isError)? onLog,
  }) async {
    _isAnalyzing = true;
    _analysisError = null;
    _currentAnalysis = null;
    notifyListeners();

    try {
      onLog?.call('Validating GitHub repository URL...', false);
      if (!GitHubService.isValidGitHubUrl(url)) {
        throw Exception('Invalid GitHub URL. Expected https://github.com/owner/repo format');
      }

      onLog?.call('Fetching repository metadata from GitHub...', false);
      await GitHubService.fetchMetadata(url);

      onLog?.call('Cloning repository for local inspection...', false);
      final localPath = await GitHubService.cloneRepository(url, onProgress: onLog);

      onLog?.call('Analyzing repository file structure and dependencies...', false);
      final analysis = await RepoAnalyzer.analyze(localPath);

      _currentAnalysis = analysis;
      _isAnalyzing = false;
      notifyListeners();
      return analysis;
    } catch (e) {
      _analysisError = e.toString();
      _isAnalyzing = false;
      onLog?.call('Analysis error: $e', true);
      notifyListeners();
      return null;
    }
  }

  Future<Project> installProject({
    required String name,
    required String githubUrl,
    required RepoAnalysisResult analysis,
    required ProcessProvider processProvider,
    required Future<bool> Function(InstallationStep step) requestApproval,
  }) async {
    final port = await PortDetector.findAvailablePort(
      startPort: analysis.techStack.recommendedPort,
    );

    final project = Project(
      id: const Uuid().v4(),
      name: name,
      githubUrl: githubUrl,
      localPath: analysis.repoPath,
      techStack: analysis.techStack,
      status: ProjectState.installing,
      port: port,
      localUrl: 'http://localhost:$port',
      databaseType: analysis.techStack.databaseRequirement,
      envVariables: analysis.suggestedEnv,
    );

    final plan = DependencyInstaller.generatePlan(project);
    project.installationPlan = plan;

    _projects.add(project);
    await _db.saveProject(project);
    notifyListeners();

    void logHandler(String line, bool isError) {
      processProvider.addLog(project.id, line, isError);
    }

    logHandler('Starting installation for ${project.name}...', false);

    final success = await DependencyInstaller.executeAllSteps(
      plan,
      project: project,
      onLine: logHandler,
      requestApproval: requestApproval,
    );

    if (success) {
      project.status = ProjectState.ready;
      logHandler('✓ Installation completed successfully! Ready to run.', false);
    } else {
      project.status = ProjectState.error;
      project.lastError = 'Installation steps did not all succeed.';
      logHandler('✗ Installation encountered errors.', true);
    }

    await _db.saveProject(project);
    notifyListeners();
    return project;
  }

  Future<bool> startProject(Project project, ProcessProvider processProvider) async {
    project.status = ProjectState.starting;
    notifyListeners();

    final started = await _processManager.startProject(
      project,
      onLog: (line, isError) => processProvider.addLog(project.id, line, isError),
    );

    if (started) {
      project.status = ProjectState.running;
      project.lastStartedAt = DateTime.now();
    } else {
      project.status = ProjectState.error;
    }

    await _db.saveProject(project);
    notifyListeners();
    return started;
  }

  Future<void> stopProject(Project project, ProcessProvider processProvider) async {
    project.status = ProjectState.stopping;
    notifyListeners();

    await _processManager.stopProject(project.id);
    project.status = ProjectState.ready;
    processProvider.addLog(project.id, 'Project stopped by user.', false);

    await _db.saveProject(project);
    notifyListeners();
  }

  Future<void> restartProject(Project project, ProcessProvider processProvider) async {
    await stopProject(project, processProvider);
    await Future.delayed(const Duration(milliseconds: 600));
    await startProject(project, processProvider);
  }

  Future<void> deleteProject(String projectId) async {
    await _processManager.stopProject(projectId);
    _projects.removeWhere((p) => p.id == projectId);
    await _db.deleteProject(projectId);
    notifyListeners();
  }

  Future<TestSuiteReport> runTests(Project project, ProcessProvider processProvider) async {
    _isRunningTests = true;
    notifyListeners();

    final report = await TestingEngine.runTests(
      project,
      onLog: (line, isError) => processProvider.addLog(project.id, '[TEST] $line', isError),
    );

    _lastTestReport = report;
    _isRunningTests = false;
    notifyListeners();
    return report;
  }

  Future<void> updateProjectEnv(Project project, Map<String, String> newEnv) async {
    project.envVariables = newEnv;
    await _db.saveProject(project);
    notifyListeners();
  }

  Project? getProjectById(String? id) {
    if (id == null) return null;
    return _projects.cast<Project?>().firstWhere(
      (p) => p?.id == id,
      orElse: () => null,
    );
  }
}
