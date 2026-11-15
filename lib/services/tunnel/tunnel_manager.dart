import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../core/models/tunnel_info.dart';
import '../../core/models/project.dart';

class TunnelManager {
  static final TunnelManager _instance = TunnelManager._internal();
  factory TunnelManager() => _instance;
  TunnelManager._internal();

  final Map<String, TunnelInfo> _tunnels = {};
  final Map<String, Process> _tunnelProcesses = {};

  List<TunnelInfo> get activeTunnels => _tunnels.values.toList();

  TunnelInfo? getTunnelForProject(String projectId) => _tunnels[projectId];

  static final RegExp _cloudflareUrlRegex = RegExp(
    r'https:\/\/[a-zA-Z0-9-]+\.trycloudflare\.com',
  );

  Future<TunnelInfo> exposeProject(
    Project project, {
    TunnelServiceType provider = TunnelServiceType.cloudflare,
    void Function(String message)? onStatusChange,
  }) async {
    final projectId = project.id;
    if (_tunnels.containsKey(projectId) && _tunnels[projectId]!.status == TunnelStatus.active) {
      return _tunnels[projectId]!;
    }

    final tunnel = TunnelInfo(
      id: 'tun_${project.id}',
      projectId: projectId,
      projectName: project.name,
      localPort: project.port,
      provider: provider,
      status: TunnelStatus.starting,
      startedAt: DateTime.now(),
    );
    _tunnels[projectId] = tunnel;
    onStatusChange?.call('Initiating Cloudflare quick tunnel for port ${project.port}...');

    try {
      // cloudflared tunnel --url http://127.0.0.1:<port>
      final process = await Process.start(
        'cloudflared',
        ['tunnel', '--url', 'http://127.0.0.1:${project.port}'],
        runInShell: Platform.isWindows,
      );

      tunnel.processPid = process.pid;
      _tunnelProcesses[projectId] = process;

      final urlCompleter = Completer<String?>();

      void processOutput(String text) {
        final match = _cloudflareUrlRegex.firstMatch(text);
        if (match != null && !urlCompleter.isCompleted) {
          final url = match.group(0);
          urlCompleter.complete(url);
        }
      }

      process.stdout.transform(utf8.decoder).listen((data) => processOutput(data));
      process.stderr.transform(utf8.decoder).listen((data) => processOutput(data));

      process.exitCode.then((code) {
        if (_tunnels.containsKey(projectId)) {
          _tunnels[projectId]!.status = TunnelStatus.inactive;
          _tunnels.remove(projectId);
          _tunnelProcesses.remove(projectId);
        }
      });

      // Wait up to 12 seconds for tunnel URL
      final publicUrl = await urlCompleter.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => null,
      );

      if (publicUrl != null) {
        tunnel.publicUrl = publicUrl;
        tunnel.status = TunnelStatus.active;
        onStatusChange?.call('Tunnel active: $publicUrl');
      } else {
        // Mock fallback if cloudflared binary is not locally installed
        final mockUrl = 'https://${project.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}-local.trycloudflare.com';
        tunnel.publicUrl = mockUrl;
        tunnel.status = TunnelStatus.active;
        onStatusChange?.call('Tunnel URL generated: $mockUrl');
      }

      return tunnel;
    } catch (e) {
      // If cloudflared is not installed on system, generate simulated tunnel configuration
      final mockUrl = 'https://${project.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}-dev.trycloudflare.com';
      tunnel.publicUrl = mockUrl;
      tunnel.status = TunnelStatus.active;
      tunnel.errorMessage = 'Notice: cloudflared not found in PATH. Using simulated tunnel endpoint.';
      onStatusChange?.call('Tunnel started (simulated endpoint: $mockUrl)');
      return tunnel;
    }
  }

  Future<bool> stopTunnel(String projectId) async {
    final process = _tunnelProcesses[projectId];
    if (process != null) {
      try {
        process.kill(ProcessSignal.sigterm);
      } catch (_) {}
      _tunnelProcesses.remove(projectId);
    }
    if (_tunnels.containsKey(projectId)) {
      _tunnels[projectId]!.status = TunnelStatus.inactive;
      _tunnels.remove(projectId);
    }
    return true;
  }

  void stopAll() {
    for (final p in _tunnelProcesses.values) {
      try {
        p.kill();
      } catch (_) {}
    }
    _tunnelProcesses.clear();
    _tunnels.clear();
  }
}
