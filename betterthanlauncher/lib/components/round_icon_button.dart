import 'package:flutter/material.dart';

class RoundIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final Color normalColor;
  final Color hoverColor;
  final String? tooltip;
  final Color? tooltipBackgroundColor;
  final Color? tooltipTextColor;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.normalColor,
    required this.hoverColor,
    this.tooltip,
    this.tooltipBackgroundColor,
    this.tooltipTextColor,
  });

  @override
  State<RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<RoundIconButton> {
  bool isHovered = false;

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
          color: isHovered ? widget.hoverColor : widget.normalColor,
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
              preferBelow: false, // Places tooltip above when possible
              decoration: BoxDecoration(
                color: widget.tooltipBackgroundColor ?? Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: TextStyle(
                color: widget.tooltipTextColor ?? Colors.white,
                fontSize: 13,
              ),
              child: button,
            )
          : button,
    );
  }
}
