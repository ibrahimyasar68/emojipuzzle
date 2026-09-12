// Generates the game's sound effects as 16-bit PCM WAV files.
//
//   dart run tool/generate_sfx.dart
//
// The sounds are synthesised rather than downloaded: no licence to track
// (§33), no network, and re-running this produces byte-identical files. They
// are placeholders in the sense that a real sound designer would do better,
// not in the sense that they are silent — each one is tuned to be short,
// soft and friendly for a 3-year-old (§22, §27).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sampleRate = 44100;

void main() {
  final directory = Directory('assets/audio/sfx')..createSync(recursive: true);

  _write('${directory.path}/piece_snap.wav', _pieceSnap());
  _write('${directory.path}/puzzle_complete.wav', _puzzleComplete());
  _write('${directory.path}/balloon_pop.wav', _balloonPop());
  _write('${directory.path}/hint.wav', _hint());
}

void _write(String path, List<double> samples) {
  File(path).writeAsBytesSync(_wav(samples));
  stdout.writeln('$path — ${(samples.length / sampleRate * 1000).round()} ms');
}

/// A piece dropping into place: a soft blip that falls in pitch (§22).
List<double> _pieceSnap() {
  const duration = 0.12;
  return _generate(duration, (t) {
    final progress = t / duration;
    final frequency = 900 * math.pow(0.55, progress);
    final envelope = _attackDecay(progress, attack: 0.04, curve: 4);
    return 0.55 * envelope * math.sin(2 * math.pi * frequency * t);
  });
}

/// The picture is finished: a little rising phrase (§23).
List<double> _puzzleComplete() {
  const notes = [523.25, 659.25, 783.99, 1046.50]; // C5 E5 G5 C6
  const noteLength = 0.16;
  final duration = noteLength * notes.length;

  return _generate(duration, (t) {
    var value = 0.0;
    for (var i = 0; i < notes.length; i++) {
      final start = i * noteLength;
      final local = t - start;
      // Notes overlap slightly, so the phrase sings instead of stuttering.
      if (local < 0 || local > noteLength * 1.6) continue;
      final progress = local / (noteLength * 1.6);
      final envelope = _attackDecay(progress, attack: 0.06, curve: 3);
      value += 0.28 * envelope * math.sin(2 * math.pi * notes[i] * local);
    }
    return value;
  });
}

/// A balloon giving up: a puff of noise over a low thump (§24).
List<double> _balloonPop() {
  const duration = 0.15;
  final random = math.Random(7); // fixed, so the file never changes
  return _generate(duration, (t) {
    final progress = t / duration;
    final noise = (random.nextDouble() * 2 - 1) *
        _attackDecay(progress, attack: 0.01, curve: 9);
    final thump = math.sin(2 * math.pi * 140 * t) *
        _attackDecay(progress, attack: 0.02, curve: 5);
    return 0.45 * noise + 0.35 * thump;
  });
}

/// "Look at this one": two gentle tones, never a buzzer (§21).
List<double> _hint() {
  const notes = [783.99, 1046.50]; // G5 C6
  const noteLength = 0.2;
  final duration = noteLength * notes.length;

  return _generate(duration, (t) {
    final index = (t / noteLength).floor().clamp(0, notes.length - 1);
    final local = t - index * noteLength;
    final progress = local / noteLength;
    final envelope = _attackDecay(progress, attack: 0.2, curve: 2);
    return 0.32 * envelope * math.sin(2 * math.pi * notes[index] * local);
  });
}

/// Rises over [attack] of the sound, then falls away; [curve] sets how
/// quickly. Keeps every effect free of clicks at both ends.
double _attackDecay(double progress,
    {required double attack, required double curve}) {
  if (progress <= 0 || progress >= 1) return 0;
  if (progress < attack) return progress / attack;
  final decay = (progress - attack) / (1 - attack);
  return math.pow(1 - decay, curve).toDouble();
}

List<double> _generate(double duration, double Function(double t) sample) {
  final count = (duration * sampleRate).round();
  return [
    for (var i = 0; i < count; i++) sample(i / sampleRate),
  ];
}

/// 16-bit PCM, mono — the least surprising thing every platform can play.
Uint8List _wav(List<double> samples) {
  const bitsPerSample = 16;
  const channels = 1;
  final dataBytes = samples.length * 2;

  final bytes = BytesBuilder();
  void ascii(String text) => bytes.add(text.codeUnits);
  void uint32(int value) => bytes.add(
      Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little));
  void uint16(int value) => bytes.add(
      Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little));

  ascii('RIFF');
  uint32(36 + dataBytes);
  ascii('WAVE');
  ascii('fmt ');
  uint32(16);
  uint16(1); // PCM
  uint16(channels);
  uint32(sampleRate);
  uint32(sampleRate * channels * bitsPerSample ~/ 8);
  uint16(channels * bitsPerSample ~/ 8);
  uint16(bitsPerSample);
  ascii('data');
  uint32(dataBytes);

  final pcm = Uint8List(dataBytes);
  final view = pcm.buffer.asByteData();
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    view.setInt16(i * 2, (clamped * 32767).round(), Endian.little);
  }
  bytes.add(pcm);

  return bytes.toBytes();
}
