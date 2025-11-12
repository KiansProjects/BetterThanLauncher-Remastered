import 'package:flutter/material.dart';

enum AppThemes { dark, light }

class AppThemeData {
  final Color mainBackground;    // Haupt-Hintergrund des Content-Bereichs
  final Color cardBackground;    // Karten, Tiles, Output-Container
  final Color borderColor;       // Rahmen, Divider, Tooltip-Hintergrund
  final Color secondaryText;     // Sekundäre Texte, Labels
  final Color buttonNormal;      // Buttons normal (Sidebar etc.)
  final Color buttonHover;       // Buttons Hover
  final Color primaryText;       // Haupttext
  final Color highlightText;     // Sekundär-Text oder Icons
  final Color errorText;         // Fehlertexte, Validationsfehler
  final Color consoleText;         // temporärer weißer Text / Icons
  final Color consoleBackground;   // temporärer schwarzer Hintergrund

  const AppThemeData({
    required this.mainBackground,
    required this.cardBackground,
    required this.borderColor,
    required this.secondaryText,
    required this.buttonNormal,
    required this.buttonHover,
    required this.primaryText,
    required this.highlightText,
    required this.errorText,
    required this.consoleText,
    required this.consoleBackground,
  });
}
