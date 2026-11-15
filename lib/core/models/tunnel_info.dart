enum TunnelStatus {
  inactive,
  starting,
  active,
  error,
}

enum TunnelServiceType {
  cloudflare,
  custom,
}

class TunnelInfo {
  final String id;
  final String projectId;
  final String projectName;
  final int localPort;
  final TunnelServiceType provider;
  String? publicUrl;
  TunnelStatus status;
  DateTime? startedAt;
  String? errorMessage;
  int? processPid;

  TunnelInfo({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.localPort,
    this.provider = TunnelServiceType.cloudflare,
    this.publicUrl,
    this.status = TunnelStatus.inactive,
    this.startedAt,
    this.errorMessage,
    this.processPid,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'projectName': projectName,
    'localPort': localPort,
    'provider': provider.name,
    'publicUrl': publicUrl,
    'status': status.name,
    'startedAt': startedAt?.toIso8601String(),
    'errorMessage': errorMessage,
    'processPid': processPid,
  };

  factory TunnelInfo.fromJson(Map<String, dynamic> json) {
    return TunnelInfo(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      localPort: (json['localPort'] as num).toInt(),
      provider: TunnelServiceType.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => TunnelServiceType.cloudflare,
      ),
      publicUrl: json['publicUrl'] as String?,
      status: TunnelStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TunnelStatus.inactive,
      ),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      processPid: (json['processPid'] as num?)?.toInt(),
    );
  }
}

