import 'package:flutter/material.dart';
import '../../core/constants/supported_technologies.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final ProjectState status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case ProjectState.running:
        bg = AppTheme.successGreen.withValues(alpha: 0.15);
        fg = AppTheme.successGreen;
        label = 'RUNNING';
        icon = Icons.play_circle_fill;
        break;
      case ProjectState.ready:
        bg = AppTheme.primaryBlue.withValues(alpha: 0.15);
        fg = AppTheme.primaryBlue;
        label = 'READY';
        icon = Icons.check_circle;
        break;
      case ProjectState.starting:
        bg = AppTheme.warningOrange.withValues(alpha: 0.15);
        fg = AppTheme.warningOrange;
        label = 'STARTING';
        icon = Icons.hourglass_top;
        break;
      case ProjectState.stopping:
        bg = AppTheme.warningOrange.withValues(alpha: 0.15);
        fg = AppTheme.warningOrange;
        label = 'STOPPING';
        icon = Icons.pause_circle_filled;
        break;
      case ProjectState.installing:
      case ProjectState.cloning:
      case ProjectState.analyzing:
        bg = AppTheme.accentCyan.withValues(alpha: 0.15);
        fg = AppTheme.accentCyan;
        label = status.name.toUpperCase();
        icon = Icons.sync;
        break;
      case ProjectState.error:
        bg = AppTheme.errorRed.withValues(alpha: 0.15);
        fg = AppTheme.errorRed;
        label = 'ERROR';
        icon = Icons.error;
        break;
      case ProjectState.notInstalled:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        label = 'NOT INSTALLED';
        icon = Icons.download;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
