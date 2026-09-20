import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Üzerinde resim olan, yazısı olmayan yuvarlak bir düğme (§2).
///
/// Bunların hepsi 64 px'lik alt sınırın çok üstündedir: çocuğun dikkatle
/// nişan alması gereken bir ana ekran, yanlış basacağı bir ana ekrandır.
///
/// [holdDuration] verilirse düğme bir **yetişkin kapısı** olur: dokunmak
/// yetmez, o süre kadar basılı tutmak gerekir ve tutarken çevresinde bir
/// halka dolar. §2'nin "uzun basma yok" kuralı çocuğun *oynamak için*
/// yapmak zorunda olduğu hareketler içindir; bu ise tam tersi — çocuğun
/// kazara açmaması istenen kapıdır (sıfırlama düğmesiyle aynı gerekçe).
class HomeButton extends StatefulWidget {
  const HomeButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 96,
    this.background,
    this.foreground,
    this.holdDuration,
  });

  final IconData icon;

  /// Dokunma (ya da [holdDuration] varsa yeterince uzun basma) sonucu.
  final VoidCallback onTap;

  /// TalkBack tarafından seslendirilir. Oyunun buna ihtiyacı yok, ama bir
  /// şey ifade etmenin maliyeti de yok (§31).
  final String semanticLabel;

  final double size;

  /// Verilmezse temanın düğme renkleri.
  final Color? background;
  final Color? foreground;

  /// Null ise sıradan bir düğmedir; doluysa o kadar basılı tutmak gerekir.
  final Duration? holdDuration;

  @override
  State<HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<HomeButton>
    with SingleTickerProviderStateMixin {
  /// Basılı tutmanın ilerlemesi. `Timer` değil: arka plana geçince durmalı
  /// (§28) ve ekrana bir şey çizecek olan da budur.
  AnimationController? _hold;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  @override
  void didUpdateWidget(HomeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.holdDuration == oldWidget.holdDuration) return;
    _hold?.dispose();
    _hold = null;
    _createController();
  }

  void _createController() {
    final duration = widget.holdDuration;
    if (duration == null) return;
    _hold = AnimationController(vsync: this, duration: duration)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        _hold?.value = 0;
        widget.onTap();
      });
  }

  @override
  void dispose() {
    _hold?.dispose();
    super.dispose();
  }

  void _startHold(TapDownDetails _) => _hold?.forward(from: 0);

  /// Parmak erken kalktı: halka geldiği yerden geri iner, hiçbir şey olmaz.
  ///
  /// `value == 0` iken de **durdurmak** gerekir: kısa bir dokunuşta basma
  /// ve kalkma aynı karede olur, sayaç daha ilerlememiştir ve erken dönen
  /// bir iptal onu çalışır bırakır — dokunuş iki saniye sonra kapıyı
  /// açardı (testte yaşandı).
  void _cancelHold() {
    final hold = _hold;
    if (hold == null) return;
    if (hold.value == 0) {
      hold.stop();
      return;
    }
    hold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hold = _hold;

    final face = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.background ?? palette.button,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        widget.icon,
        size: widget.size * 0.46,
        color: widget.foreground ?? palette.onButton,
      ),
    );

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hold == null ? widget.onTap : null,
        onTapDown: hold == null ? null : _startHold,
        onTapUp: hold == null ? null : (_) => _cancelHold(),
        onTapCancel: hold == null ? null : _cancelHold,
        child: hold == null
            ? face
            : AnimatedBuilder(
                animation: hold,
                builder: (context, child) => CustomPaint(
                  foregroundPainter: _HoldRingPainter(
                    progress: hold.value,
                    colour: widget.foreground ?? palette.onSubtleSurface,
                  ),
                  child: child,
                ),
                child: face,
              ),
      ),
    );
  }
}

/// Basılı tutuldukça dolan halka. Boşken hiç çizilmez: düğme sıradan
/// göründüğü sürece çocuk için ilginç bir şey değildir.
class _HoldRingPainter extends CustomPainter {
  const _HoldRingPainter({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final stroke = size.shortestSide * 0.07;
    final rect =
        Rect.fromLTWH(0, 0, size.width, size.height).deflate(stroke / 2);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = colour
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_HoldRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colour != colour;
}
