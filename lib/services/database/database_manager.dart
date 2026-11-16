import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/constants/supported_technologies.dart';
import '../../core/models/project.dart';
import '../../core/utils/command_runner.dart';

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
  static Future<bool> ensureDatabaseExists({
    required String databaseName,
    String host = '127.0.0.1',
    int port = 3306,
    String username = 'root',
    String password = '',
    void Function(String output, bool isError)? onLine,
  }) async {
    final sanitized = databaseName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (sanitized.isEmpty) return false;

    final isOpen = await testConnection(type: DatabaseType.mysql, host: host, port: port);
    if (!isOpen) {
      onLine?.call('MySQL server not responding on $host:$port', true);
      return false;
    }

    // Method 1: Execute via PHP PDO (standard and zero-dependency if PHP is available)
    try {
      final script =
          '\$h="$host";\$p=$port;\$u="$username";\$pw="$password";'
          'try { '
          '\$pdo = new PDO("mysql:host=\$h;port=\$p", \$u, \$pw); '
          '\$pdo->exec("CREATE DATABASE IF NOT EXISTS `$sanitized` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"); '
          'echo "DB_OK"; '
          '} catch(Exception \$e) { echo "DB_ERR: " . \$e->getMessage(); exit(1); }';

      final res = await CommandRunner.run('php', ['-r', script]);
      if (res.isSuccess && res.stdout.contains('DB_OK')) {
        onLine?.call('✓ Database "$sanitized" created/verified on MySQL ($host:$port)', false);
        return true;
      }
    } catch (_) {}

    // Method 2: Execute via mysql CLI
    try {
      final args = ['-h', host, '-P', port.toString(), '-u', username];
      if (password.isNotEmpty) {
        args.add('-p$password');
      }
      args.addAll(['-e', 'CREATE DATABASE IF NOT EXISTS `$sanitized` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;']);
      final res = await CommandRunner.run('mysql', args);
      if (res.isSuccess) {
        onLine?.call('✓ Database "$sanitized" created/verified on MySQL via mysql CLI', false);
        return true;
      }
    } catch (_) {}

    return false;
  }

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
      final mysqlUp = await testConnection(type: DatabaseType.mysql, port: 3306);
      if (mysqlUp) {
        if (onLine != null) {
          onLine('Configuring and provisioning MySQL/MariaDB database: $sanitizedName...', false);
        }
        await ensureDatabaseExists(
          databaseName: sanitizedName,
          port: 3306,
          username: 'root',
          password: '',
          onLine: onLine,
        );
        project.envVariables = {
          ...project.envVariables,
          'DB_CONNECTION': 'mysql',
          'DB_HOST': '127.0.0.1',
          'DB_PORT': '3306',
          'DB_DATABASE': sanitizedName,
          'DB_USERNAME': 'root',
          'DB_PASSWORD': '',
        };
      } else {
        if (onLine != null) {
          onLine('ℹ️ MySQL not active on port 3306. Configuring isolated SQLite database for zero-config startup.', false);
        }
        final dbPath = p.join(project.localPath, 'database', 'database.sqlite');
        final dbFile = File(dbPath);
        if (!await dbFile.exists()) {
          await dbFile.parent.create(recursive: true);
          await dbFile.create();
        }
        project.envVariables = {
          ...project.envVariables,
          'DB_CONNECTION': 'sqlite',
          'DB_DATABASE': dbPath,
          'DATABASE_URL': 'sqlite://$dbPath',
        };
      }
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
    if (!await envFile.exists()) return;

    try {
      var content = await envFile.readAsString();

      for (final entry in project.envVariables.entries) {
        final key = entry.key;
        final val = entry.value;
        final regex = RegExp('^#?\\s*${RegExp.escape(key)}=.*\$', multiLine: true);
        if (regex.hasMatch(content)) {
          content = content.replaceFirst(regex, '$key=$val');
        } else {
          content += '\n$key=$val';
        }
      }

      // Ensure PORT
      final portRegex = RegExp(r'^#?\s*PORT=.*$', multiLine: true);
      if (portRegex.hasMatch(content)) {
        content = content.replaceFirst(portRegex, 'PORT=${project.port}');
      } else {
        content += '\nPORT=${project.port}';
      }

      await envFile.writeAsString(content);
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
