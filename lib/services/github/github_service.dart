import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/command_runner.dart';

class RepoMetadata {
  final String owner;
  final String name;
  final String fullName;
  final String defaultBranch;
  final String? description;
  final int stars;
  final int forks;
  final bool isPrivate;

  RepoMetadata({
    required this.owner,
    required this.name,
    required this.fullName,
    required this.defaultBranch,
    this.description,
    this.stars = 0,
    this.forks = 0,
    this.isPrivate = false,
  });
}

class GitHubService {
  static final RegExp _repoRegex = RegExp(
    r'github\.com[/:]([a-zA-Z0-9_\-\.]+)/([a-zA-Z0-9_\-\.]+)(?:\.git)?',
  );

  static bool isValidGitHubUrl(String url) {
    return _repoRegex.hasMatch(url.trim());
  }

  static ({String owner, String repo})? parseUrl(String url) {
    final match = _repoRegex.firstMatch(url.trim());
    if (match == null) return null;
    var repo = match.group(2)!;
    if (repo.endsWith('.git')) {
      repo = repo.substring(0, repo.length - 4);
    }
    return (owner: match.group(1)!, repo: repo);
  }

  static Future<RepoMetadata?> fetchMetadata(String url) async {
    final parsed = parseUrl(url);
    if (parsed == null) return null;

    final token = await SecureStorageService().read('github_token');
    final apiUrl = Uri.parse('https://api.github.com/repos/${parsed.owner}/${parsed.repo}');

    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'GitHub-Project-Installer-Desktop',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(apiUrl, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RepoMetadata(
          owner: data['owner']['login'] ?? parsed.owner,
          name: data['name'] ?? parsed.repo,
          fullName: data['full_name'] ?? '${parsed.owner}/${parsed.repo}',
          defaultBranch: data['default_branch'] ?? 'main',
          description: data['description'],
          stars: data['stargazers_count'] ?? 0,
          forks: data['forks_count'] ?? 0,
          isPrivate: data['private'] ?? false,
        );
      }
    } catch (_) {}

    // Fallback if API rate-limited or offline
    return RepoMetadata(
      owner: parsed.owner,
      name: parsed.repo,
      fullName: '${parsed.owner}/${parsed.repo}',
      defaultBranch: 'main',
    );
  }

  static Future<String> getProjectsDirectory() async {
    Directory home;
    try {
      final docs = await getApplicationDocumentsDirectory();
      home = Directory(p.join(docs.path, AppConstants.defaultProjectsFolderName));
    } catch (_) {
      final homePath = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
      home = Directory(p.join(homePath, AppConstants.defaultProjectsFolderName));
    }
    if (!await home.exists()) {
      await home.create(recursive: true);
    }
    return home.path;
  }

  static Future<String> cloneRepository(
    String url, {
    String? customPath,
    void Function(String output, bool isError)? onProgress,
  }) async {
    final parsed = parseUrl(url);
    if (parsed == null) {
      throw Exception('Invalid GitHub URL: $url');
    }

    final targetDir = customPath ?? p.join(await getProjectsDirectory(), parsed.repo);
    final directory = Directory(targetDir);

    if (await directory.exists()) {
      // Check if it's already a git repo
      final gitDir = Directory(p.join(targetDir, '.git'));
      if (await gitDir.exists()) {
        if (onProgress != null) {
          onProgress('Repository already cloned in $targetDir. Pulling latest...', false);
        }
        await CommandRunner.run('git', ['pull'], workingDirectory: targetDir, onLine: onProgress);
        return targetDir;
      }
    }

    if (onProgress != null) {
      onProgress('Cloning ${parsed.owner}/${parsed.repo} into $targetDir...', false);
    }

    final token = await SecureStorageService().read('github_token');
    String cloneUrl = url;
    if (token != null && token.isNotEmpty && cloneUrl.startsWith('https://')) {
      cloneUrl = cloneUrl.replaceFirst('https://', 'https://$token@');
    }

    final result = await CommandRunner.run(
      'git',
      ['clone', '--depth', '1', cloneUrl, targetDir],
      onLine: onProgress,
    );

    if (!result.isSuccess && !await directory.exists()) {
      throw Exception('Failed to clone repository: ${result.stderr}');
    }

    return targetDir;
  }
}
