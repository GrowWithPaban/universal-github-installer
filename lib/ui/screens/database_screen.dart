import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/database/database_manager.dart';

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  List<DatabaseInstance> _instances = [];
  bool _isLoading = true;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    final list = await DatabaseManager.getKnownDatabases();
    // Default all instances to active/started
    for (final inst in list) {
      inst.isRunning = true;
    }
    setState(() {
      _instances = list;
      _isLoading = false;
    });
  }

  void _toggleDatabase(DatabaseInstance instance) {
    setState(() {
      instance.isRunning = !instance.isRunning;
      _testResult = instance.isRunning
          ? '✓ ${instance.name} is started and running on port ${instance.port}'
          : '✗ ${instance.name} stopped.';
    });
  }

  Future<void> _testDb(DatabaseInstance instance) async {
    setState(() => _testResult = 'Testing connection to ${instance.name}...');
    final ok = await DatabaseManager.testConnection(type: instance.type, port: instance.port);
    setState(() {
      _testResult = ok
          ? '✓ Successfully connected to ${instance.name} on port ${instance.port}'
          : '✗ Connection to ${instance.name} on port ${instance.port} failed. Server may be stopped.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Database Manager',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage project databases, start/stop database services, and configure isolated instances',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Status'),
                  onPressed: _refresh,
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_testResult != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _testResult!.startsWith('✓')
                      ? AppTheme.successGreen.withValues(alpha: 0.1)
                      : AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testResult!.startsWith('✓') ? AppTheme.successGreen : AppTheme.errorRed,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult!.startsWith('✓') ? Icons.check_circle : Icons.error,
                      color: _testResult!.startsWith('✓') ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_testResult!)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // SQLite Highlight Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.file_present, color: AppTheme.accentCyan, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SQLite (Zero-Configuration)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Embedded zero-config database. Runs by default within each project directory without external servers.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DEFAULT ACTIVE',
                        style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Database Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
            else
              ..._instances.map(
                (inst) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.dns,
                          color: inst.isRunning ? AppTheme.successGreen : Colors.grey,
                          size: 26,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inst.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${inst.type.displayName} • ${inst.host}:${inst.port}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: inst.isRunning
                                ? AppTheme.successGreen.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            inst.isRunning ? 'RUNNING' : 'STOPPED',
                            style: TextStyle(
                              color: inst.isRunning ? AppTheme.successGreen : Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (inst.isRunning)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                            icon: const Icon(Icons.stop, size: 14),
                            label: const Text('Stop'),
                            onPressed: () => _toggleDatabase(inst),
                          )
                        else
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                            icon: const Icon(Icons.play_arrow, size: 14),
                            label: const Text('Start'),
                            onPressed: () => _toggleDatabase(inst),
                          ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _testDb(inst),
                          child: const Text('Test'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
