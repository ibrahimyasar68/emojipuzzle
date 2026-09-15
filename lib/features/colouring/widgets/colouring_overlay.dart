import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../../../core/constants/puzzle_config.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/paint_colours.dart';
import '../providers/colouring_book.dart';
import 'car_painter.dart';
import 'colouring_layout.dart';

/// Boyama safhası (§24.2): çocuk paletten istediği rengi seçer ve arabanın
/// bir parçasına dokunur; parça boyanır ve sıradaki puzzle gelir.
///
/// Renk sabit bir listeden değil, sürekli bir paletten serbestçe seçilir
/// (K-9): bir şeritte bütün tonlar açıktan koyuya, yanında beyazdan siyaha
/// griler. Parmak palette gezdikçe seçim de gezer; seçilen renk sol üst
/// köşedeki karede, parmağın altında kalmadan görünür (K-10).
///
/// Bu özellik puzzle hakkında hiçbir şey bilmez (§36). Defter, ses ve
/// bittiğini söyleyecek bir yol verilir.
///
/// Tamamlama dizisinin geri kalanı gibi atlanabilir (§23, K-6): köşedeki
/// ok hemen geçer. Beklemeler zamanlayıcıyla değil animasyon denetleyicisiyle
/// yapılır: uygulama arka plandayken durur, çocuk dönmeden oyun ilerlemez.
class ColouringOverlay extends StatefulWidget {
  const ColouringOverlay({
    super.key,
    required this.book,
    required this.onFinished,
    this.audio,
    this.haptics = const HapticService(),
    this.finishesCar = false,
  });

  final ColouringBook book;

  /// Bir kez çağrılır: boyandıktan sonra ya da geçildiğinde.
  final VoidCallback onFinished;

  /// Verilmezse sessizdir.
  final AudioService? audio;

  final HapticService? haptics;

  /// Bu safha arabanın son safhası mı (K-15). Öyleyse boyamadan sonra araba
  /// — beyaz parçası kalmış olsa bile — ekrandan sürülerek çıkar. Sıradaki
  /// arabaya geçmek defterin değil oyunun işidir.
  final bool finishesCar;

  @override
  State<ColouringOverlay> createState() => _ColouringOverlayState();
}

class _ColouringOverlayState extends State<ColouringOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: PuzzleConfig.colouringFillDuration,
  );
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: PuzzleConfig.colouringSettleDuration,
  );
  late final AnimationController _drive = AnimationController(
    vsync: this,
    duration: PuzzleConfig.colouringDriveOffDuration,
  );

  /// Seçili renk. Bir renk baştan seçilidir: tek dokunuş boyamaya yeter.
  PaletteChoice _choice = PaletteChoice.initial;

  String? _freshPart;
  int? _freshFrom;

  /// Her puzzle bitişinde bir parça (§24.2). Boyandıktan sonra kart
  /// dokunuşa kapanır.
  bool _painted = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _settle.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      if (widget.finishesCar) {
        widget.audio?.playPuzzleComplete();
        _drive.forward();
      } else {
        _finish();
      }
    });
    _drive.addStatusListener((status) async {
      if (status != AnimationStatus.completed) return;
      _finish();
    });
  }

  @override
  void dispose() {
    _fill.dispose();
    _settle.dispose();
    _drive.dispose();
    super.dispose();
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinished();
  }

  /// Parmak palete değdi ya da palette gezindi.
  void _pick(
    PaletteStrip strip,
    Offset point,
    ColouringLayout layout, {
    required bool touchDown,
  }) {
    if (touchDown) widget.haptics?.selection();
    final choice = layout.choiceIn(strip, point);
    if (choice == _choice) return;
    setState(() => _choice = choice);
  }

  void _tapCard(Offset local, ColouringLayout layout) {
    if (_painted || _finished) return;
    final part = widget.book.car.partAt(local / layout.scale);
    // Kâğıda dokunmak bir şey boyamaz ve bir şey söylemez (§20).
    if (part == null) return;
    // Boyanmış parça kilitlidir (K-15): beş safha beş parçadır ve yeniden
    // boyanan bir parça, arabanın bir parçasını beyaz bırakırdı.
    if (widget.book.colourOf(part.id) != null) return;

    _painted = true;
    _freshPart = part.id;
    _freshFrom = widget.book.colourOf(part.id);
    unawaited(widget.book.paint(part.id, _choice.colour.toARGB32()));
    widget.audio?.playPieceSnap();
    widget.haptics?.light();
    _fill.forward(from: 0);
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final area = constraints.biggest;
          final layout = ColouringLayout.of(area);
          final alongWidth = layout.huesAlongWidth;

          return Stack(
            key: const ValueKey('colouring-overlay'),
            children: [
              // Karta, palete ya da oka değmeyen bir dokunuş hiçbir şey
              // yapmaz, ama alttaki puzzle'a da ulaşmaz.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: ColoredBox(color: palette.rewardScrim),
                ),
              ),
              Positioned.fromRect(
                rect: layout.card,
                child: GestureDetector(
                  key: const ValueKey('colouring-card'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _tapCard(details.localPosition, layout),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: PaintColours.paper,
                      borderRadius: BorderRadius.circular(
                        PuzzleConfig.colouringMargin,
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([widget.book, _fill, _drive]),
                      builder: (context, _) {
                        final drive = Curves.easeIn.transform(_drive.value);
                        return Transform.translate(
                          // Kâğıt yerinde kalır, araba ekranın sağından çıkar.
                          offset: Offset(
                            drive * (area.width - layout.card.left),
                            0,
                          ),
                          child: CustomPaint(
                            size: layout.card.size,
                            painter: CarPainter(
                              model: widget.book.car,
                              fills: widget.book.fills,
                              freshPart: _freshPart,
                              freshFrom: _freshFrom,
                              freshProgress:
                                  Curves.easeOut.transform(_fill.value),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              _strip(
                strip: PaletteStrip.hues,
                rect: layout.hues,
                layout: layout,
                label: 'Renk paleti',
                base: LinearGradient(
                  begin:
                      alongWidth ? Alignment.centerLeft : Alignment.topCenter,
                  end: alongWidth
                      ? Alignment.centerRight
                      : Alignment.bottomCenter,
                  colors: PaintColours.hueSweep,
                ),
                veil: PaintColours.shadeVeil(
                  begin:
                      alongWidth ? Alignment.topCenter : Alignment.centerLeft,
                  end: alongWidth
                      ? Alignment.bottomCenter
                      : Alignment.centerRight,
                ),
              ),
              _strip(
                strip: PaletteStrip.greys,
                rect: layout.greys,
                layout: layout,
                label: 'Gri tonları',
                base: PaintColours.greys,
              ),
              _marker(layout),
              _preview(layout),
              Positioned.fromRect(
                rect: layout.skip,
                child: Semantics(
                  button: true,
                  label: 'Geç',
                  child: GestureDetector(
                    key: const ValueKey('colouring-skip'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _finish,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.button,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: PuzzleConfig.colouringSkipButtonSize * 0.46,
                        color: palette.onButton,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Paletin bir şeridi. Dokunuş ve sürükleme aynı işi yapar: parmağın
  /// altındaki rengi seçer.
  Widget _strip({
    required PaletteStrip strip,
    required Rect rect,
    required ColouringLayout layout,
    required String label,
    required Gradient base,
    Gradient? veil,
  }) {
    const fill = SizedBox.expand();
    return Positioned.fromRect(
      rect: rect,
      child: Semantics(
        label: label,
        child: Listener(
          key: ValueKey('colouring-${strip.name}'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _pick(
            strip,
            rect.topLeft + event.localPosition,
            layout,
            touchDown: true,
          ),
          onPointerMove: (event) => _pick(
            strip,
            rect.topLeft + event.localPosition,
            layout,
            touchDown: false,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PuzzleConfig.colouringMargin),
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: base),
              child: veil == null
                  ? fill
                  : DecoratedBox(
                      decoration: BoxDecoration(gradient: veil),
                      child: fill,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Sol üst köşedeki kare: seçilen renk, parmağın örtmediği bir yerde
  /// (K-10). Dokunuşa kapalıdır; bir düğme değil, bir aynadır.
  Widget _preview(ColouringLayout layout) {
    return Positioned.fromRect(
      rect: layout.preview,
      child: IgnorePointer(
        child: Semantics(
          label: 'Seçilen renk',
          child: Container(
            key: const ValueKey('colouring-preview'),
            decoration: BoxDecoration(
              color: _choice.colour,
              borderRadius: BorderRadius.circular(
                PuzzleConfig.colouringPreviewCornerRadius,
              ),
              border: Border.all(
                color: PaintColours.ink,
                width: PuzzleConfig.colouringMarkerBorderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Seçilen noktadaki halka: içi seçilen renk, dışı siyah ve beyaz çift
  /// çerçeve, ki açık da koyu da her renk üstünde görünsün.
  Widget _marker(ColouringLayout layout) {
    const size = PuzzleConfig.colouringMarkerSize;
    final centre = layout.pointOf(_choice);
    return Positioned(
      left: centre.dx - size / 2,
      top: centre.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Container(
          key: const ValueKey('colouring-marker'),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: PaintColours.paper,
              width: PuzzleConfig.colouringMarkerBorderWidth,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _choice.colour,
              shape: BoxShape.circle,
              border: Border.all(
                color: PaintColours.ink,
                width: PuzzleConfig.colouringMarkerBorderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
