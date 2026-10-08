import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'decor_items.dart';
import 'decor_provider.dart';

/// 画面の下へ「いまのきせかえ」を伝える。背景つきのとき、各画面は自分の背景色を透明にする。
class DecorScope extends InheritedWidget {
  const DecorScope({super.key, required this.hasBackground, this.frameAsset, required super.child});

  final bool hasBackground;

  /// つけているフレームの画像。なければ null。
  final String? frameAsset;

  static DecorScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<DecorScope>();

  /// 画面（Scaffold）の背景色。背景をつけているときは透明にして、背景の絵を見せる。
  static Color pageBg(BuildContext context, Color fallback) =>
      (maybeOf(context)?.hasBackground ?? false) ? Colors.transparent : fallback;

  /// 背景つきのとき、背景に直接載る文字の下に敷く白いうすい地。なければ透明。
  static Color chipBg(BuildContext context) =>
      (maybeOf(context)?.hasBackground ?? false) ? Colors.white.withValues(alpha: 0.82) : Colors.transparent;

  @override
  bool updateShouldNotify(DecorScope oldWidget) =>
      hasBackground != oldWidget.hasBackground || frameAsset != oldWidget.frameAsset;
}

/// アプリ全体の背景とエフェクトを敷く。MaterialApp の builder に置く。
///
/// - 背景: 全画面の後ろに絵を敷き、文字が読めるよう、うすい膜（ライトは白・ダークは濃紺）を重ねる
/// - エフェクト: 全画面の前に重ねる（雪は全面・波は下端）。タップは通す
/// - 何もつけていなければ、子をそのまま返す（見た目は変わらない）
class DecorBackdrop extends ConsumerWidget {
  const DecorBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeDecorProvider);
    final bg = decorItemById(active.background);
    final fx = decorItemById(active.effect);
    final frame = decorItemById(active.frame);

    var content = child;
    if (bg != null) {
      final theme = Theme.of(context);
      content = Theme(
        data: theme.copyWith(scaffoldBackgroundColor: Colors.transparent),
        child: content,
      );
    }
    content = DecorScope(hasBackground: bg != null, frameAsset: frame?.asset, child: content);
    if (bg == null && fx == null) return content;

    final dark = Theme.of(context).brightness == Brightness.dark;
    final veil = dark ? const Color(0xFF12121E).withValues(alpha: 0.62) : Colors.white.withValues(alpha: 0.58);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (bg != null) ...[
          Positioned.fill(child: Image.asset(bg.asset, fit: BoxFit.cover, excludeFromSemantics: true)),
          Positioned.fill(child: ColoredBox(color: veil)),
        ],
        content,
        // 白い雲の背景でも、白い時計・電池アイコンが読めるよう、上端にうすい暗い帯を敷く
        if (bg != null)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: MediaQuery.paddingOf(context).top + 6,
            child: const IgnorePointer(
              child: DecoratedBox(
                key: ValueKey('decor_status_scrim'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x59000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
        if (fx != null) Positioned.fill(child: IgnorePointer(child: _Effect(fx.id))),
      ],
    );
  }
}

class _Effect extends StatelessWidget {
  const _Effect(this.id);
  final String id;

  @override
  Widget build(BuildContext context) {
    final asset = 'assets/shop/$id.webp';
    if (id == 'effect_waves') {
      // 下ナビや下部の内容を隠さないよう、画面高の12%以下・半透明にする
      final h = MediaQuery.sizeOf(context).height * 0.12;
      return Align(
        alignment: Alignment.bottomCenter,
        child: Opacity(
          key: const ValueKey('decor_waves'),
          opacity: 0.55,
          child: SizedBox(
            width: double.infinity,
            height: h,
            child: Image.asset(asset,
                fit: BoxFit.cover, alignment: Alignment.bottomCenter, excludeFromSemantics: true),
          ),
        ),
      );
    }
    return Image.asset(asset, fit: BoxFit.cover, excludeFromSemantics: true);
  }
}

/// アバターなどの丸い絵に、つけているフレームを重ねる。フレームがなければ子をそのまま返す。
class DecorFrame extends StatelessWidget {
  const DecorFrame({super.key, required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frame = DecorScope.maybeOf(context)?.frameAsset;
    // 小さいアイコンではフレームの絵が潰れるので出さない
    if (frame == null || size < 28) return child;
    final f = size * 1.5;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            left: -(f - size) / 2,
            top: -(f - size) / 2,
            width: f,
            height: f,
            child: IgnorePointer(child: Image.asset(frame, fit: BoxFit.contain, excludeFromSemantics: true)),
          ),
        ],
      ),
    );
  }
}
