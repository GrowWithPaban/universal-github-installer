import 'package:flutter/material.dart';
import '../core/models/tunnel_info.dart';
import '../core/models/project.dart';
import '../services/tunnel/tunnel_manager.dart';

class TunnelProvider extends ChangeNotifier {
  final TunnelManager _manager = TunnelManager();
  bool _isLoading = false;
  String? _statusMessage;

  List<TunnelInfo> get activeTunnels => _manager.activeTunnels;
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;

  TunnelInfo? getTunnelForProject(String projectId) => _manager.getTunnelForProject(projectId);

  Future<TunnelInfo?> exposeProject(Project project) async {
    _isLoading = true;
    _statusMessage = 'Starting tunnel for ${project.name}...';
    notifyListeners();

    try {
      final tunnel = await _manager.exposeProject(
        project,
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
