class LogEntry {
  final DateTime timestamp;
  final String text;
  final bool isError;

  const LogEntry({
    required this.timestamp,
    required this.text,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'text': text,
    'isError': isError,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      text: json['text'] as String,
      isError: json['isError'] as bool? ?? false,
    );
  }
}

class ProjectProcessInfo {
  final String projectId;
  final int pid;
  final DateTime startedAt;
  final int port;
  final List<LogEntry> logs;
  bool isHealthy;

  ProjectProcessInfo({
    required this.projectId,
    required this.pid,
    required this.startedAt,
    required this.port,
    List<LogEntry>? logs,
    this.isHealthy = true,
  }) : logs = logs ?? [];
}

