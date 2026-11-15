enum RuntimeType {
  node,
  npm,
  pnpm,
  yarn,
  python,
  pip,
  poetry,
  uv,
  php,
  composer,
  git,
  docker,
  sqlite3,
  mysql,
  postgres,
  cloudflared;

  String get displayName {
    switch (this) {
      case RuntimeType.node:
        return 'Node.js';
      case RuntimeType.npm:
        return 'npm';
      case RuntimeType.pnpm:
        return 'pnpm';
      case RuntimeType.yarn:
        return 'Yarn';
      case RuntimeType.python:
        return 'Python';
      case RuntimeType.pip:
        return 'pip';
      case RuntimeType.poetry:
        return 'Poetry';
      case RuntimeType.uv:
        return 'uv';
      case RuntimeType.php:
        return 'PHP';
      case RuntimeType.composer:
        return 'Composer';
      case RuntimeType.git:
        return 'Git';
      case RuntimeType.docker:
        return 'Docker';
      case RuntimeType.sqlite3:
        return 'SQLite 3';
      case RuntimeType.mysql:
        return 'MySQL';
      case RuntimeType.postgres:
        return 'PostgreSQL';
      case RuntimeType.cloudflared:
        return 'Cloudflared (Tunnel)';
    }
  }
}

class RuntimeInfo {
  final RuntimeType type;
  final bool isInstalled;
  final String? version;
  final String? binaryPath;
  final String? installCommandWindows;
  final String? installCommandMac;

  const RuntimeInfo({
    required this.type,
    required this.isInstalled,
    this.version,
    this.binaryPath,
    this.installCommandWindows,
    this.installCommandMac,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'isInstalled': isInstalled,
    'version': version,
    'binaryPath': binaryPath,
    'installCommandWindows': installCommandWindows,
    'installCommandMac': installCommandMac,
  };

  factory RuntimeInfo.fromJson(Map<String, dynamic> json) {
    return RuntimeInfo(
      type: RuntimeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RuntimeType.node,
      ),
      isInstalled: json['isInstalled'] as bool? ?? false,
      version: json['version'] as String?,
      binaryPath: json['binaryPath'] as String?,
      installCommandWindows: json['installCommandWindows'] as String?,
      installCommandMac: json['installCommandMac'] as String?,
    );
  }
}
