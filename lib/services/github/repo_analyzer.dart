import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/models/tech_stack.dart';
import '../detection/tech_detector.dart';

class RepoAnalysisResult {
  final String repoPath;
  final TechStack techStack;
  final String readmeSummary;
  final List<String> configFiles;
  final List<String> envExampleFiles;
  final Map<String, String> suggestedEnv;
  final List<String> availableTestFiles;

  RepoAnalysisResult({
    required this.repoPath,
    required this.techStack,
    required this.readmeSummary,
    required this.configFiles,
    required this.envExampleFiles,
    required this.suggestedEnv,
    required this.availableTestFiles,
  });
}

class RepoAnalyzer {
  static Future<RepoAnalysisResult> analyze(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      throw Exception('Repository directory does not exist: $dirPath');
    }

    // Read directory files
    final files = <String>[];
    await for (final entity in dir.list(followLinks: false)) {
      files.add(p.basename(entity.path));
    }

    // Read README if available
    String readmeSummary = '';
    for (final name in ['README.md', 'readme.md', 'README', 'readme.txt']) {
      final f = File(p.join(dirPath, name));
      if (await f.exists()) {
        try {
          final content = await f.readAsString();
          readmeSummary = content.length > 500 ? '${content.substring(0, 500)}...' : content;
          break;
        } catch (_) {}
      }
    }

    // Detect environment example files (.env.example, .env.dist, .env.sample)
    final envExamples = <String>[];
    final suggestedEnv = <String, String>{};
    for (final name in ['.env.example', '.env.dist', '.env.sample', '.env.default', '.env.local.example']) {
      final f = File(p.join(dirPath, name));
      if (await f.exists()) {
        envExamples.add(name);
        try {
          final lines = await f.readAsLines();
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty && !trimmed.startsWith('#') && trimmed.contains('=')) {
              final parts = trimmed.split('=');
              final key = parts[0].trim();
              final val = parts.sublist(1).join('=').trim();
              suggestedEnv[key] = val;
            }
          }
        } catch (_) {}
      }
    }

    // Config files
    final configFiles = <String>[];
    const candidateConfigs = [
      'package.json',
      'composer.json',
      'requirements.txt',
      'Pipfile',
      'pyproject.toml',
      'docker-compose.yml',
      'docker-compose.yaml',
      'Dockerfile',
      'artisan',
      'manage.py',
      'vite.config.js',
      'vite.config.ts',
      'next.config.js',
      'next.config.mjs',
      'nuxt.config.ts',
      'tsconfig.json',
    ];

    for (final cfg in candidateConfigs) {
      if (files.contains(cfg)) {
        configFiles.add(cfg);
      }
    }

    // Run modular technology detector
    final techStack = await TechDetector.detect(dirPath);

    return RepoAnalysisResult(
      repoPath: dirPath,
      techStack: techStack,
      readmeSummary: readmeSummary,
      configFiles: configFiles,
      envExampleFiles: envExamples,
      suggestedEnv: suggestedEnv,
      availableTestFiles: techStack.detectedTestFrameworks,
    );
  }
}

