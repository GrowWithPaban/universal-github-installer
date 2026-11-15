import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/constants/supported_technologies.dart';
import '../../core/models/tech_stack.dart';

class PhpDetector {
  static Future<TechStack?> detect(String dirPath, List<String> files) async {
    final hasComposer = files.contains('composer.json');
    final hasArtisan = files.contains('artisan');
    final hasWpConfig = files.contains('wp-config.php') || files.contains('wp-config-sample.php');
    final hasSpark = files.contains('spark'); // CodeIgniter 4

    // Check for PHP files
    bool hasAnyPhpFile = files.any((f) => f.endsWith('.php'));
    if (!hasComposer && !hasArtisan && !hasWpConfig && !hasSpark && !hasAnyPhpFile) {
      return null;
    }

    FrameworkType framework = FrameworkType.corePhp;
    DatabaseType database = DatabaseType.mysql;
    int port = 8000;
    final dependencyFiles = <String>[];
    final scripts = <String>[];
    final testFrameworks = <String>[];

    if (hasComposer) {
      dependencyFiles.add('composer.json');
      try {
        final compFile = File(p.join(dirPath, 'composer.json'));
        final content = await compFile.readAsString();
        final json = jsonDecode(content);

        // Check require / require-dev
        final require = (json['require'] as Map<String, dynamic>?) ?? {};
        final requireDev = (json['require-dev'] as Map<String, dynamic>?) ?? {};
        final allDeps = {...require, ...requireDev};

        if (allDeps.containsKey('laravel/framework') || hasArtisan) {
          framework = FrameworkType.laravel;
          port = 8000;
          database = DatabaseType.mysql;
        } else if (allDeps.containsKey('symfony/framework-bundle') || files.contains('symfony.lock')) {
          framework = FrameworkType.symfony;
          port = 8000;
          database = DatabaseType.postgresql;
        } else if (allDeps.containsKey('codeigniter4/framework') || hasSpark) {
          framework = FrameworkType.codeIgniter4;
          port = 8080;
        } else if (hasWpConfig) {
          framework = FrameworkType.wordPress;
          port = 8080;
          database = DatabaseType.mysql;
        } else {
          framework = FrameworkType.composerPackage;
        }

        // Test frameworks
        if (allDeps.containsKey('phpunit/phpunit') || files.contains('phpunit.xml')) {
          testFrameworks.add('phpunit');
        }
        if (allDeps.containsKey('pestphp/pest')) {
          testFrameworks.add('pest');
        }

        // Scripts
        if (json['scripts'] is Map) {
          scripts.addAll((json['scripts'] as Map).keys.map((e) => e.toString()));
        }
      } catch (_) {}
    } else if (hasWpConfig) {
      framework = FrameworkType.wordPress;
      port = 8080;
      database = DatabaseType.mysql;
    } else if (files.contains('system') && Directory(p.join(dirPath, 'system')).existsSync()) {
      framework = FrameworkType.codeIgniter3;
      port = 8080;
    }

    return TechStack(
      language: ProgrammingLanguage.php,
      framework: framework,
      databaseRequirement: database,
      packageManager: hasComposer ? 'composer' : null,
      dependencyFiles: dependencyFiles,
      detectedScripts: scripts,
      recommendedPort: port,
      detectedTestFrameworks: testFrameworks,
    );
  }
}
