import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/constants/supported_technologies.dart';
import '../../core/models/installation_plan.dart';
import '../../core/models/project.dart';
import '../../core/utils/command_runner.dart';
import '../database/database_manager.dart';

class DependencyInstaller {
  static InstallationPlan generatePlan(Project project) {
    final steps = <InstallationStep>[];
    final tech = project.techStack;
    final path = project.localPath;
    final port = project.port;

    String startCmd = 'node';
    List<String> startArgs = ['index.js'];
    final envVars = <String, String>{
      'PORT': port.toString(),
      ...project.envVariables,
    };

    switch (tech.language) {
      case ProgrammingLanguage.php:
        if (tech.framework == FrameworkType.laravel) {
          steps.add(InstallationStep(
            id: 'composer_install',
            title: 'Install Composer Dependencies',
            description: 'Run composer install --no-interaction',
            command: 'composer',
            args: ['install', '--no-interaction', '--prefer-dist'],
            workingDirectory: path,
          ));
          steps.add(InstallationStep(
            id: 'env_setup',
            title: 'Setup Environment Configuration',
            description: 'Copy .env.example to .env if not exists',
            command: 'php',
            args: ['-r', 'if (!file_exists(".env") && file_exists(".env.example")) copy(".env.example", ".env");'],
            workingDirectory: path,
          ));
          steps.add(InstallationStep(
            id: 'artisan_key',
            title: 'Generate Application Encryption Key',
            description: 'Run php artisan key:generate',
            command: 'php',
            args: ['artisan', 'key:generate', '--force'],
            workingDirectory: path,
          ));
          if (File(p.join(path, 'package.json')).existsSync()) {
            steps.add(InstallationStep(
              id: 'npm_install',
              title: 'Install Frontend Dependencies',
              description: 'Install npm packages for frontend assets',
              command: 'npm',
              args: ['install'],
              workingDirectory: path,
            ));
            steps.add(InstallationStep(
              id: 'npm_build',
              title: 'Build Production Frontend Assets',
              description: 'Run npm run build to compile Vite / Tailwind assets',
              command: 'npm',
              args: ['run', 'build'],
              workingDirectory: path,
            ));
          }
          steps.add(InstallationStep(
            id: 'artisan_migrate',
            title: 'Run Database Migrations',
            description: 'Run php artisan migrate --force',
            command: 'php',
            args: ['artisan', 'migrate', '--force'],
            workingDirectory: path,
            isDestructive: true,
            requiresUserApproval: true,
          ));
          startCmd = 'php';
          startArgs = ['artisan', 'serve', '--host=127.0.0.1', '--port=$port'];
        } else {
          if (tech.packageManager == 'composer') {
            steps.add(InstallationStep(
              id: 'composer_install',
              title: 'Install Composer Packages',
              description: 'Run composer install',
              command: 'composer',
              args: ['install'],
              workingDirectory: path,
            ));
          }
          startCmd = 'php';
          startArgs = ['-S', '127.0.0.1:$port'];
        }
        break;

      case ProgrammingLanguage.nodeJs:
        final pkgMgr = tech.packageManager ?? 'npm';
        steps.add(InstallationStep(
          id: 'node_install_deps',
          title: 'Install Node Dependencies',
          description: 'Run $pkgMgr install',
          command: pkgMgr,
          args: ['install'],
          workingDirectory: path,
        ));

        // Check for Prisma migrations
        if (Directory(p.join(path, 'prisma')).existsSync()) {
          steps.add(InstallationStep(
            id: 'prisma_generate',
            title: 'Generate Prisma Client & DB Push',
            description: 'Run npx prisma generate',
            command: 'npx',
            args: ['prisma', 'generate'],
            workingDirectory: path,
          ));
        }

        // Determine start command
        if (tech.detectedScripts.contains('dev')) {
          startCmd = pkgMgr;
          if (tech.framework == FrameworkType.vite) {
            startArgs = ['run', 'dev', '--', '--host', '127.0.0.1', '--port', '$port'];
          } else {
            startArgs = ['run', 'dev', '--', '--port', '$port'];
          }
        } else if (tech.detectedScripts.contains('start')) {
          startCmd = pkgMgr;
          startArgs = ['start'];
        } else {
          startCmd = 'node';
          startArgs = ['index.js'];
        }
        break;

      case ProgrammingLanguage.python:
        final isWin = Platform.isWindows;
        final venvPython = isWin ? p.join(path, '.venv', 'Scripts', 'python.exe') : p.join(path, '.venv', 'bin', 'python');
        final venvPip = isWin ? p.join(path, '.venv', 'Scripts', 'pip.exe') : p.join(path, '.venv', 'bin', 'pip');

        // Step 1: Create venv
        steps.add(InstallationStep(
          id: 'py_venv',
          title: 'Create Isolated Python Virtual Environment',
          description: 'Run python -m venv .venv',
          command: isWin ? 'python' : 'python3',
          args: ['-m', 'venv', '.venv'],
          workingDirectory: path,
        ));

        // Step 2: Install requirements
        if (File(p.join(path, 'requirements.txt')).existsSync()) {
          steps.add(InstallationStep(
            id: 'py_requirements',
            title: 'Install Python Requirements',
            description: 'Run pip install -r requirements.txt',
            command: venvPip,
            args: ['install', '-r', 'requirements.txt'],
            workingDirectory: path,
          ));
        } else if (File(p.join(path, 'pyproject.toml')).existsSync()) {
          steps.add(InstallationStep(
            id: 'py_install_project',
            title: 'Install Python Package',
            description: 'Run pip install .',
            command: venvPip,
            args: ['install', '.'],
            workingDirectory: path,
          ));
        }

        if (tech.framework == FrameworkType.django) {
          steps.add(InstallationStep(
            id: 'django_migrate',
            title: 'Run Django Migrations',
            description: 'Run python manage.py migrate',
            command: venvPython,
            args: ['manage.py', 'migrate'],
            workingDirectory: path,
            isDestructive: true,
            requiresUserApproval: true,
          ));
          startCmd = venvPython;
          startArgs = ['manage.py', 'runserver', '127.0.0.1:$port'];
        } else if (tech.framework == FrameworkType.fastApi) {
          startCmd = venvPython;
          startArgs = ['-m', 'uvicorn', 'main:app', '--host', '127.0.0.1', '--port', '$port'];
        } else if (tech.framework == FrameworkType.streamlit) {
          startCmd = venvPython;
          startArgs = ['-m', 'streamlit', 'run', 'app.py', '--server.port', '$port'];
        } else if (tech.framework == FrameworkType.flask) {
          startCmd = venvPython;
          startArgs = ['-m', 'flask', 'run', '--host=127.0.0.1', '--port=$port'];
        } else {
          startCmd = venvPython;
          startArgs = ['main.py'];
        }
        break;

      case ProgrammingLanguage.dockerCompose:
        steps.add(InstallationStep(
          id: 'docker_up',
          title: 'Start Docker Compose Stack',
          description: 'Run docker compose up -d',
          command: 'docker',
          args: ['compose', 'up', '-d'],
          workingDirectory: path,
        ));
        startCmd = 'docker';
        startArgs = ['compose', 'logs', '-f'];
        break;

      case ProgrammingLanguage.staticWeb:
        startCmd = Platform.isWindows ? 'python' : 'python3';
        startArgs = ['-m', 'http.server', '$port'];
        break;

      default:
        startCmd = 'echo';
        startArgs = ['No start command configured for this project'];
        break;
    }

    return InstallationPlan(
      projectId: project.id,
      steps: steps,
      startCommand: startCmd,
      startArgs: startArgs,
      assignedPort: port,
      requiredEnvVars: envVars,
    );
  }

  static Future<bool> executeStep(
    InstallationStep step, {
    Map<String, String>? env,
    required void Function(String output, bool isError) onLine,
  }) async {
    step.isRunning = true;
    step.errorMessage = null;

    onLine('>>> Executing: ${step.command} ${step.args.join(" ")}', false);

    final res = await CommandRunner.run(
      step.command,
      step.args,
      workingDirectory: step.workingDirectory,
      environment: env,
      onLine: onLine,
    );

    step.isRunning = false;
    if (res.isSuccess) {
      step.completed = true;
      onLine('✓ Step completed: ${step.title}\n', false);
      return true;
    } else {
      step.completed = false;
      step.errorMessage = res.stderr.isNotEmpty ? res.stderr : 'Step failed with code ${res.exitCode}';
      onLine('✗ Step failed: ${step.errorMessage}\n', true);
      return false;
    }
  }

  static Future<bool> executeAllSteps(
    InstallationPlan plan, {
    required Project project,
    required void Function(String output, bool isError) onLine,
    required Future<bool> Function(InstallationStep step) requestApproval,
  }) async {
    // Also provision database if required
    await DatabaseManager.provisionDatabaseForProject(project, onLine: onLine);

    for (final step in plan.steps) {
      if (step.requiresUserApproval) {
        final approved = await requestApproval(step);
        if (!approved) {
          onLine('User skipped or declined step: ${step.title}', false);
          continue;
        }
      }

      final success = await executeStep(
        step,
        env: plan.requiredEnvVars,
        onLine: onLine,
      );

      if (!success && !step.isDestructive) {
        // Stop on critical failure
        return false;
      }
    }
    return true;
  }
}
