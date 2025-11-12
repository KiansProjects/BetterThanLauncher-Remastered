import 'package:flutter/material.dart';
import 'app_theme_data.dart';

class AppThemeStyles {
  static const AppThemeData dark = AppThemeData(
    mainBackground: Color(0xFF16181C),
    cardBackground: Color(0xFF26292F),
    borderColor: Color(0xFF434956),
    secondaryText: Color(0xFFA7B0C0),
    buttonNormal: Color(0xFF2563EB),
    buttonHover: Color(0xFF1D4ED8),
    primaryText: Color(0xFFA7B0C0),
    highlightText: Color(0xFFFFFFFF),
    errorText: Color(0xFFEF4444),
    consoleText: Color(0xFFFFFFFF),
    consoleBackground: Color(0xFF000000),
  );

  static const AppThemeData light = AppThemeData(
    mainBackground: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFF9FAFB),
    borderColor: Color(0xFFE9ECEF),
    secondaryText: Color(0xFF374151),
    buttonNormal: Color(0xFFCBD5E1),
    buttonHover: Color(0xFF94A3B8),
    primaryText: Color(0xFF6B7280),
    highlightText: Color(0xFF111111),
    errorText: Color(0xFFB91C1C),
    consoleText: Color(0xFFFFFFFF),
    consoleBackground: Color(0xFF000000),
  );

  static AppThemeData getTheme(AppThemes theme) {
    switch (theme) {
      case AppThemes.dark:
        return dark;
      case AppThemes.light:
        return light;
    }
  }
}
