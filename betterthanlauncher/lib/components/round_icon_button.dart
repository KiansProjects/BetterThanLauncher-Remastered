import 'package:betterthanlauncher/themes/theme_manager.dart';
import 'package:flutter/material.dart';

class RoundIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  State<RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<RoundIconButton> {
  bool isHovered = false;
  final theme = ThemeManager.currentTheme.value;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isHovered ? theme.buttonHover : theme.buttonHover,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: widget.icon),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: widget.tooltip != null
          ? Tooltip(
              message: widget.tooltip!,
              waitDuration: const Duration(milliseconds: 400),
              preferBelow: false,
              decoration: BoxDecoration(
                color: theme.borderColor,
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: TextStyle(
                color: theme.highlightText,
                fontSize: 13,
              ),
              child: button,
            )
          : button,
    );
  }
}
