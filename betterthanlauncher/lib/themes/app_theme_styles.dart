import 'package:flutter/material.dart';
import 'app_theme_data.dart';
import 'app_themes.dart';

class AppThemeStyles {
  static const AppThemeData dark = AppThemeData(
    background: Color(0xFF16181C),
    components: Color(0xFF26292F),
    components2: Color(0xFF434956),
    components3: Color(0xFFA7B0C0),
    components4: Color(0xFF2563EB),
    components5: Color(0xFF1D4ED8),
    text: Color(0xFFA7B0C0),
    text2: Color(0xFFFFFFFF),
  );

  static const AppThemeData light = AppThemeData(
    background: Color(0xFFFFFFFF),
    components: Color(0xFFF9FAFB),
    components2: Color(0xFFE9ECEF),
    components3: Color(0xFF374151),
    components4: Color(0xFFCBD5E1),
    components5: Color(0xFF94A3B8),
    text: Color(0xFF6B7280),
    text2: Color(0xFF111111),
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
