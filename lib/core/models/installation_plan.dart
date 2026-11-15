class InstallationStep {
  final String id;
  final String title;
  final String description;
  final String command;
  final List<String> args;
  final String? workingDirectory;
  final bool isDestructive;
  final bool requiresUserApproval;
  bool completed;
  bool isRunning;
  String? errorMessage;

  InstallationStep({
    required this.id,
    required this.title,
    required this.description,
    required this.command,
    this.args = const [],
    this.workingDirectory,
    this.isDestructive = false,
    this.requiresUserApproval = false,
    this.completed = false,
    this.isRunning = false,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'command': command,
    'args': args,
    'workingDirectory': workingDirectory,
    'isDestructive': isDestructive,
    'requiresUserApproval': requiresUserApproval,
    'completed': completed,
    'isRunning': isRunning,
    'errorMessage': errorMessage,
  };

  factory InstallationStep.fromJson(Map<String, dynamic> json) {
    return InstallationStep(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      command: json['command'] as String,
      args: List<String>.from(json['args'] ?? []),
      workingDirectory: json['workingDirectory'] as String?,
      isDestructive: json['isDestructive'] as bool? ?? false,
      requiresUserApproval: json['requiresUserApproval'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      isRunning: json['isRunning'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

class InstallationPlan {
  final String projectId;
  final List<InstallationStep> steps;
  final String startCommand;
  final List<String> startArgs;
  final int assignedPort;
  final Map<String, String> requiredEnvVars;

  InstallationPlan({
    required this.projectId,
    required this.steps,
    required this.startCommand,
    this.startArgs = const [],
    required this.assignedPort,
    this.requiredEnvVars = const {},
  });

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'steps': steps.map((s) => s.toJson()).toList(),
    'startCommand': startCommand,
    'startArgs': startArgs,
    'assignedPort': assignedPort,
    'requiredEnvVars': requiredEnvVars,
  };

  factory InstallationPlan.fromJson(Map<String, dynamic> json) {
    return InstallationPlan(
      projectId: json['projectId'] as String,
      steps: (json['steps'] as List)
          .map((s) => InstallationStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      startCommand: json['startCommand'] as String,
      startArgs: List<String>.from(json['startArgs'] ?? []),
      assignedPort: (json['assignedPort'] as num).toInt(),
      requiredEnvVars: Map<String, String>.from(json['requiredEnvVars'] ?? {}),
    );
  }
}
