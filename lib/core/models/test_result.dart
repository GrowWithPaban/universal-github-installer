class TestCaseResult {
  final String name;
  final bool passed;
  final String? failureMessage;
  final Duration duration;

  const TestCaseResult({
    required this.name,
    required this.passed,
    this.failureMessage,
    this.duration = Duration.zero,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'passed': passed,
    'failureMessage': failureMessage,
    'durationMs': duration.inMilliseconds,
  };

  factory TestCaseResult.fromJson(Map<String, dynamic> json) {
    return TestCaseResult(
      name: json['name'] as String,
      passed: json['passed'] as bool,
      failureMessage: json['failureMessage'] as String?,
      duration: Duration(milliseconds: (json['durationMs'] as num?)?.toInt() ?? 0),
    );
  }
}

class TestSuiteReport {
  final String projectId;
  final String framework;
  final DateTime executedAt;
  final int totalCount;
  final int passedCount;
  final int failedCount;
  final Duration totalDuration;
  final List<TestCaseResult> tests;
  final String rawOutput;
  final bool httpHealthCheckPassed;
  final String? dbConnectionStatus;

  const TestSuiteReport({
    required this.projectId,
    required this.framework,
    required this.executedAt,
    required this.totalCount,
    required this.passedCount,
    required this.failedCount,
    required this.totalDuration,
    this.tests = const [],
    this.rawOutput = '',
    this.httpHealthCheckPassed = true,
    this.dbConnectionStatus,
  });

  bool get allPassed => failedCount == 0 && httpHealthCheckPassed;

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'framework': framework,
    'executedAt': executedAt.toIso8601String(),
    'totalCount': totalCount,
    'passedCount': passedCount,
    'failedCount': failedCount,
    'totalDurationMs': totalDuration.inMilliseconds,
    'tests': tests.map((t) => t.toJson()).toList(),
    'rawOutput': rawOutput,
    'httpHealthCheckPassed': httpHealthCheckPassed,
    'dbConnectionStatus': dbConnectionStatus,
  };

  factory TestSuiteReport.fromJson(Map<String, dynamic> json) {
    return TestSuiteReport(
      projectId: json['projectId'] as String,
      framework: json['framework'] as String,
      executedAt: DateTime.parse(json['executedAt'] as String),
      totalCount: (json['totalCount'] as num).toInt(),
      passedCount: (json['passedCount'] as num).toInt(),
      failedCount: (json['failedCount'] as num).toInt(),
      totalDuration: Duration(milliseconds: (json['totalDurationMs'] as num?)?.toInt() ?? 0),
      tests: (json['tests'] as List? ?? [])
          .map((t) => TestCaseResult.fromJson(t as Map<String, dynamic>))
          .toList(),
      rawOutput: json['rawOutput'] as String? ?? '',
      httpHealthCheckPassed: json['httpHealthCheckPassed'] as bool? ?? true,
      dbConnectionStatus: json['dbConnectionStatus'] as String?,
    );
  }
}

