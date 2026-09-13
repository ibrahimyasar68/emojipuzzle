import 'package:flutter/material.dart';

/// Üzerinde resim olan, yazısı olmayan yuvarlak bir düğme (§2).
///
/// Bunların hepsi 64 px'lik alt sınırın çok üstündedir: çocuğun dikkatle
/// nişan alması gereken bir ana ekran, yanlış basacağı bir ana ekrandır.
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

  /// TalkBack tarafından seslendirilir. Oyunun buna ihtiyacı yok, ama bir
  /// şey ifade etmenin maliyeti de yok (§31).
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
