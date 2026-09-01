import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring device battery level
/// Adjusts animation performance based on battery state
class BatteryService with ChangeNotifier {
  static final BatteryService _instance = BatteryService._internal();

  factory BatteryService() => _instance;
  BatteryService._internal();

  final _battery = Battery();
  late BatteryState _batteryState;
  int _batteryLevel = 100;
  bool _isLowBattery = false;
  bool _isMediumBattery = false;

  /// Get current battery level (0-100)
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
    _batteryState = await _battery.batteryState;
    _batteryLevel = await _battery.batteryLevel;
    _updateBatteryState();

    // Listen to battery state changes
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _batteryState = state;
      notifyListeners();
    });
  }

  /// Update battery level and thresholds
  Future<void> updateBatteryLevel() async {
    final level = await _battery.batteryLevel;
    if (level != _batteryLevel) {
      _batteryLevel = level;
      _updateBatteryState();
      notifyListeners();
    }
  }

  /// Internal: Update battery state based on level
  void _updateBatteryState() {
    _isLowBattery = _batteryLevel < 20;
    _isMediumBattery = _batteryLevel >= 20 && _batteryLevel < 50;
  }
}
