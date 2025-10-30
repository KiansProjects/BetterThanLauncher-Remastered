import 'package:flutter/material.dart';

class RoundIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final Color normalColor;
  final Color hoverColor;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.normalColor,
    required this.hoverColor,
  });

  @override
  State<RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<RoundIconButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isHovered ? widget.hoverColor : widget.normalColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}
