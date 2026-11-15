import 'dart:io';
import 'package:path/path.dart' as p;

class SecurityFinding {
  final String filePath;
  final int lineNumber;
  final String description;
  final String severity; // High, Medium, Low
  final String snippet;

  SecurityFinding({
    required this.filePath,
    required this.lineNumber,
    required this.description,
    required this.severity,
    required this.snippet,
  });
}

class SecretScanner {
  static final List<RegExp> _secretPatterns = [
    RegExp(r'ghp_[0-9a-zA-Z]{36}', caseSensitive: false), // GitHub token
    RegExp(r'github_pat_[0-9a-zA-Z_]{82}', caseSensitive: false),
    RegExp(r'AKIA[0-9A-Z]{16}'), // AWS access key
    RegExp(r'sk-[a-zA-Z0-9]{32,}', caseSensitive: false), // OpenAI key
    RegExp(r'AIza[0-9A-Za-z\-_]{35}'), // Google API key
    RegExp(r'-----BEGIN (RSA|EC|DSA|OPENSSH) PRIVATE KEY-----'),
    RegExp(r'password\s*=\s*["\x27][^"\x27]{6,}["\x27]', caseSensitive: false),
  ];

  static final List<RegExp> _riskyCommandPatterns = [
    RegExp(r'curl\s+.*\s*\|\s*(sh|bash)', caseSensitive: false),
    RegExp(r'rm\s+-rf\s+(/|\$HOME|~)', caseSensitive: false),
    RegExp(r':\(\)\{\s*:\|:&\s*\};:', caseSensitive: false), // Fork bomb
  ];

  static Future<List<SecurityFinding>> scanDirectory(String dirPath) async {
    final findings = <SecurityFinding>[];
    final dir = Directory(dirPath);
    if (!await dir.exists()) return findings;

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;

      final relativePath = p.relative(entity.path, from: dirPath);
      // Skip node_modules, .git, vendor, bin
      if (relativePath.contains('node_modules') ||
          relativePath.contains('.git') ||
          relativePath.contains('vendor') ||
          relativePath.endsWith('.png') ||
          relativePath.endsWith('.jpg') ||
          relativePath.endsWith('.zip') ||
          relativePath.endsWith('.lock')) {
        continue;
      }

      try {
        final lines = await entity.readAsLines();
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];

          // Check secrets
          for (final pattern in _secretPatterns) {
            if (pattern.hasMatch(line)) {
              findings.add(SecurityFinding(
                filePath: relativePath,
                lineNumber: i + 1,
                description: 'Potential secret or credentials token found',
                severity: 'High',
                snippet: line.trim().length > 60 ? '${line.trim().substring(0, 60)}...' : line.trim(),
              ));
              break;
            }
          }

          // Check risky commands
          for (final pattern in _riskyCommandPatterns) {
            if (pattern.hasMatch(line)) {
              findings.add(SecurityFinding(
                filePath: relativePath,
                lineNumber: i + 1,
                description: 'Dangerous or unverified script command detected',
                severity: 'High',
                snippet: line.trim(),
              ));
              break;
            }
          }
        }
      } catch (_) {
        // Skip unreadable or binary files
      }
    }

    return findings;
  }
}
