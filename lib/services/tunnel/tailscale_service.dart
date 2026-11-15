import 'dart:convert';
import 'dart:io';
import '../../core/utils/command_runner.dart';

class TailscaleNodeInfo {
  final bool isInstalled;
  final bool isRunning;
  final String? ip;
  final String? dnsName;
  final String? hostName;

  TailscaleNodeInfo({
    required this.isInstalled,
    required this.isRunning,
    this.ip,
    this.dnsName,
    this.hostName,
  });

  String get displayUrl {
    if (dnsName != null && dnsName!.isNotEmpty) {
      final cleaned = dnsName!.endsWith('.') ? dnsName!.substring(0, dnsName!.length - 1) : dnsName!;
      return 'https://$cleaned';
    }
    if (ip != null && ip!.isNotEmpty) {
      return 'http://$ip';
    }
    return '';
  }
}

class TailscaleService {
  static String? _resolvedBinary;

  static String getBinary() {
    if (_resolvedBinary != null) return _resolvedBinary!;

    final candidates = [
      'tailscale',
      '/Applications/Tailscale.app/Contents/MacOS/Tailscale',
      r'C:\Program Files\Tailscale\tailscale.exe',
      r'C:\Program Files (x86)\Tailscale\tailscale.exe',
      '/usr/local/bin/tailscale',
      '/opt/homebrew/bin/tailscale',
    ];

    for (final c in candidates) {
      if (File(c).existsSync()) {
        _resolvedBinary = c;
        return c;
      }
    }

    _resolvedBinary = 'tailscale';
    return _resolvedBinary!;
  }

  static Future<TailscaleNodeInfo> getStatus() async {
    final binary = getBinary();
    try {
      final res = await CommandRunner.run(binary, ['status', '--json']);
      if (res.isSuccess && res.stdout.trim().isNotEmpty) {
        final json = jsonDecode(res.stdout);
        final self = json['Self'] as Map<String, dynamic>?;
        if (self != null) {
          final dns = self['DNSName'] as String?;
          final host = self['HostName'] as String?;
          final ips = (self['TailscaleIPs'] as List?)?.map((e) => e.toString()).toList() ?? [];
          return TailscaleNodeInfo(
            isInstalled: true,
            isRunning: true,
            dnsName: dns,
            hostName: host,
            ip: ips.isNotEmpty ? ips.first : null,
          );
        }
      }
    } catch (_) {}

    final exists = File(binary).existsSync() || binary == 'tailscale';
    return TailscaleNodeInfo(
      isInstalled: exists,
      isRunning: false,
    );
  }

  static Future<String?> startFunnel(int port) async {
    final binary = getBinary();
    final status = await getStatus();

    // tailscale funnel --bg <port>
    await CommandRunner.run(binary, ['funnel', '--bg', '$port']);

    if (status.displayUrl.isNotEmpty) {
      return status.displayUrl;
    }
    return 'https://tailscale.live:$port';
  }

  static Future<String?> startServe(int port) async {
    final binary = getBinary();
    final status = await getStatus();

    // tailscale serve --bg <port>
    await CommandRunner.run(binary, ['serve', '--bg', 'http://127.0.0.1:$port']);

    if (status.displayUrl.isNotEmpty) {
      return '${status.displayUrl}:$port';
    }
    return 'http://127.0.0.1:$port';
  }

  static Future<void> stop(int port) async {
    final binary = getBinary();
    try {
      await CommandRunner.run(binary, ['funnel', '$port', 'off']);
      await CommandRunner.run(binary, ['serve', '--reset']);
    } catch (_) {}
  }
}

