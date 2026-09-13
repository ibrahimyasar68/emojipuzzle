import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../puzzle/models/puzzle_definition.dart';
import 'sticker_tile.dart';

/// "Bu artık senin." Çocuğun az önce kazandığı çıkartma, sonraki resimden
/// önce bir an gösterilir (§23, §25).
///
/// Tamamlama dizisinin son ve en kısa adımıdır: çıkartmaların yaşadığı yer
/// albümdür, burası yalnızca teslim anıdır. Dizideki her şey gibi, bir
/// dokunuş onu anında bitirir (§23).
class StickerRewardOverlay extends StatefulWidget {
  const StickerRewardOverlay({
    super.key,
    required this.puzzle,
    required this.onFinished,
    this.duration = PuzzleConfig.stickerRewardDuration,
  });

  final PuzzleDefinition puzzle;
  final VoidCallback onFinished;
  final Duration duration;

  @override
  State<StickerRewardOverlay> createState() => _StickerRewardOverlayState();
}

class _StickerRewardOverlayState extends State<StickerRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  Timer? _end;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: PuzzleConfig.stickerRewardPopDuration,
    )..forward();
    _end = Timer(widget.duration, _finish);
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    _end?.cancel();
    _end = null;
    widget.onFinished();
  }

  @override
  void dispose() {
    _end?.cancel();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        key: const ValueKey('sticker-reward'),
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: ColoredBox(
          color: context.palette.rewardScrim,
          child: Center(
            child: ScaleTransition(
              scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
              child: StickerTile(
                puzzle: widget.puzzle,
                earned: true,
                size: PuzzleConfig.stickerRewardSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
