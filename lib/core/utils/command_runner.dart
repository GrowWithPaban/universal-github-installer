import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class CommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  bool get isSuccess => exitCode == 0;
}

class CommandRunner {
  static Map<String, String> getEnhancedEnvironment([Map<String, String>? extra]) {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    final currentPath = Platform.environment['PATH'] ?? '';
    final separator = Platform.isWindows ? ';' : ':';

    final additionalPaths = [
      p.join(home, '.local', 'bin'),
      p.join(home, '.cargo', 'bin'),
      p.join(home, '.nvm', 'current', 'bin'),
      '/opt/homebrew/bin',
      '/opt/homebrew/sbin',
      '/usr/local/bin',
      '/usr/bin',
      '/bin',
      '/usr/sbin',
      '/sbin',
    ];

    final newPath = [
      ...additionalPaths.where((path) => Directory(path).existsSync()),
      currentPath,
    ].join(separator);

    return {
      ...Platform.environment,
      'PATH': newPath,
      ...?extra,
    };
  }

  static String resolveExecutable(String executable) {
    if (executable.contains(Platform.pathSeparator)) {
      return executable;
    }

    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    final searchDirs = [
      p.join(home, '.local', 'bin'),
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '/usr/bin',
      '/bin',
      p.join(home, '.cargo', 'bin'),
    ];

    for (final dir in searchDirs) {
      final candidate = p.join(dir, executable);
      if (File(candidate).existsSync()) {
        return candidate;
      }
      if (Platform.isWindows && File('$candidate.exe').existsSync()) {
        return '$candidate.exe';
      }
      if (Platform.isWindows && File('$candidate.cmd').existsSync()) {
        return '$candidate.cmd';
      }
    }

    return executable;
  }

  static Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    void Function(String output, bool isError)? onLine,
  }) async {
    try {
      final resolvedExecutable = resolveExecutable(executable);
      final env = getEnhancedEnvironment(environment);

      final process = await Process.start(
        resolvedExecutable,
        arguments,
        workingDirectory: workingDirectory,
        environment: env,
        runInShell: true,
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      final stdoutDone = Completer<void>();
      final stderrDone = Completer<void>();

      process.stdout.transform(utf8.decoder).listen((data) {
        stdoutBuffer.write(data);
        if (onLine != null) {
          for (final line in data.split('\n')) {
            if (line.isNotEmpty) onLine(line, false);
          }
        }
      }, onDone: () => stdoutDone.complete());

      process.stderr.transform(utf8.decoder).listen((data) {
        stderrBuffer.write(data);
        if (onLine != null) {
          for (final line in data.split('\n')) {
            if (line.isNotEmpty) onLine(line, true);
          }
        }
      }, onDone: () => stderrDone.complete());

      final exitCode = await process.exitCode;
      await Future.wait([stdoutDone.future, stderrDone.future]);

      return CommandResult(
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
      );
    } catch (e) {
      if (onLine != null) {
        onLine('Command execution error: $e', true);
      }
      return CommandResult(
        exitCode: -1,
        stdout: '',
        stderr: e.toString(),
      );
    }
  }

  static Future<Process> startStreaming(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    required void Function(String line, bool isError) onLine,
  }) async {
    final resolvedExecutable = resolveExecutable(executable);
    final env = getEnhancedEnvironment(environment);

    final process = await Process.start(
      resolvedExecutable,
      arguments,
      workingDirectory: workingDirectory,
      environment: env,
      runInShell: true,
    );

    process.stdout.transform(utf8.decoder).listen((data) {
      for (final line in data.split('\n')) {
        if (line.trim().isNotEmpty) {
          onLine(line, false);
        }
      }
    });

    process.stderr.transform(utf8.decoder).listen((data) {
      for (final line in data.split('\n')) {
        if (line.trim().isNotEmpty) {
          onLine(line, true);
        }
      }
    });

    return process;
  }
}
