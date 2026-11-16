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

  static Future<bool> isPortListening(int port, {Duration timeout = const Duration(milliseconds: 500)}) async {
    try {
      final socket = await Socket.connect('127.0.0.1', port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      try {
        final socket = await Socket.connect('localhost', port, timeout: timeout);
        socket.destroy();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  static Future<bool> isHttpResponsive(String url, {Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final client = HttpClient()..connectionTimeout = timeout;
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
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
      if (await isPortListening(port)) {
        return true;
      }
      final inUse = await isPortInUse(port);
      if (inUse) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }
}

