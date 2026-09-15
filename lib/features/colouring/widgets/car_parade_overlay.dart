import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_theme.dart';
import '../data/paint_colours.dart';
import '../models/car_model.dart';
import '../providers/colouring_book.dart';
import 'car_painter.dart';

/// Oyun sonu (K-15): çocuğun bu oyunda boyadığı arabalar sırayla gelip yan
/// yana durur.
///
/// Dikey ekranda alt alta, yatay ekranda yan yana. Bir süre sonra kendiliğinden
/// biter; bir dokunuş daha erken bitirir (§23). Zamanlama animasyon
/// denetleyicisiyledir, arka planda durur (§28).
class CarParadeOverlay extends StatefulWidget {
  const CarParadeOverlay({
    super.key,
    required this.cars,
    required this.onFinished,
    this.audio,
    this.duration = PuzzleConfig.carParadeDuration,
  });

  final List<FinishedCar> cars;

  /// Bir kez çağrılır.
  final VoidCallback onFinished;

  final AudioService? audio;
  final Duration duration;

  @override
  State<CarParadeOverlay> createState() => _CarParadeOverlayState();
}

class _CarParadeOverlayState extends State<CarParadeOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: PuzzleConfig.carParadeEnterDuration,
  )..forward();
  late final AnimationController _stay = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    widget.audio?.playPuzzleComplete();
    _stay
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _stay.dispose();
    super.dispose();
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = CarModel.designSize.width / CarModel.designSize.height;
    const gap = PuzzleConfig.colouringGap;
    const margin = PuzzleConfig.colouringMargin;
    final cars = widget.cars;

    return Positioned.fill(
      child: GestureDetector(
        key: const ValueKey('car-parade'),
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: ColoredBox(
          color: context.palette.rewardScrim,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final area = constraints.biggest;
              final portrait = area.height >= area.width;
              final count = math.max(cars.length, 1);
              final along = (portrait ? area.height : area.width) -
                  2 * margin -
                  (count - 1) * gap;
              final across = (portrait ? area.width : area.height) - 2 * margin;
              final slot = along / count;
              final width = math.max(
                0.0,
                math.min(
                  PuzzleConfig.colouringMaxCardWidth,
                  portrait
                      ? math.min(across, slot * aspect)
                      : math.min(slot, across * aspect),
                ),
              );

              final cards = [
                for (var i = 0; i < cars.length; i++)
                  _card(i, cars.length, cars[i], Size(width, width / aspect)),
              ];
              return Center(
                child: Flex(
                  direction: portrait ? Axis.vertical : Axis.horizontal,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: gap, height: gap),
                      cards[i],
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Arabalar birer birer, sırayla belirir.
  Widget _card(int index, int count, FinishedCar car, Size size) {
    final start = index / (count + 1);
    final end = (index + 2) / (count + 1);
    final curve = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, math.min(end, 1), curve: Curves.easeOutBack),
    );
    return ScaleTransition(
      key: ValueKey('parade-car-$index'),
      scale: curve,
      child: SizedBox.fromSize(
        size: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PaintColours.paper,
            borderRadius: BorderRadius.circular(PuzzleConfig.colouringMargin),
          ),
          child: CustomPaint(
            size: size,
            painter: CarPainter(model: car.model, fills: car.fills),
          ),
        ),
      ),
    );
  }
}
