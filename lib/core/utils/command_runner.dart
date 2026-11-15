import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  static Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    void Function(String output, bool isError)? onLine,
  }) async {
    try {
      final process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: Platform.isWindows,
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
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: Platform.isWindows,
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

