import 'package:flutter/material.dart';
import '../../core/models/project.dart';

class EnvEditorDialog extends StatefulWidget {
  final Project project;

  const EnvEditorDialog({super.key, required this.project});

  @override
  State<EnvEditorDialog> createState() => _EnvEditorDialogState();
}

class _EnvEditorDialogState extends State<EnvEditorDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final buffer = StringBuffer();
    for (final entry in widget.project.envVariables.entries) {
      buffer.writeln('${entry.key}=${entry.value}');
    }
    _controller = TextEditingController(text: buffer.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, String> _parseEnv(String text) {
    final map = <String, String>{};
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('#') && trimmed.contains('=')) {
        final parts = trimmed.split('=');
        final key = parts[0].trim();
        final val = parts.sublist(1).join('=').trim();
        map[key] = val;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Configure Environment Variables (.env) - ${widget.project.name}'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            const Text(
              'Edit project-specific environment variables below (KEY=VALUE). Changes are automatically synchronized to the local .env file.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'KEY=VALUE\nDB_HOST=127.0.0.1\n...',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final parsed = _parseEnv(_controller.text);
            Navigator.of(context).pop(parsed);
          },
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}

