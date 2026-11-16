import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/constants/supported_technologies.dart';
import '../../core/models/tech_stack.dart';
import 'node_detector.dart';
import 'php_detector.dart';
import 'python_detector.dart';

class TechDetector {
  static Future<TechStack> detect(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return const TechStack(
        language: ProgrammingLanguage.unknown,
        framework: FrameworkType.custom,
      );
    }

    final files = <String>[];
    await for (final entity in dir.list(followLinks: false)) {
      files.add(p.basename(entity.path));
    }

    final hasDockerCompose = files.contains('docker-compose.yml') ||
        files.contains('docker-compose.yaml') ||
        files.contains('compose.yaml');

    // Priority 1: Check PHP first if artisan or composer.json is present (Laravel, Symfony, etc.)
    final isPhpPrimary = files.contains('artisan') ||
        files.contains('composer.json') ||
        files.contains('wp-config.php') ||
        files.contains('spark');

    if (isPhpPrimary) {
      final phpResult = await PhpDetector.detect(dirPath, files);
      if (phpResult != null) {
        if (hasDockerCompose) {
          return TechStack(
            language: phpResult.language,
            framework: phpResult.framework,
            databaseRequirement: phpResult.databaseRequirement,
            packageManager: phpResult.packageManager,
            dependencyFiles: phpResult.dependencyFiles,
            detectedScripts: phpResult.detectedScripts,
            recommendedPort: phpResult.recommendedPort,
            detectedTestFrameworks: phpResult.detectedTestFrameworks,
            hasDockerCompose: true,
          );
        }
        return phpResult;
      }
    }

    // Priority 2: Check Python first if manage.py or requirements.txt is present
    final isPythonPrimary = files.contains('manage.py') ||
        files.contains('Pipfile') ||
        files.contains('poetry.lock') ||
        files.contains('requirements.txt');

    if (isPythonPrimary) {
      final pythonResult = await PythonDetector.detect(dirPath, files);
      if (pythonResult != null) {
        if (hasDockerCompose) {
          return TechStack(
            language: pythonResult.language,
            framework: pythonResult.framework,
            databaseRequirement: pythonResult.databaseRequirement,
            packageManager: pythonResult.packageManager,
            dependencyFiles: pythonResult.dependencyFiles,
            detectedScripts: pythonResult.detectedScripts,
            recommendedPort: pythonResult.recommendedPort,
            detectedTestFrameworks: pythonResult.detectedTestFrameworks,
            hasDockerCompose: true,
          );
        }
        return pythonResult;
      }
    }

    // Priority 3: Check Node.js
    final nodeResult = await NodeDetector.detect(dirPath, files);
    if (nodeResult != null) {
      if (hasDockerCompose) {
        return TechStack(
          language: nodeResult.language,
          framework: nodeResult.framework,
          databaseRequirement: nodeResult.databaseRequirement,
          packageManager: nodeResult.packageManager,
          dependencyFiles: nodeResult.dependencyFiles,
          detectedScripts: nodeResult.detectedScripts,
          recommendedPort: nodeResult.recommendedPort,
          detectedTestFrameworks: nodeResult.detectedTestFrameworks,
          hasDockerCompose: true,
        );
      }
      return nodeResult;
    }

    // 4. Fallback Check PHP
    final phpResult = await PhpDetector.detect(dirPath, files);
    if (phpResult != null) {
      if (hasDockerCompose) {
        return TechStack(
          language: phpResult.language,
          framework: phpResult.framework,
          databaseRequirement: phpResult.databaseRequirement,
          packageManager: phpResult.packageManager,
          dependencyFiles: phpResult.dependencyFiles,
          detectedScripts: phpResult.detectedScripts,
          recommendedPort: phpResult.recommendedPort,
          detectedTestFrameworks: phpResult.detectedTestFrameworks,
          hasDockerCompose: true,
        );
      }
      return phpResult;
    }

    // 3. Check Python
    final pythonResult = await PythonDetector.detect(dirPath, files);
    if (pythonResult != null) {
      if (hasDockerCompose) {
        return TechStack(
          language: pythonResult.language,
          framework: pythonResult.framework,
          databaseRequirement: pythonResult.databaseRequirement,
          packageManager: pythonResult.packageManager,
          dependencyFiles: pythonResult.dependencyFiles,
          detectedScripts: pythonResult.detectedScripts,
          recommendedPort: pythonResult.recommendedPort,
          detectedTestFrameworks: pythonResult.detectedTestFrameworks,
          hasDockerCompose: true,
        );
      }
      return pythonResult;
    }

    // 4. Check Docker Compose standalone
    if (hasDockerCompose) {
      return const TechStack(
        language: ProgrammingLanguage.dockerCompose,
        framework: FrameworkType.dockerized,
        recommendedPort: 8080,
        hasDockerCompose: true,
      );
    }

    // 5. Check Static Web (index.html)
    if (files.contains('index.html')) {
      return const TechStack(
        language: ProgrammingLanguage.staticWeb,
        framework: FrameworkType.staticHtml,
        recommendedPort: 8080,
      );
    }

    // Fallback
    return const TechStack(
      language: ProgrammingLanguage.unknown,
      framework: FrameworkType.custom,
      recommendedPort: 3000,
    );
  }
}

