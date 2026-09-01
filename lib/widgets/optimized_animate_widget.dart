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
        );
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

/// Throttled animation controller configuration for expensive animations
/// Note: Limits animation frame rate based on battery level
/// Implementation: Use with TickerProvider from Flutter framework
class ThrottledAnimationConfig {
  final int targetFps;
  late Duration _lastUpdate;

  ThrottledAnimationConfig({
    this.targetFps = 60,
  });

  /// Get frame duration for target FPS
  Duration get frameDuration => Duration(
    microseconds: (1000000 / targetFps).toInt(),
  );

  /// Reset animation state
  void reset() {
    _lastUpdate = Duration.zero;
  }

  /// Check if frame should render based on elapsed time
  bool shouldRenderFrame(Duration elapsed) {
    if (elapsed - _lastUpdate >= frameDuration) {
      _lastUpdate = elapsed;
      return true;
    }
    return false;
  }
}
