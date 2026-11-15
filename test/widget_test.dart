import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:github_installer/core/constants/supported_technologies.dart';
import 'package:github_installer/core/models/project.dart';
import 'package:github_installer/core/models/tech_stack.dart';
import 'package:github_installer/core/utils/secret_scanner.dart';
import 'package:github_installer/services/github/github_service.dart';
import 'package:github_installer/services/detection/tech_detector.dart';
import 'package:github_installer/services/runtime/dependency_installer.dart';
import 'package:github_installer/state/app_state.dart';
import 'package:github_installer/state/process_provider.dart';
import 'package:github_installer/state/projects_provider.dart';
import 'package:github_installer/state/runtime_provider.dart';
import 'package:github_installer/state/tunnel_provider.dart';
import 'package:github_installer/main.dart';

void main() {
  group('Phase 2 & 3: GitHub Service and Technology Detection Tests', () {
    test('GitHub URL validator correctly parses repositories', () {
      expect(GitHubService.isValidGitHubUrl('https://github.com/laravel/laravel'), isTrue);
      expect(GitHubService.isValidGitHubUrl('https://github.com/vercel/next.js.git'), isTrue);
      expect(GitHubService.isValidGitHubUrl('git@github.com:facebook/react.git'), isTrue);
      expect(GitHubService.isValidGitHubUrl('https://google.com'), isFalse);

      final parsed = GitHubService.parseUrl('https://github.com/torvalds/linux.git');
      expect(parsed, isNotNull);
      expect(parsed!.owner, 'torvalds');
      expect(parsed.repo, 'linux');
    });

    test('TechDetector correctly identifies Node.js projects', () async {
      final tempDir = await Directory.systemTemp.createTemp('node_test_');
      final pkgJson = File('${tempDir.path}/package.json');
      await pkgJson.writeAsString('{"dependencies": {"express": "^4.18.0"}}');

      final detected = await TechDetector.detect(tempDir.path);
      expect(detected.language, ProgrammingLanguage.nodeJs);
      expect(detected.framework, FrameworkType.express);
      expect(detected.recommendedPort, 3000);

      await tempDir.delete(recursive: true);
    });

    test('TechDetector correctly identifies Python Django projects', () async {
      final tempDir = await Directory.systemTemp.createTemp('python_test_');
      final managePy = File('${tempDir.path}/manage.py');
      await managePy.writeAsString('#!/usr/bin/env python');

      final detected = await TechDetector.detect(tempDir.path);
      expect(detected.language, ProgrammingLanguage.python);
      expect(detected.framework, FrameworkType.django);
      expect(detected.recommendedPort, 8000);

      await tempDir.delete(recursive: true);
    });

    test('TechDetector correctly identifies PHP Laravel projects', () async {
      final tempDir = await Directory.systemTemp.createTemp('php_test_');
      final composerJson = File('${tempDir.path}/composer.json');
      await composerJson.writeAsString('{"require": {"laravel/framework": "^11.0"}}');
      final artisan = File('${tempDir.path}/artisan');
      await artisan.writeAsString('#!/usr/bin/env php');

      final detected = await TechDetector.detect(tempDir.path);
      expect(detected.language, ProgrammingLanguage.php);
      expect(detected.framework, FrameworkType.laravel);
      expect(detected.databaseRequirement, DatabaseType.mysql);

      await tempDir.delete(recursive: true);
    });
  });

  group('Phase 4 & 6: Installation Plan and Multiple Project Management', () {
    test('DependencyInstaller generates appropriate steps for Laravel', () {
      final project = Project(
        id: 'proj_1',
        name: 'My Laravel App',
        githubUrl: 'https://github.com/laravel/laravel',
        localPath: '/tmp/test_laravel',
        techStack: const TechStack(
          language: ProgrammingLanguage.php,
          framework: FrameworkType.laravel,
          packageManager: 'composer',
        ),
      );

      final plan = DependencyInstaller.generatePlan(project);
      expect(plan.steps.any((s) => s.id == 'composer_install'), isTrue);
      expect(plan.steps.any((s) => s.id == 'artisan_key'), isTrue);
      expect(plan.steps.any((s) => s.id == 'artisan_migrate'), isTrue);
      expect(plan.startCommand, 'php');
    });

    test('DependencyInstaller generates appropriate steps for Node.js', () {
      final project = Project(
        id: 'proj_2',
        name: 'My Node App',
        githubUrl: 'https://github.com/user/node-app',
        localPath: '/tmp/test_node',
        techStack: const TechStack(
          language: ProgrammingLanguage.nodeJs,
          framework: FrameworkType.express,
          packageManager: 'npm',
          detectedScripts: ['dev'],
        ),
      );

      final plan = DependencyInstaller.generatePlan(project);
      expect(plan.steps.any((s) => s.id == 'node_install_deps'), isTrue);
      expect(plan.startCommand, 'npm');
      expect(plan.startArgs.contains('dev'), isTrue);
    });
  });

  group('Phase 12 & 13: Security Secret Scanner Tests', () {
    test('SecretScanner identifies suspicious secrets', () async {
      final tempDir = await Directory.systemTemp.createTemp('sec_test_');
      final envFile = File('${tempDir.path}/config.env');
      await envFile.writeAsString('GITHUB_TOKEN=ghp_abcdefghijklmnopqrstuvwxyz1234567890\n');

      final findings = await SecretScanner.scanDirectory(tempDir.path);
      expect(findings.isNotEmpty, isTrue);
      expect(findings.first.severity, 'High');

      await tempDir.delete(recursive: true);
    });
  });

  group('Phase 1: Flutter Desktop UI Smoke Tests', () {
    testWidgets('App renders MainLayout and Sidebar successfully', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppState()),
            ChangeNotifierProvider(create: (_) => ProjectsProvider()),
            ChangeNotifierProvider(create: (_) => ProcessProvider()),
            ChangeNotifierProvider(create: (_) => RuntimeProvider()),
            ChangeNotifierProvider(create: (_) => TunnelProvider()),
          ],
          child: const GitHubInstallerApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('GitHub Installer'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Install New Project'), findsWidgets);
      expect(find.text('My Projects'), findsOneWidget);
      expect(find.text('Running Projects'), findsOneWidget);
      expect(find.text('Database Manager'), findsOneWidget);
      expect(find.text('Runtime Manager'), findsOneWidget);
      expect(find.text('Testing Center'), findsOneWidget);
      expect(find.text('Tunnel Manager'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });
  });
}
