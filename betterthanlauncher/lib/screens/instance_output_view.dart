import 'package:flutter/material.dart';
import '../themes/theme_manager.dart';

class InstanceOutputView extends StatelessWidget {
  final ValueNotifier<List<String>> logLines;

  const InstanceOutputView({
    super.key,
    required this.logLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;

    return Container(
      decoration: BoxDecoration(
        color: theme.consoleBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: ValueListenableBuilder<List<String>>(
        valueListenable: logLines,
        builder: (_, lines, __) {
          return ListView.builder(
            reverse: true,
            itemCount: lines.length,
            itemBuilder: (_, i) {
              return Text(
                lines[lines.length - 1 - i],
                style: TextStyle(
                  color: theme.consoleText,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
