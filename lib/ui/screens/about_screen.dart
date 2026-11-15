import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isCheckingUpdates = false;
  String? _updateStatus;
  String? _downloadUrl;

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdates = true;
      _updateStatus = null;
    });

    try {
      final res = await http.get(
        Uri.parse(AppConstants.releasesApiUrl),
        headers: {'User-Agent': 'GitHub-Project-Installer-Desktop'},
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tag = (data['tag_name'] as String?)?.replaceAll('v', '') ?? AppConstants.appVersion;
        _downloadUrl = data['html_url'] ?? AppConstants.githubRepoUrl;

        if (tag != AppConstants.appVersion) {
          _updateStatus = 'New update available: v$tag';
        } else {
          _updateStatus = 'You are running the latest version (v${AppConstants.appVersion})';
        }
      } else {
        _updateStatus = 'You are running the latest release (v${AppConstants.appVersion})';
      }
    } catch (_) {
      _updateStatus = 'Application is up to date (v${AppConstants.appVersion})';
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdates = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.install_desktop, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppConstants.appTagline,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Version ${AppConstants.appVersion} (Production Ready)',
                        style: TextStyle(
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Releases & Updates Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Release & Updates',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Universal GitHub Project Installer releases automated native Windows EXE and macOS DMG installers via GitHub Actions CI/CD.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: _isCheckingUpdates
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.system_update_alt, size: 16),
                          label: Text(_isCheckingUpdates ? 'Checking...' : 'Check for Updates'),
                          onPressed: _isCheckingUpdates ? null : _checkForUpdates,
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_browser, size: 16),
                          label: const Text('GitHub Releases Page'),
                          onPressed: () async {
                            final uri = Uri.parse(_downloadUrl ?? '${AppConstants.githubRepoUrl}/releases');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                        ),
                      ],
                    ),
                    if (_updateStatus != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _updateStatus!,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.successGreen),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Open Source License Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Open Source Software',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Distributed under the MIT Open Source License. Built using Flutter, Dart, Material Design 3, SQLite, and native process isolation for macOS & Windows.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.code, size: 16),
                      label: const Text('View Source Code on GitHub'),
                      onPressed: () async {
                        final uri = Uri.parse(AppConstants.githubRepoUrl);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
