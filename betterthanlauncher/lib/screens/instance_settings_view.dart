import 'package:flutter/material.dart';
import '../themes/theme_manager.dart';

class InstanceSettingsView extends StatelessWidget {
  final String instanceName;

  const InstanceSettingsView({super.key, required this.instanceName});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme.value;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          "Settings for $instanceName (WIP)",
          style: TextStyle(color: theme.secondaryText),
        ),
      ),
    );
  }
}
