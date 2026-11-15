import 'package:flutter/material.dart';
import '../../core/models/installation_plan.dart';
import '../../core/theme/app_theme.dart';

class CommandApprovalDialog extends StatelessWidget {
  final InstallationStep step;

  const CommandApprovalDialog({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: AppTheme.warningOrange),
          SizedBox(width: 10),
          Text('Command Execution Authorization'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A potentially destructive command or database migration has been requested by the repository setup plan. Please review before proceeding:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkTerminal,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: SelectableText(
                '${step.command} ${step.args.join(" ")}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppTheme.accentCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Step: ${step.title}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              'Description: ${step.description}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (step.workingDirectory != null) ...[
              const SizedBox(height: 4),
              Text(
                'Working Directory: ${step.workingDirectory}',
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Skip / Deny'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningOrange),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Authorize & Run'),
        ),
      ],
    );
  }
}
