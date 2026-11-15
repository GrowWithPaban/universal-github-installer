import '../constants/supported_technologies.dart';

class TechStack {
  final ProgrammingLanguage language;
  final FrameworkType framework;
  final DatabaseType databaseRequirement;
  final String? packageManager; // npm, yarn, pnpm, composer, pip, poetry, uv
  final List<String> dependencyFiles;
  final List<String> detectedScripts;
  final String? runtimeVersionRequired;
  final int recommendedPort;
  final List<String> environmentFiles;
  final List<String> detectedTestFrameworks;
  final bool hasDockerCompose;

  const TechStack({
    required this.language,
    required this.framework,
    this.databaseRequirement = DatabaseType.none,
    this.packageManager,
    this.dependencyFiles = const [],
    this.detectedScripts = const [],
    this.runtimeVersionRequired,
    this.recommendedPort = 3000,
    this.environmentFiles = const [],
    this.detectedTestFrameworks = const [],
    this.hasDockerCompose = false,
  });

  Map<String, dynamic> toJson() => {
    'language': language.name,
    'framework': framework.name,
    'databaseRequirement': databaseRequirement.name,
    'packageManager': packageManager,
    'dependencyFiles': dependencyFiles,
    'detectedScripts': detectedScripts,
    'runtimeVersionRequired': runtimeVersionRequired,
    'recommendedPort': recommendedPort,
    'environmentFiles': environmentFiles,
    'detectedTestFrameworks': detectedTestFrameworks,
    'hasDockerCompose': hasDockerCompose,
  };

  factory TechStack.fromJson(Map<String, dynamic> json) {
    return TechStack(
      language: ProgrammingLanguage.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => ProgrammingLanguage.unknown,
      ),
      framework: FrameworkType.values.firstWhere(
        (e) => e.name == json['framework'],
        orElse: () => FrameworkType.custom,
      ),
      databaseRequirement: DatabaseType.values.firstWhere(
        (e) => e.name == json['databaseRequirement'],
        orElse: () => DatabaseType.none,
      ),
      packageManager: json['packageManager'] as String?,
      dependencyFiles: List<String>.from(json['dependencyFiles'] ?? []),
      detectedScripts: List<String>.from(json['detectedScripts'] ?? []),
      runtimeVersionRequired: json['runtimeVersionRequired'] as String?,
      recommendedPort: (json['recommendedPort'] as num?)?.toInt() ?? 3000,
      environmentFiles: List<String>.from(json['environmentFiles'] ?? []),
      detectedTestFrameworks: List<String>.from(json['detectedTestFrameworks'] ?? []),
      hasDockerCompose: json['hasDockerCompose'] as bool? ?? false,
    );
  }
}

