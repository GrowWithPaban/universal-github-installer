import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/constants/supported_technologies.dart';
import '../../core/models/tech_stack.dart';

class NodeDetector {
  static Future<TechStack?> detect(String dirPath, List<String> files) async {
    final hasPackageJson = files.contains('package.json');
    if (!hasPackageJson) return null;

    FrameworkType framework = FrameworkType.vanillaNode;
    DatabaseType database = DatabaseType.none;
    int port = 3000;
    String packageManager = 'npm';
    final dependencyFiles = ['package.json'];
    final scripts = <String>[];
    final testFrameworks = <String>[];

    // Detect package manager lock file
    if (files.contains('pnpm-lock.yaml')) {
      packageManager = 'pnpm';
      dependencyFiles.add('pnpm-lock.yaml');
    } else if (files.contains('yarn.lock')) {
      packageManager = 'yarn';
      dependencyFiles.add('yarn.lock');
    } else if (files.contains('package-lock.json')) {
      packageManager = 'npm';
      dependencyFiles.add('package-lock.json');
    }

    try {
      final pkgFile = File(p.join(dirPath, 'package.json'));
      final content = await pkgFile.readAsString();
      final json = jsonDecode(content);

      final deps = (json['dependencies'] as Map<String, dynamic>?) ?? {};
      final devDeps = (json['devDependencies'] as Map<String, dynamic>?) ?? {};
      final allDeps = {...deps, ...devDeps};

      if (json['scripts'] is Map) {
        scripts.addAll((json['scripts'] as Map).keys.map((e) => e.toString()));
      }

      // Framework identification
      if (allDeps.containsKey('next') || files.contains('next.config.js') || files.contains('next.config.mjs')) {
        framework = FrameworkType.nextJs;
        port = 3000;
      } else if (allDeps.containsKey('nuxt') || files.contains('nuxt.config.ts') || files.contains('nuxt.config.js')) {
        framework = FrameworkType.nuxt;
        port = 3000;
      } else if (allDeps.containsKey('@nestjs/core')) {
        framework = FrameworkType.nestJs;
        port = 3000;
      } else if (files.contains('angular.json') || allDeps.containsKey('@angular/core')) {
        framework = FrameworkType.angular;
        port = 4200;
      } else if (files.contains('vite.config.js') || files.contains('vite.config.ts') || allDeps.containsKey('vite')) {
        framework = FrameworkType.vite;
        port = 5173;
      } else if (allDeps.containsKey('react') || allDeps.containsKey('react-dom')) {
        framework = FrameworkType.react;
        port = 3000;
      } else if (allDeps.containsKey('vue')) {
        framework = FrameworkType.vue;
        port = 8080;
      } else if (allDeps.containsKey('express')) {
        framework = FrameworkType.express;
        port = 3000;
      }

      // Database requirements in Node
      if (allDeps.containsKey('mongoose') || allDeps.containsKey('mongodb')) {
        database = DatabaseType.mongodb;
      } else if (allDeps.containsKey('pg') || allDeps.containsKey('typeorm') && allDeps.toString().contains('postgres')) {
        database = DatabaseType.postgresql;
      } else if (allDeps.containsKey('mysql') || allDeps.containsKey('mysql2')) {
        database = DatabaseType.mysql;
      } else if (allDeps.containsKey('better-sqlite3') || allDeps.containsKey('sqlite3')) {
        database = DatabaseType.sqlite;
      }

      // Test framework detection
      if (allDeps.containsKey('jest') || files.contains('jest.config.js') || files.contains('jest.config.ts')) {
        testFrameworks.add('jest');
      }
      if (allDeps.containsKey('vitest') || files.contains('vitest.config.ts')) {
        testFrameworks.add('vitest');
      }
      if (allDeps.containsKey('cypress')) {
        testFrameworks.add('cypress');
      }
      if (allDeps.containsKey('@playwright/test')) {
        testFrameworks.add('playwright');
      }
    } catch (_) {}

    return TechStack(
      language: ProgrammingLanguage.nodeJs,
      framework: framework,
      databaseRequirement: database,
      packageManager: packageManager,
      dependencyFiles: dependencyFiles,
      detectedScripts: scripts,
      recommendedPort: port,
      detectedTestFrameworks: testFrameworks,
    );
  }
}
