import 'package:flutter/material.dart';
import '../themes/theme_manager.dart';

class BuildScreen extends StatelessWidget {
  final ValueNotifier<String> lastLine;

  const BuildScreen({super.key, required this.lastLine});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;
    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.components,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.text),
              const SizedBox(height: 20),
              ValueListenableBuilder<String>(
                valueListenable: lastLine,
                builder: (context, value, _) {
                  return Text(
                    value,
                    style: TextStyle(color: theme.text, fontSize: 14),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
