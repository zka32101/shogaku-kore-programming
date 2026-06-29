import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

const _kBgmEnabledKey = 'bgm_enabled';
const _kBgmVolumeKey = 'bgm_volume';

class BgmState {
  final bool isEnabled;
  final double volume; // 0.0 ~ 1.0
  final String? currentTrack;
  final bool isPlaying;

  const BgmState({
    this.isEnabled = true,
    this.volume = 0.7,
    this.currentTrack,
    this.isPlaying = false,
  });
}

class BgmNotifier extends StateNotifier<BgmState> {
  final AudioPlayer _player = AudioPlayer();

  BgmNotifier() : super(const BgmState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kBgmEnabledKey) ?? true;
      final volume = prefs.getDouble(_kBgmVolumeKey) ?? 0.7;

      state = BgmState(
        isEnabled: enabled,
        volume: volume,
        currentTrack: state.currentTrack,
        isPlaying: state.isPlaying,
      );

      await _player.setVolume(volume);
    } catch (e) {
      // 設定読み込み失敗は無視
    }
  }

  Future<void> playBgm(String trackName) async {
    if (!state.isEnabled) return;

    try {
      // ステージBGM（シンプルなループ生成）
      final bgmData = _generateBgmData(trackName);
      await _player.play(BytesSource(bgmData));

      state = BgmState(
        isEnabled: state.isEnabled,
        volume: state.volume,
        currentTrack: trackName,
        isPlaying: true,
      );
    } catch (e) {
      state = BgmState(
        isEnabled: state.isEnabled,
        volume: state.volume,
        currentTrack: state.currentTrack,
        isPlaying: false,
      );
    }
  }

  Future<void> stopBgm() async {
    try {
      await _player.stop();
      state = BgmState(
        isEnabled: state.isEnabled,
        volume: state.volume,
        currentTrack: state.currentTrack,
        isPlaying: false,
      );
    } catch (e) {
      // 停止失敗は無視
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _player.setVolume(clampedVolume);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kBgmVolumeKey, clampedVolume);

      state = BgmState(
        isEnabled: state.isEnabled,
        volume: clampedVolume,
        currentTrack: state.currentTrack,
        isPlaying: state.isPlaying,
      );
    } catch (e) {
      // ボリューム設定失敗は無視
    }
  }

  Future<void> toggleBgm() async {
    try {
      final newEnabled = !state.isEnabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kBgmEnabledKey, newEnabled);

      if (!newEnabled) {
        await _player.stop();
      }

      state = BgmState(
        isEnabled: newEnabled,
        volume: state.volume,
        currentTrack: state.currentTrack,
        isPlaying: newEnabled && state.isPlaying,
      );
    } catch (e) {
      // トグル失敗は無視
    }
  }

  /// シンプルなループBGMを生成（実装例）
  Uint8List _generateBgmData(String trackName) {
    // 16ビット、22.05kHz、1秒間のシンプルなトーン
    const sampleRate = 22050;
    const duration = 1; // 秒
    const frequency = 440.0; // A4

    final samples = <int>[];
    for (int i = 0; i < sampleRate * duration; i++) {
      final value = (32767 * 0.3 * math.sin(2 * math.pi * frequency * i / sampleRate)).toInt();
      samples.add(value & 0xFF);
      samples.add((value >> 8) & 0xFF);
    }

    return Uint8List.fromList(samples);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final bgmProvider = StateNotifierProvider<BgmNotifier, BgmState>((ref) {
  return BgmNotifier();
});
