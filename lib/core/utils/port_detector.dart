import 'dart:io';

class PortDetector {
  static Future<bool> isPortInUse(int port) async {
    try {
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      await socket.close();
      return false; // Port was free to bind
    } catch (_) {
      return true; // Port is in use
    }
  }

  static Future<int> findAvailablePort({int startPort = 3000, int maxAttempts = 100}) async {
    for (int port = startPort; port < startPort + maxAttempts; port++) {
      final inUse = await isPortInUse(port);
      if (!inUse) {
        return port;
      }
    }
    return startPort; // Fallback
  }

  static Future<bool> waitForPort(int port, {Duration timeout = const Duration(seconds: 15)}) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      final inUse = await isPortInUse(port);
      if (inUse) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }
}
