import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/constants/supported_technologies.dart';
import '../../core/models/tech_stack.dart';

class PythonDetector {
  static Future<TechStack?> detect(String dirPath, List<String> files) async {
    final hasReqs = files.contains('requirements.txt');
    final hasPipfile = files.contains('Pipfile');
    final hasPyproject = files.contains('pyproject.toml');
    final hasManagePy = files.contains('manage.py');
    final hasSetupPy = files.contains('setup.py');
    final hasAnyPy = files.any((f) => f.endsWith('.py'));

    if (!hasReqs && !hasPipfile && !hasPyproject && !hasManagePy && !hasSetupPy && !hasAnyPy) {
      return null;
    }

    FrameworkType framework = FrameworkType.generalPython;
    DatabaseType database = DatabaseType.sqlite;
    int port = 8000;
    String packageManager = 'pip';
    final dependencyFiles = <String>[];
    final testFrameworks = <String>[];

    if (files.contains('uv.lock')) {
      packageManager = 'uv';
      dependencyFiles.add('uv.lock');
    } else if (hasPyproject && (files.contains('poetry.lock') || await _fileContains(dirPath, 'pyproject.toml', 'tool.poetry'))) {
      packageManager = 'poetry';
      dependencyFiles.add('pyproject.toml');
    } else if (hasPipfile) {
      packageManager = 'pipenv';
      dependencyFiles.add('Pipfile');
    } else if (hasReqs) {
      packageManager = 'pip';
      dependencyFiles.add('requirements.txt');
    }

    // Read requirements / pyproject / manage.py to detect specific framework
    final allContent = StringBuffer();
    for (final f in ['requirements.txt', 'Pipfile', 'pyproject.toml']) {
      if (files.contains(f)) {
        try {
          final text = await File(p.join(dirPath, f)).readAsString();
          allContent.writeln(text.toLowerCase());
        } catch (_) {}
      }
    }
    final contentStr = allContent.toString();

    if (hasManagePy || contentStr.contains('django')) {
      framework = FrameworkType.django;
      port = 8000;
      database = DatabaseType.sqlite;
    } else if (contentStr.contains('fastapi') || contentStr.contains('uvicorn')) {
      framework = FrameworkType.fastApi;
      port = 8000;
    } else if (contentStr.contains('streamlit')) {
      framework = FrameworkType.streamlit;
      port = 8501;
    } else if (contentStr.contains('flask')) {
      framework = FrameworkType.flask;
      port = 5000;
    }

    if (contentStr.contains('psycopg2') || contentStr.contains('asyncpg')) {
      database = DatabaseType.postgresql;
    } else if (contentStr.contains('mysqlclient') || contentStr.contains('pymysql')) {
      database = DatabaseType.mysql;
    }

    if (contentStr.contains('pytest') || files.contains('pytest.ini') || files.contains('conftest.py')) {
      testFrameworks.add('pytest');
    } else if (files.any((f) => f.contains('test'))) {
      testFrameworks.add('unittest');
    }

    return TechStack(
      language: ProgrammingLanguage.python,
      framework: framework,
      databaseRequirement: database,
      packageManager: packageManager,
      dependencyFiles: dependencyFiles,
      recommendedPort: port,
      detectedTestFrameworks: testFrameworks,
    );
  }

  static Future<bool> _fileContains(String dirPath, String fileName, String query) async {
    try {
      final f = File(p.join(dirPath, fileName));
      if (await f.exists()) {
        final content = await f.readAsString();
        return content.contains(query);
      }
    } catch (_) {}
    return false;
  }
}

