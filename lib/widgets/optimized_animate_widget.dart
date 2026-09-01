import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/battery_service.dart';

/// Optimized animation widget that respects battery level
/// Reduces animation complexity in low-battery mode
class OptimizedAnimateWidget extends ConsumerWidget {
  final Widget child;
  final Duration duration;
  final Duration? delay;
  final Curve curve;
  final VoidCallback? onComplete;

  const OptimizedAnimateWidget({
    required this.child,
    required this.duration,
    this.delay,
    this.curve = Curves.easeInOut,
    this.onComplete,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryService = BatteryService();
    final durationMultiplier = batteryService.animationDurationMultiplier;

    // Adjust animation duration based on battery level
    // Low battery mode: shorter animations (faster responsiveness)
    final adjustedDuration = duration * durationMultiplier;

    return child.animate().fadeIn(
          duration: adjustedDuration,
          curve: curve,
          delay: delay,
        );
  }
}

/// Extension to easily apply battery-aware animations
extension OptimizedAnimateExtension on Widget {
  /// Apply fade-in animation with battery optimization
  Widget fadeInOptimized({
    Duration duration = const Duration(milliseconds: 300),
    Duration? delay,
    Curve curve = Curves.easeInOut,
  }) {
    final batteryService = BatteryService();
    final adjustedDuration = duration * batteryService.animationDurationMultiplier;

    return animate()
        .fadeIn(
          duration: adjustedDuration,
          curve: curve,
          delay: delay,
        )
        .then()
        .callback(() {
          // Optional callback on animation complete
        });
  }

  /// Apply scale animation with battery optimization
  Widget scaleOptimized({
    Duration duration = const Duration(milliseconds: 300),
    Duration? delay,
    Curve curve = Curves.easeInOut,
    double begin = 0.8,
    double end = 1.0,
  }) {
    final batteryService = BatteryService();
    final adjustedDuration = duration * batteryService.animationDurationMultiplier;

    return animate()
        .scale(
          duration: adjustedDuration,
          curve: curve,
          delay: delay,
          begin: begin,
          end: end,
        );
  }

  /// Apply slide animation with battery optimization
  Widget slideOptimized({
    Duration duration = const Duration(milliseconds: 300),
    Duration? delay,
    Curve curve = Curves.easeInOut,
    Offset begin = const Offset(-1, 0),
    Offset end = Offset.zero,
  }) {
    final batteryService = BatteryService();
    final adjustedDuration = duration * batteryService.animationDurationMultiplier;

    return animate()
        .slide(
          duration: adjustedDuration,
          curve: curve,
          delay: delay,
          begin: begin,
          end: end,
        );
  }
}

/// Throttled animation controller for expensive animations
class ThrottledAnimationController extends TickerProvider {
  final TickerProvider vsync;
  final int targetFps;
  late Ticker _ticker;
  late Duration _lastUpdate;

  ThrottledAnimationController({
    required this.vsync,
    this.targetFps = 60,
  });

  @override
  Ticker createTicker(TickerCallback onTick) {
    final Duration frameDuration = Duration(
      microseconds: (1000000 / targetFps).toInt(),
    );

    _lastUpdate = Duration.zero;

    return Ticker((Duration elapsed) {
      if (elapsed - _lastUpdate >= frameDuration) {
        _lastUpdate = elapsed;
        onTick(elapsed);
      }
    });
  }
}
