import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// WAV波形をDart内で生成して再生するサウンドサービス
/// アセットファイル不要
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  void setEnabled(bool enabled) => _enabled = enabled;
  bool get isEnabled => _enabled;

  // ─── 公開API ────────────────────────────────────────────────

  Future<void> playCorrect() => _play(_correctBytes());
  Future<void> playWrong() => _play(_wrongBytes());
  Future<void> playTap() => _play(_tapBytes());
  Future<void> playComplete() => _play(_completeBytes());
  Future<void> playStar() => _play(_starBytes());
  Future<void> playLevelUp() => _play(_levelUpBytes());
  Future<void> playCombo(int streak) => _play(_comboBytes(streak));

  Future<void> dispose() => _player.dispose();

  // ─── 再生 ────────────────────────────────────────────────────

  Future<void> _play(Uint8List wavBytes) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(wavBytes));
    } catch (_) {
      // サウンド再生失敗は無視
    }
  }

  // ─── WAV生成ヘルパー ─────────────────────────────────────────

  static const int _sampleRate = 22050;

  /// WAV ファイルのバイト列を生成
  Uint8List _buildWav(List<({double freq, int ms, double amp})> tones) {
    final allSamples = <int>[];

    for (final tone in tones) {
      final count = _sampleRate * tone.ms ~/ 1000;
      for (int i = 0; i < count; i++) {
        // エンベロープ：フェードアウト
        final env = 1.0 - (i / count) * 0.7;
        final sample = math.sin(2 * math.pi * tone.freq * i / _sampleRate) *
            tone.amp *
            env *
            32767;
        allSamples.add(sample.round().clamp(-32768, 32767));
      }
      // 音符間の無音 (20ms)
      final silence = _sampleRate * 20 ~/ 1000;
      for (int i = 0; i < silence; i++) {
        allSamples.add(0);
      }
    }

    final dataSize = allSamples.length * 2;
    final bytes = ByteData(44 + dataSize);

    // RIFF ヘッダー
    _writeString(bytes, 0, 'RIFF');
    bytes.setUint32(4, 36 + dataSize, Endian.little);
    _writeString(bytes, 8, 'WAVE');
    _writeString(bytes, 12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little); // chunk size
    bytes.setUint16(20, 1, Endian.little);  // PCM
    bytes.setUint16(22, 1, Endian.little);  // mono
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, _sampleRate * 2, Endian.little); // byte rate
    bytes.setUint16(32, 2, Endian.little);  // block align
    bytes.setUint16(34, 16, Endian.little); // bits per sample
    _writeString(bytes, 36, 'data');
    bytes.setUint32(40, dataSize, Endian.little);

    // PCM データ
    for (int i = 0; i < allSamples.length; i++) {
      bytes.setInt16(44 + i * 2, allSamples[i], Endian.little);
    }

    return bytes.buffer.asUint8List();
  }

  void _writeString(ByteData data, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  // ─── 音パターン定義 ─────────────────────────────────────────

  /// 正解音: C5→E5 上昇
  Uint8List _correctBytes() => _buildWav([
        (freq: 523.25, ms: 120, amp: 0.5), // C5
        (freq: 659.25, ms: 150, amp: 0.5), // E5
      ]);

  /// 不正解音: 低いブー
  Uint8List _wrongBytes() => _buildWav([
        (freq: 220.0, ms: 200, amp: 0.4), // A3
        (freq: 196.0, ms: 200, amp: 0.3), // G3
      ]);

  /// タップ音: 短いクリック
  Uint8List _tapBytes() => _buildWav([
        (freq: 880.0, ms: 40, amp: 0.25), // A5
      ]);

  /// クリア音: C5→G5 ファンファーレ
  Uint8List _completeBytes() => _buildWav([
        (freq: 523.25, ms: 100, amp: 0.5), // C5
        (freq: 659.25, ms: 100, amp: 0.5), // E5
        (freq: 783.99, ms: 200, amp: 0.6), // G5
      ]);

  /// スター獲得音: きらきら
  Uint8List _starBytes() => _buildWav([
        (freq: 1046.5, ms: 80, amp: 0.4), // C6
        (freq: 1318.5, ms: 80, amp: 0.4), // E6
        (freq: 1567.98, ms: 120, amp: 0.5), // G6
      ]);

  /// レベルアップ音: 上昇アルペジオ C5→E5→G5→C6
  Uint8List _levelUpBytes() => _buildWav([
        (freq: 523.25, ms: 100, amp: 0.5),  // C5
        (freq: 659.25, ms: 100, amp: 0.5),  // E5
        (freq: 783.99, ms: 100, amp: 0.55), // G5
        (freq: 1046.5, ms: 300, amp: 0.65), // C6（伸ばす）
      ]);

  /// コンボ音: 連続正解数に応じて音が高くなる（2連続〜）
  Uint8List _comboBytes(int streak) {
    // streak=2 → E5, streak=3 → G5, streak=4+ → C6
    final freq = streak == 2
        ? 659.25  // E5
        : streak == 3
            ? 783.99 // G5
            : 1046.5; // C6
    final amp = 0.35 + (streak.clamp(2, 5) - 2) * 0.05;
    return _buildWav([
      (freq: freq * 0.75, ms: 50, amp: amp * 0.8),
      (freq: freq, ms: 120, amp: amp),
    ]);
  }
}
