import 'package:flutter/foundation.dart';

/// Service for monitoring device battery level (lightweight implementation)
/// Adjusts animation performance based on battery state
///
/// Note: This is a lightweight implementation that doesn't require
/// platform-specific battery plugins. In production, this should be
/// extended with actual battery monitoring using platform channels.
class BatteryService with ChangeNotifier {
  static final BatteryService _instance = BatteryService._internal();

  factory BatteryService() => _instance;
  BatteryService._internal();

  int _batteryLevel = 100;
  bool _isLowBattery = false;
  bool _isMediumBattery = false;

  /// Get current battery level (0-100)
  /// Default: 100 (full battery) - actual level requires platform channel
  int get batteryLevel => _batteryLevel;

  /// Check if device is in low battery mode
  bool get isLowBattery => _isLowBattery;

  /// Check if device is in medium battery mode
  bool get isMediumBattery => _isMediumBattery;

  /// Get animation duration multiplier based on battery level
  /// Low battery: 0.5x (faster animations, less processing)
  /// Medium battery: 0.75x
  /// Normal: 1.0x
  double get animationDurationMultiplier {
    if (_isLowBattery) return 0.5;
    if (_isMediumBattery) return 0.75;
    return 1.0;
  }

  /// Get animation frame rate based on battery level
  /// Low battery: 24 fps
  /// Medium battery: 30 fps
  /// Normal: 60 fps
  int get animationFrameRate {
    if (_isLowBattery) return 24;
    if (_isMediumBattery) return 30;
    return 60;
  }

  /// Initialize battery monitoring
  Future<void> initialize() async {
    // In a real implementation, this would use platform channels
    // to get actual battery level from the device
    _updateBatteryState();
    notifyListeners();
  }

  /// Update battery level and thresholds
  /// Can be called periodically or when battery state changes
  Future<void> updateBatteryLevel([int? level]) async {
    final newLevel = level ?? _batteryLevel;
    if (newLevel != _batteryLevel) {
      _batteryLevel = newLevel;
      _updateBatteryState();
      notifyListeners();
    }
  }

  /// Internal: Update battery state based on level
  void _updateBatteryState() {
    _isLowBattery = _batteryLevel < 20;
    _isMediumBattery = _batteryLevel >= 20 && _batteryLevel < 50;
  }

  /// Set battery level for testing purposes
  void setBatteryLevelForTesting(int level) {
    _batteryLevel = level;
    _updateBatteryState();
    notifyListeners();
  }
}
