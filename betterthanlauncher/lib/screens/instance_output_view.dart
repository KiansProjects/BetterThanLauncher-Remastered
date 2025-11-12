import 'package:flutter/material.dart';
import '../themes/theme_manager.dart';

class InstanceOutputView extends StatelessWidget {
  final ValueNotifier<String> output;

  const InstanceOutputView({
    super.key,
    required this.output,
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
      child: ValueListenableBuilder<String>(
        valueListenable: output,
        builder: (_, text, __) => SingleChildScrollView(
          reverse: true,
          child: Text(
            text,
            style: TextStyle(
              color: theme.consoleText,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

