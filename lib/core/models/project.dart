import '../constants/supported_technologies.dart';
import 'tech_stack.dart';
import 'installation_plan.dart';

class Project {
  final String id;
  String name;
  String githubUrl;
  String localPath;
  TechStack techStack;
  ProjectState status;
  int port;
  String? localUrl;
  String? runtimeVersion;
  DatabaseType databaseType;
  String? databaseName;
  Map<String, String> envVariables;
  DateTime createdAt;
  DateTime? lastStartedAt;
  InstallationPlan? installationPlan;
  String? lastError;

  Project({
    required this.id,
    required this.name,
    required this.githubUrl,
    required this.localPath,
    required this.techStack,
    this.status = ProjectState.notInstalled,
    this.port = 3000,
    this.localUrl,
    this.runtimeVersion,
    this.databaseType = DatabaseType.none,
    this.databaseName,
    this.envVariables = const {},
    DateTime? createdAt,
    this.lastStartedAt,
    this.installationPlan,
    this.lastError,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayUrl => localUrl ?? 'http://localhost:$port';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'githubUrl': githubUrl,
    'localPath': localPath,
    'techStack': techStack.toJson(),
    'status': status.name,
    'port': port,
    'localUrl': localUrl,
    'runtimeVersion': runtimeVersion,
    'databaseType': databaseType.name,
    'databaseName': databaseName,
    'envVariables': envVariables,
    'createdAt': createdAt.toIso8601String(),
    'lastStartedAt': lastStartedAt?.toIso8601String(),
    'installationPlan': installationPlan?.toJson(),
    'lastError': lastError,
  };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      githubUrl: json['githubUrl'] as String,
      localPath: json['localPath'] as String,
      techStack: TechStack.fromJson(json['techStack'] as Map<String, dynamic>),
      status: ProjectState.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProjectState.notInstalled,
      ),
      port: (json['port'] as num?)?.toInt() ?? 3000,
      localUrl: json['localUrl'] as String?,
      runtimeVersion: json['runtimeVersion'] as String?,
      databaseType: DatabaseType.values.firstWhere(
        (e) => e.name == json['databaseType'],
        orElse: () => DatabaseType.none,
      ),
      databaseName: json['databaseName'] as String?,
      envVariables: Map<String, String>.from(json['envVariables'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastStartedAt: json['lastStartedAt'] != null
          ? DateTime.parse(json['lastStartedAt'] as String)
          : null,
      installationPlan: json['installationPlan'] != null
          ? InstallationPlan.fromJson(json['installationPlan'] as Map<String, dynamic>)
          : null,
      lastError: json['lastError'] as String?,
    );
  }

  Project copyWith({
    String? name,
    String? githubUrl,
    String? localPath,
    TechStack? techStack,
    ProjectState? status,
    int? port,
    String? localUrl,
    String? runtimeVersion,
    DatabaseType? databaseType,
    String? databaseName,
    Map<String, String>? envVariables,
    DateTime? lastStartedAt,
    InstallationPlan? installationPlan,
    String? lastError,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      githubUrl: githubUrl ?? this.githubUrl,
      localPath: localPath ?? this.localPath,
      techStack: techStack ?? this.techStack,
      status: status ?? this.status,
      port: port ?? this.port,
      localUrl: localUrl ?? this.localUrl,
      runtimeVersion: runtimeVersion ?? this.runtimeVersion,
      databaseType: databaseType ?? this.databaseType,
      databaseName: databaseName ?? this.databaseName,
      envVariables: envVariables ?? this.envVariables,
      createdAt: createdAt,
      lastStartedAt: lastStartedAt ?? this.lastStartedAt,
      installationPlan: installationPlan ?? this.installationPlan,
      lastError: lastError ?? this.lastError,
    );
  }
}
