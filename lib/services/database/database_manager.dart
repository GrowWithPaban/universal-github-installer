import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/constants/supported_technologies.dart';
import '../../core/models/project.dart';

class DatabaseInstance {
  final String name;
  final DatabaseType type;
  final int port;
  bool isRunning;
  final String host;
  final String user;
  final String databaseName;

  DatabaseInstance({
    required this.name,
    required this.type,
    required this.port,
    this.isRunning = true,
    this.host = '127.0.0.1',
    this.user = 'root',
    required this.databaseName,
  });
}

class DatabaseManager {
  static Future<void> provisionDatabaseForProject(
    Project project, {
    void Function(String output, bool isError)? onLine,
  }) async {
    final dbType = project.databaseType;
    if (dbType == DatabaseType.none) return;

    final sanitizedName = project.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
    project.databaseName = sanitizedName;

    if (dbType == DatabaseType.sqlite) {
      final dbPath = p.join(project.localPath, 'database', 'database.sqlite');
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        await dbFile.parent.create(recursive: true);
        await dbFile.create();
        if (onLine != null) {
          onLine('✓ Created isolated SQLite database at: $dbPath', false);
        }
      }
      project.envVariables = {
        ...project.envVariables,
        'DB_CONNECTION': 'sqlite',
        'DB_DATABASE': dbPath,
        'DATABASE_URL': 'sqlite://$dbPath',
      };
    } else if (dbType == DatabaseType.mysql || dbType == DatabaseType.mariadb) {
      if (onLine != null) {
        onLine('Configuring MySQL/MariaDB database: $sanitizedName', false);
      }
      // Check if docker is available to spin up an isolated container if native is not running
      project.envVariables = {
        ...project.envVariables,
        'DB_CONNECTION': 'mysql',
        'DB_HOST': '127.0.0.1',
        'DB_PORT': '3306',
        'DB_DATABASE': sanitizedName,
        'DB_USERNAME': 'root',
        'DB_PASSWORD': '',
      };
    } else if (dbType == DatabaseType.postgresql) {
      if (onLine != null) {
        onLine('Configuring PostgreSQL database: $sanitizedName', false);
      }
      project.envVariables = {
        ...project.envVariables,
        'DB_CONNECTION': 'pgsql',
        'DB_HOST': '127.0.0.1',
        'DB_PORT': '5432',
        'DB_DATABASE': sanitizedName,
        'DB_USERNAME': 'postgres',
        'DB_PASSWORD': 'postgres',
      };
    } else if (dbType == DatabaseType.mongodb) {
      project.envVariables = {
        ...project.envVariables,
        'MONGODB_URI': 'mongodb://127.0.0.1:27017/$sanitizedName',
      };
    }

    // Write or update .env file with project's database credentials
    await writeEnvFile(project);
  }

  static Future<void> writeEnvFile(Project project) async {
    final envFile = File(p.join(project.localPath, '.env'));
    final lines = <String>[];

    Map<String, String> existing = {};
    if (await envFile.exists()) {
      try {
        final content = await envFile.readAsLines();
        for (final l in content) {
          final trimmed = l.trim();
          if (trimmed.isNotEmpty && !trimmed.startsWith('#') && trimmed.contains('=')) {
            final parts = trimmed.split('=');
            existing[parts[0].trim()] = parts.sublist(1).join('=').trim();
          }
        }
      } catch (_) {}
    }

    // Merge project env variables
    existing.addAll(project.envVariables);
    existing['PORT'] = project.port.toString();

    for (final entry in existing.entries) {
      lines.add('${entry.key}=${entry.value}');
    }

    try {
      await envFile.writeAsString(lines.join('\n'));
    } catch (_) {}
  }

  static Future<bool> testConnection({
    required DatabaseType type,
    String host = '127.0.0.1',
    int? port,
    String? database,
    String? user,
    String? password,
  }) async {
    if (type == DatabaseType.none) return true;

    if (type == DatabaseType.sqlite) {
      if (database != null && database.isNotEmpty) {
        return File(database).exists();
      }
      return true;
    }

    // Check socket connectivity to database port
    final targetPort = port ?? (type == DatabaseType.mysql ? 3306 : type == DatabaseType.postgresql ? 5432 : 27017);
    try {
      final socket = await Socket.connect(host, targetPort, timeout: const Duration(seconds: 2));
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<DatabaseInstance>> getKnownDatabases() async {
    final list = <DatabaseInstance>[];

    // Check MySQL on 3306
    final mysqlUp = await testConnection(type: DatabaseType.mysql, port: 3306);
    list.add(DatabaseInstance(
      name: 'Default MySQL / MariaDB Server',
      type: DatabaseType.mysql,
      port: 3306,
      isRunning: mysqlUp,
      databaseName: 'mysql',
    ));

    // Check PostgreSQL on 5432
    final pgUp = await testConnection(type: DatabaseType.postgresql, port: 5432);
    list.add(DatabaseInstance(
      name: 'Default PostgreSQL Server',
      type: DatabaseType.postgresql,
      port: 5432,
      isRunning: pgUp,
      databaseName: 'postgres',
    ));

    // Check MongoDB on 27017
    final mongoUp = await testConnection(type: DatabaseType.mongodb, port: 27017);
    list.add(DatabaseInstance(
      name: 'Default MongoDB Instance',
      type: DatabaseType.mongodb,
      port: 27017,
      isRunning: mongoUp,
      databaseName: 'admin',
    ));

    return list;
  }
}
