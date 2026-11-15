import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  File? _vaultFile;
  final String _maskKey = 'GithubInstallerSecureVaultKey2026';

  Future<File> _getVaultFile() async {
    if (_vaultFile != null) return _vaultFile!;
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory(Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.');
    }
    final appDir = Directory(p.join(dir.path, '.github_installer'));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    _vaultFile = File(p.join(appDir.path, 'credentials.vault'));
    if (!await _vaultFile!.exists()) {
      await _vaultFile!.writeAsString('');
    }
    return _vaultFile!;
  }

  String _obfuscate(String input) {
    final bytes = utf8.encode(input);
    final keyBytes = utf8.encode(_maskKey);
    final masked = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64Encode(masked);
  }

  String _deobfuscate(String input) {
    try {
      final bytes = base64Decode(input);
      final keyBytes = utf8.encode(_maskKey);
      final unmasked = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
      );
      return utf8.decode(unmasked);
    } catch (_) {
      return '';
    }
  }

  Future<Map<String, String>> _readAll() async {
    try {
      final file = await _getVaultFile();
      final content = await file.readAsString();
      if (content.trim().isEmpty) return {};
      final decoded = _deobfuscate(content);
      return Map<String, String>.from(jsonDecode(decoded) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, String> data) async {
    try {
      final file = await _getVaultFile();
      final encoded = _obfuscate(jsonEncode(data));
      await file.writeAsString(encoded);
    } catch (_) {}
  }

  Future<void> write(String key, String value) async {
    final data = await _readAll();
    data[key] = value;
    await _writeAll(data);
  }

  Future<String?> read(String key) async {
    final data = await _readAll();
    return data[key];
  }

  Future<void> delete(String key) async {
    final data = await _readAll();
    data.remove(key);
    await _writeAll(data);
  }
}

