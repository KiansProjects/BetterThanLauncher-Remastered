import 'package:flutter/material.dart';
import '../themes/theme_manager.dart';

class InstanceOutputView extends StatelessWidget {
  final String instanceName;
  final ValueNotifier<String> output;
  final VoidCallback onClose;

  const InstanceOutputView({
    super.key,
    required this.instanceName,
    required this.output,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.components2, width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("▶ $instanceName",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
              ),
            ],
          ),
          Divider(color: theme.components2),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: output,
              builder: (_, text, __) => SingleChildScrollView(
                reverse: true,
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
