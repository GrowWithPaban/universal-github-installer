import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/supported_technologies.dart';
import '../../core/models/project.dart';
import '../../core/models/test_result.dart';
import '../../core/utils/command_runner.dart';
import '../database/database_manager.dart';

class TestingEngine {
  static Future<TestSuiteReport> runTests(
    Project project, {
    void Function(String line, bool isError)? onLog,
  }) async {
    final startTime = DateTime.now();
    final tech = project.techStack;
    final frameworks = tech.detectedTestFrameworks;

    String testFramework = frameworks.isNotEmpty ? frameworks.first : 'Built-in Health Checks';
    String cmd = '';
    List<String> args = [];

    final isWin = Platform.isWindows;
    final venvPython = isWin
        ? '${project.localPath}\\.venv\\Scripts\\python.exe'
        : '${project.localPath}/.venv/bin/python';

    // Configure test command based on framework
    if (frameworks.contains('jest')) {
      cmd = tech.packageManager ?? 'npm';
      args = ['test', '--', '--watchAll=false'];
    } else if (frameworks.contains('vitest')) {
      cmd = tech.packageManager ?? 'npm';
      args = ['test', '--', '--run'];
    } else if (frameworks.contains('pytest')) {
      cmd = File(venvPython).existsSync() ? venvPython : (isWin ? 'python' : 'python3');
      args = ['-m', 'pytest'];
    } else if (frameworks.contains('phpunit')) {
      cmd = 'composer';
      args = ['exec', 'phpunit'];
    } else if (frameworks.contains('pest')) {
      cmd = 'composer';
      args = ['exec', 'pest'];
    }

    int totalCount = 0;
    int passedCount = 0;
    int failedCount = 0;
    final testCases = <TestCaseResult>[];
    final outputBuffer = StringBuffer();

    // 1. Run Framework Test Suite if command available
    if (cmd.isNotEmpty) {
      onLog?.call('Running test suite via $testFramework: $cmd ${args.join(" ")}', false);
      final res = await CommandRunner.run(
        cmd,
        args,
        workingDirectory: project.localPath,
        onLine: (line, isError) {
          outputBuffer.writeln(line);
          onLog?.call(line, isError);

          // Simple regex parse for pass/fail lines
          if (line.toLowerCase().contains('pass') || line.contains('✓') || line.contains('OK')) {
            passedCount++;
            totalCount++;
            testCases.add(TestCaseResult(
              name: line.trim().length > 60 ? line.trim().substring(0, 60) : line.trim(),
              passed: true,
            ));
          } else if (line.toLowerCase().contains('fail') || line.contains('✕') || line.contains('FAIL')) {
            failedCount++;
            totalCount++;
            testCases.add(TestCaseResult(
              name: line.trim().length > 60 ? line.trim().substring(0, 60) : line.trim(),
              passed: false,
              failureMessage: line.trim(),
            ));
          }
        },
      );

      if (totalCount == 0) {
        if (res.isSuccess) {
          totalCount = 1;
          passedCount = 1;
          testCases.add(const TestCaseResult(name: 'Test Suite Execution', passed: true));
        } else {
          totalCount = 1;
          failedCount = 1;
          testCases.add(TestCaseResult(
            name: 'Test Suite Execution',
            passed: false,
            failureMessage: res.stderr.isNotEmpty ? res.stderr : 'Tests failed with exit code ${res.exitCode}',
          ));
        }
      }
    }

    // 2. Run HTTP Health Check
    bool httpHealthPassed = false;
    onLog?.call('Testing HTTP health endpoint on ${project.displayUrl}...', false);
    try {
      final response = await http.get(Uri.parse(project.displayUrl)).timeout(const Duration(seconds: 4));
      httpHealthPassed = response.statusCode < 500;
      testCases.add(TestCaseResult(
        name: 'HTTP Endpoint Reachability (${project.displayUrl})',
        passed: httpHealthPassed,
        failureMessage: httpHealthPassed ? null : 'HTTP returned error code ${response.statusCode}',
      ));
      if (httpHealthPassed) {
        passedCount++;
      } else {
        failedCount++;
      }
      totalCount++;
      onLog?.call('✓ HTTP check response status: ${response.statusCode}', false);
    } catch (e) {
      httpHealthPassed = false;
      testCases.add(TestCaseResult(
        name: 'HTTP Endpoint Reachability (${project.displayUrl})',
        passed: false,
        failureMessage: 'Could not connect to ${project.displayUrl} ($e)',
      ));
      failedCount++;
      totalCount++;
      onLog?.call('Notice: Application not responding on ${project.displayUrl}', true);
    }

    // 3. Test Database Connectivity
    String? dbStatus;
    if (project.databaseType != DatabaseType.none) {
      onLog?.call('Testing database connection for ${project.databaseType.displayName}...', false);
      final connected = await DatabaseManager.testConnection(
        type: project.databaseType,
        database: project.envVariables['DB_DATABASE'],
      );
      dbStatus = connected ? 'Connected' : 'Connection failed';
      testCases.add(TestCaseResult(
        name: 'Database Connectivity (${project.databaseType.displayName})',
        passed: connected,
        failureMessage: connected ? null : 'Database server unreachable or file missing',
      ));
      if (connected) {
        passedCount++;
      } else {
        failedCount++;
      }
      totalCount++;
      onLog?.call('Database test status: $dbStatus', !connected);
    }

    final duration = DateTime.now().difference(startTime);

    return TestSuiteReport(
      projectId: project.id,
      framework: testFramework,
      executedAt: DateTime.now(),
      totalCount: totalCount,
      passedCount: passedCount,
      failedCount: failedCount,
      totalDuration: duration,
      tests: testCases,
      rawOutput: outputBuffer.toString(),
      httpHealthCheckPassed: httpHealthPassed,
      dbConnectionStatus: dbStatus,
    );
  }
}
