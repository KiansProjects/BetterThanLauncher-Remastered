import 'package:flutter/material.dart';
import 'app_theme_data.dart';
import 'app_theme_styles.dart';
import 'app_themes.dart';

class ThemeManager {
  static final ValueNotifier<AppThemeData> currentTheme =
      ValueNotifier(AppThemeStyles.dark);

  static void setTheme(AppThemes theme) {
    currentTheme.value = AppThemeStyles.getTheme(theme);
  }
}
