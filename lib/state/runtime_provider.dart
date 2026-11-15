import 'package:flutter/material.dart';
import '../core/models/runtime_info.dart';
import '../services/runtime/runtime_manager.dart';

class RuntimeProvider extends ChangeNotifier {
  List<RuntimeInfo> _runtimes = [];
  bool _isLoading = false;

  List<RuntimeInfo> get runtimes => _runtimes;
  bool get isLoading => _isLoading;

  int get installedCount => _runtimes.where((r) => r.isInstalled).length;
  int get missingCount => _runtimes.where((r) => !r.isInstalled).length;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    _runtimes = await RuntimeManager.detectAllRuntimes();
    _isLoading = false;
    notifyListeners();
  }
}
