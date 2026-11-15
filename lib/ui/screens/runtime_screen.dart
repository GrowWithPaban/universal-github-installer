import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../state/runtime_provider.dart';

class RuntimeScreen extends StatefulWidget {
  const RuntimeScreen({super.key});

  @override
  State<RuntimeScreen> createState() => _RuntimeScreenState();
}

class _RuntimeScreenState extends State<RuntimeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RuntimeProvider>().refresh();
    });
  }

  void _copyCommand(String cmd) {
    Clipboard.setData(ClipboardData(text: cmd));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $cmd'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RuntimeProvider>();
    final isWin = Platform.isWindows;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Runtime & Dependency Manager',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.installedCount} installed • ${provider.missingCount} missing runtimes detected on this system',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Rescan System'),
                  onPressed: provider.isLoading ? null : () => provider.refresh(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (provider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else
              ...provider.runtimes.map((r) {
                final installCmd = isWin ? r.installCommandWindows : r.installCommandMac;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          r.isInstalled ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: r.isInstalled ? AppTheme.successGreen : AppTheme.warningOrange,
                          size: 26,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.type.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.isInstalled
                                    ? '${r.version ?? "Installed"} • Binary: ${r.binaryPath}'
                                    : 'Not found in system PATH',
                                style: TextStyle(
                                  color: r.isInstalled ? Colors.grey : AppTheme.warningOrange,
                                  fontSize: 12,
                                  fontFamily: r.isInstalled ? 'monospace' : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!r.isInstalled && installCmd != null) ...[
                          OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 14),
                            label: Text(
                              'Install ($installCmd)',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            ),
                            onPressed: () => _copyCommand(installCmd),
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'READY',
                              style: TextStyle(
                                color: AppTheme.successGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
