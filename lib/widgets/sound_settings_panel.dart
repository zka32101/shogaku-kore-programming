import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bgm_provider.dart';
import '../services/sound_service.dart';
import '../services/haptic_service.dart';

class SoundSettingsPanel extends ConsumerWidget {
  const SoundSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgmState = ref.watch(bgmProvider);
    final soundService = SoundService();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル
          const Text(
            '🔊 サウンド設定',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // SFX トグル
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('効果音（SFX）'),
              Switch(
                value: soundService.isEnabled,
                onChanged: (value) {
                  HapticService.lightImpact();
                  soundService.setEnabled(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // BGM トグル
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BGM'),
              Switch(
                value: bgmState.isEnabled,
                onChanged: (value) {
                  HapticService.lightImpact();
                  ref.read(bgmProvider.notifier).toggleBgm();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // BGM ボリュームスライダー
          if (bgmState.isEnabled) ...[
            const Text(
              'BGM ボリューム',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.volume_down, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: bgmState.volume,
                    onChanged: (value) {
                      ref.read(bgmProvider.notifier).setVolume(value);
                    },
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.volume_up, size: 18),
              ],
            ),
            const SizedBox(height: 12),

            // 現在のトラック表示
            if (bgmState.currentTrack != null)
              Text(
                '現在: ${bgmState.currentTrack}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
