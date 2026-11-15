import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  File? _dataFile;

  Future<File> _getFile() async {
    if (_dataFile != null) return _dataFile!;
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
    _dataFile = File(p.join(appDir.path, 'projects_store.json'));
    if (!await _dataFile!.exists()) {
      await _dataFile!.writeAsString(jsonEncode([]));
    }
    return _dataFile!;
  }

  Future<List<Project>> loadProjects() async {
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final List list = jsonDecode(content);
      return list.map((item) => Project.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveProjects(List<Project> projects) async {
    try {
      final file = await _getFile();
      final jsonList = projects.map((p) => p.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> saveProject(Project project) async {
    final list = await loadProjects();
    final index = list.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      list[index] = project;
    } else {
      list.add(project);
    }
    await saveProjects(list);
  }

  Future<void> deleteProject(String id) async {
    final list = await loadProjects();
    list.removeWhere((p) => p.id == id);
    await saveProjects(list);
  }
}
