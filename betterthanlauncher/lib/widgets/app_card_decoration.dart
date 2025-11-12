import 'package:flutter/material.dart';
import '../themes/app_theme_data.dart';

BoxDecoration appCardDecoration(AppThemeData theme) {
  return BoxDecoration(
    color: theme.cardBackground,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
