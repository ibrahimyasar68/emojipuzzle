import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/balloon.dart';
import '../providers/balloon_game_controller.dart';
import 'balloon_layout.dart';
import 'balloon_painter.dart';

/// Balon mini oyunu (§24): bir puzzle ile diğeri arasında kısa ve baskısız
/// bir ödül.
///
/// Bu özellik puzzle hakkında hiçbir şey bilmez (§36). Kendisine ihtiyaç
/// duyduğu iki servis ve bittiğini söyleyecek bir yol verilir; geri kalan
/// her şey — kaç balon, ne hızda geldikleri, ne zaman bittiği —
/// [BalloonGameController] içindedir ve bu widget yalnızca onu çizer.
///
/// Oyun renk eşleştirmedir (K-5): bir dokunuş balonu seçer, aynı renkten
/// ikinci bir dokunuş ikisini birlikte patlatır.
///
/// Burada hiçbir şey kaybedilemez. Süre dolduğunda hâlâ havada olan
/// balonlara dokunulmaz: mesaj yok, ses yok, surat yok (§20).
class BalloonGameOverlay extends StatefulWidget {
  const BalloonGameOverlay({
    super.key,
    required this.onFinished,
    this.audio,
    this.haptics = const HapticService(),
    this.controller,
  });

  /// Oyun bittiğinde bir kez çağrılır.
  final VoidCallback onFinished;

  /// Ses çıkaran tek yer (§27). Verilmezse sessizdir.
  final AudioService? audio;

  final HapticService? haptics;

  /// Balonları sabitlemek isteyen testler tarafından verilir; verilmezse
  /// widget kendi kurar.
  final BalloonGameController? controller;

  @override
  State<BalloonGameOverlay> createState() => _BalloonGameOverlayState();
}

class _BalloonGameOverlayState extends State<BalloonGameOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final BalloonGameController _game;
  late final bool _ownsGame;

  /// Çizim saati. Oyun kurallar için kendi saatini tutar; bu saat kare
  /// hızında işler ki balonlar akıcı süzülsün ve salınsın.
  late final AnimationController _clock;

  final List<_Burst> _bursts = [];
  bool _handedBack = false;

  /// Seçimin başladığı an, çizim saatinde; büyüme ve sallanma buradan
  /// ölçülür.
  Duration _selectedAt = Duration.zero;

  Duration get _elapsed => _clock.duration! * _clock.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsGame = widget.controller == null;
    _game = widget.controller ?? BalloonGameController();
    _game
      ..onFinished = _handBack
      ..addListener(_onGameChanged);

    _clock = AnimationController(vsync: this, duration: _game.timeLimit)
      ..forward();

    _game.start();
  }

  void _onGameChanged() {
    if (mounted) setState(() {});
  }

  void _handBack() {
    if (_handedBack) return;
    _handedBack = true;
    widget.onFinished();
  }

  /// §28 — bir ödülün on beş saniyesi, uygulama birinin cebindeyken akıp
  /// gitmez. Oyunun kendi saati ile çizim saati birlikte durur; böylece
  /// dönüldüğünde balonlar tam bırakıldıkları yerdedir.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _game.pause();
        _clock.stop();
      case AppLifecycleState.resumed:
        if (!mounted || _handedBack) return;
        _game.resume();
        _clock.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.removeListener(_onGameChanged);
    _game.onFinished = null;
    if (_ownsGame) _game.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _tap(Balloon balloon, Size playArea) {
    final wasSelected = _game.selectedId;
    final popped = _game.tap(balloon.id);

    if (popped.isEmpty) {
      // Yeni bir seçim: yalnızca bir dokunuş hissi. Ses yok — ses patlamanın
      // ödülüdür, farklı renkteki bir dokunuş da ceza değildir (§20).
      if (_game.selectedId != wasSelected) {
        _selectedAt = _elapsed;
        widget.haptics?.selection();
      }
      return;
    }

    final elapsed = _elapsed;
    setState(() {
      for (final gone in popped) {
        final rect = BalloonLayout.rectOf(gone, playArea, elapsed);
        _bursts.add(
          _Burst(
            balloon: gone,
            centre: rect.center,
            radius: rect.width / 2,
            startedAt: elapsed,
            // Seçili balon büyümüş haliyle patlar; küçülüp sonra şişmez.
            startScale:
                gone.id == wasSelected ? PuzzleConfig.balloonSelectedScale : 1,
          ),
        );
      }
    });

    // İki balon, tek patlama sesi. Önce animasyon, sonra ses — haptik en
    // sonda, çünkü oyunun vazgeçebileceği tek ses odur (§27).
    widget.audio?.playBalloonPop();
    widget.haptics?.light();
  }

  /// Seçili balon büyür; eşine nabız attırılan balon şişip iner (§24).
  double _scaleOf(Balloon balloon, Duration elapsed) {
    if (balloon.id == _game.selectedId) {
      final grow = ((elapsed - _selectedAt).inMicroseconds /
              PuzzleConfig.balloonSelectDuration.inMicroseconds)
          .clamp(0.0, 1.0);
      return 1 + (PuzzleConfig.balloonSelectedScale - 1) * grow;
    }
    if (balloon.id == _game.partnerHintId) {
      final phase = elapsed.inMicroseconds /
          PuzzleConfig.balloonPartnerHintPeriod.inMicroseconds;
      final pulse = 0.5 - 0.5 * math.cos(phase * 2 * math.pi);
      return 1 + (PuzzleConfig.balloonPartnerHintScale - 1) * pulse;
    }
    return 1;
  }

  /// Seçili balon hafifçe sallanır: seçim yalnızca boyuta bırakılmaz.
  double _wobbleOf(Balloon balloon, Duration elapsed) {
    if (balloon.id != _game.selectedId) return 0;
    final phase = (elapsed - _selectedAt).inMicroseconds /
        PuzzleConfig.balloonSelectedWobblePeriod.inMicroseconds;
    return math.sin(phase * 2 * math.pi) *
        PuzzleConfig.balloonSelectedWobbleRadians;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final playArea = constraints.biggest;
          return AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final elapsed = _elapsed;
              _bursts.removeWhere(
                (burst) =>
                    elapsed - burst.startedAt >=
                    PuzzleConfig.balloonPopDuration,
              );

              return Stack(
                key: const ValueKey('balloon-game'),
                children: [
                  // Balonu ıskalayan bir dokunuş hiçbir şey yapmaz, ama
                  // alttaki puzzle'a da ulaşmamalıdır.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                    ),
                  ),
                  for (final burst in _bursts)
                    ..._burstWidgets(burst, playArea, elapsed),
                  for (final balloon in _game.balloons)
                    _balloonWidget(balloon, playArea, elapsed),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _balloonWidget(Balloon balloon, Size playArea, Duration elapsed) {
    final rect = BalloonLayout.rectOf(balloon, playArea, elapsed);
    final diameter = BalloonLayout.diameterOf(balloon, playArea);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: diameter,
      height: diameter,
      child: GestureDetector(
        key: ValueKey('balloon-${balloon.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(balloon, playArea),
        child: Opacity(
          // Yavaşça beliriyor ama ilk kareden itibaren dokunulabilir:
          // çocuğun görebildiği balon, uzanabileceği balondur (§2).
          opacity: BalloonLayout.opacityOf(balloon, elapsed),
          // Büyüme ve sallanma yalnızca çizimdedir; dokunma alanı yerinde
          // kalır.
          child: Transform.rotate(
            angle: _wobbleOf(balloon, elapsed),
            child: CustomPaint(
              painter: BalloonPainter(
                colour:
                    balloonColours[balloon.colourIndex % balloonColours.length],
                stringColour: context.palette.balloonString,
                scale: _scaleOf(balloon, elapsed),
              ),
              size: Size.square(diameter),
            ),
          ),
        ),
      ),
    );
  }

  /// Balon şişip solarken parçaları dağılır (§24).
  List<Widget> _burstWidgets(_Burst burst, Size playArea, Duration elapsed) {
    final progress = ((elapsed - burst.startedAt).inMilliseconds /
            PuzzleConfig.balloonPopDuration.inMilliseconds)
        .clamp(0.0, 1.0);
    final colour =
        balloonColours[burst.balloon.colourIndex % balloonColours.length];
    final swell = burst.startScale +
        (PuzzleConfig.balloonPopScale - burst.startScale) *
            (progress * 2.5).clamp(0.0, 1.0);

    return [
      Positioned.fromRect(
        rect: Rect.fromCircle(center: burst.centre, radius: burst.radius),
        child: IgnorePointer(
          child: Opacity(
            opacity: (1 - progress).clamp(0.0, 1.0),
            child: CustomPaint(
              painter: BalloonPainter(
                colour: colour,
                stringColour: context.palette.balloonString,
                scale: swell,
              ),
              size: Size.square(burst.radius * 2),
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: BalloonBurstPainter(
              centre: burst.centre,
              colour: colour,
              radius: burst.radius,
              progress: progress,
            ),
            size: playArea,
          ),
        ),
      ),
    ];
  }
}

/// Dokunulduktan hemen sonraki anında bir balon.
class _Burst {
  const _Burst({
    required this.balloon,
    required this.centre,
    required this.radius,
    required this.startedAt,
    required this.startScale,
  });

  final Balloon balloon;

  /// Patlamanın hangi boyuttan başladığı: seçili balon zaten büyümüştür.
  final double startScale;

  /// Patladığı yerde dondurulur: parçalar salınımla birlikte kaymaz.
  final Offset centre;
  final double radius;
  final Duration startedAt;
}
