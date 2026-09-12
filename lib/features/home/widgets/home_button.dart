import 'package:flutter/material.dart';

/// A round button with a picture on it and no words (§2).
///
/// Every one of these is far above the 64 px minimum: a home screen a child
/// has to aim at carefully is a home screen they will mis-tap.
class HomeButton extends StatelessWidget {
  const HomeButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 96,
    this.background = const Color(0xFFF3E4D0),
    this.foreground = const Color(0xFF4A4039),
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Read out by TalkBack. The game never needs it, but it costs nothing to
  /// mean something (§31).
  final String semanticLabel;

  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: size * 0.46, color: foreground),
        ),
      ),
    );
  }
}
