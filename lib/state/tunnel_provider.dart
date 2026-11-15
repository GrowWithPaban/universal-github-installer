import 'package:flutter/material.dart';
import '../core/models/project.dart';
import '../core/models/tunnel_info.dart';
import '../services/tunnel/tailscale_service.dart';
import '../services/tunnel/tunnel_manager.dart';

class TunnelProvider extends ChangeNotifier {
  final TunnelManager _manager = TunnelManager();
  bool _isLoading = false;
  String? _statusMessage;
  TailscaleNodeInfo? _tailscaleNode;

  List<TunnelInfo> get activeTunnels => _manager.activeTunnels;
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;
  TailscaleNodeInfo? get tailscaleNode => _tailscaleNode;

  TunnelInfo? getTunnelForProject(String projectId) => _manager.getTunnelForProject(projectId);

  Future<void> checkTailscale() async {
    _tailscaleNode = await TailscaleService.getStatus();
    notifyListeners();
  }

  Future<TunnelInfo?> exposeProject(
    Project project, {
    TunnelServiceType provider = TunnelServiceType.tailscaleFunnel,
  }) async {
    _isLoading = true;
    _statusMessage = 'Initiating ${provider.displayName} for ${project.name}...';
    notifyListeners();

    try {
      final tunnel = await _manager.exposeProject(
        project,
        provider: provider,
        onStatusChange: (msg) {
          _statusMessage = msg;
          notifyListeners();
        },
      );
      _isLoading = false;
      notifyListeners();
      return tunnel;
    } catch (e) {
      _isLoading = false;
      _statusMessage = 'Failed to expose project: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> stopTunnel(String projectId) async {
    await _manager.stopTunnel(projectId);
    notifyListeners();
  }
}
