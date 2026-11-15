import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/process_status.dart';
import '../../core/theme/app_theme.dart';

class TerminalView extends StatefulWidget {
  final List<LogEntry> logs;
  final VoidCallback? onClear;
  final String title;

  const TerminalView({
    super.key,
    required this.logs,
    this.onClear,
    this.title = 'Terminal Output',
  });

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void didUpdateWidget(TerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_autoScroll && widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copyAllLogs() {
    final allText = widget.logs.map((e) => '[${e.timestamp.toIso8601String()}] ${e.text}').join('\n');
    Clipboard.setData(ClipboardData(text: allText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terminal logs copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkTerminal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16, color: AppTheme.accentCyan),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _autoScroll ? Icons.vertical_align_bottom : Icons.pause,
                    size: 16,
                    color: _autoScroll ? AppTheme.accentCyan : Colors.white38,
                  ),
                  tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll PAUSED',
                  onPressed: () => setState(() => _autoScroll = !_autoScroll),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                  tooltip: 'Copy all logs',
                  onPressed: _copyAllLogs,
                ),
                if (widget.onClear != null)
                  IconButton(
                    icon: const Icon(Icons.clear_all, size: 16, color: Colors.white70),
                    tooltip: 'Clear console',
                    onPressed: widget.onClear,
                  ),
              ],
            ),
          ),

          // Log lines
          Expanded(
            child: widget.logs.isEmpty
                ? const Center(
                    child: Text(
                      'No terminal output yet.',
                      style: TextStyle(color: Colors.white38, fontFamily: 'monospace', fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.logs.length,
                    itemBuilder: (context, index) {
                      final log = widget.logs[index];
                      final time = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '[$time] ',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Expanded(
                              child: SelectableText(
                                log.text,
                                style: TextStyle(
                                  color: log.isError ? const Color(0xFFF87171) : const Color(0xFFE2E8F0),
                                  fontSize: 12.5,
                                  fontFamily: 'monospace',
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

