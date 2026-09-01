import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'battery_service.dart';

/// Optimized HTTP client with battery-aware request throttling
class OptimizedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final BatteryService _batteryService = BatteryService();

  /// Rate limit requests based on battery level
  /// Low battery: 1 request per 5 seconds
  /// Medium battery: 1 request per 2 seconds
  /// Normal: unlimited (1 request per second minimum)
  Duration get _requestThrottleInterval {
    if (_batteryService.isLowBattery) {
      return const Duration(seconds: 5);
    } else if (_batteryService.isMediumBattery) {
      return const Duration(seconds: 2);
    }
    return const Duration(seconds: 1);
  }

  DateTime? _lastRequestTime;

  OptimizedHttpClient([http.Client? innerClient])
      : _inner = innerClient ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Apply request throttling based on battery level
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _requestThrottleInterval) {
        await Future.delayed(
          _requestThrottleInterval - timeSinceLastRequest,
        );
      }
    }

    _lastRequestTime = DateTime.now();

    // Add compression headers
    request.headers['Accept-Encoding'] = 'gzip';
    request.headers['Accept'] = 'application/json';

    try {
      final response = await _inner.send(request);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get recommended polling interval based on battery level
  Duration getPollingInterval({
    Duration normalInterval = const Duration(seconds: 1),
  }) {
    if (_batteryService.isLowBattery) {
      return normalInterval * 5;
    } else if (_batteryService.isMediumBattery) {
      return normalInterval * 2;
    }
    return normalInterval;
  }

  /// Set battery level for testing purposes
  @visibleForTesting
  void setBatteryLevelForTesting(int level) {
    _batteryService.setBatteryLevelForTesting(level);
  }
}

/// API polling service with battery-aware throttling
class APIPollingService {
  final OptimizedHttpClient _httpClient = OptimizedHttpClient();
  final BatteryService _batteryService = BatteryService();

  /// Get next polling time based on battery state
  Duration getNextPollDelay({
    Duration defaultDelay = const Duration(seconds: 30),
  }) {
    return _httpClient.getPollingInterval(normalInterval: defaultDelay);
  }

  /// Should we perform background sync?
  /// Avoid background work in low battery mode
  bool shouldPerformBackgroundSync() {
    // Skip background sync if battery is below 20%
    return !_batteryService.isLowBattery;
  }

  /// Should we fetch high-resolution assets?
  /// Use lower resolution in medium/low battery mode
  bool shouldFetchHighResAssets() {
    // Only fetch high-res assets when battery is above 50%
    return !_batteryService.isMediumBattery && !_batteryService.isLowBattery;
  }

  /// Set battery level for testing purposes
  @visibleForTesting
  void setBatteryLevelForTesting(int level) {
    _batteryService.setBatteryLevelForTesting(level);
  }
}
