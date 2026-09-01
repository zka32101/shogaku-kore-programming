import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/services/optimized_http_client.dart';
import 'package:shogaku_kore_programming/services/battery_service.dart';

void main() {
  group('OptimizedHttpClient', () {
    late OptimizedHttpClient httpClient;

    setUp(() {
      httpClient = OptimizedHttpClient();
    });

    group('Request Throttle Interval', () {
      test('low battery returns 5 second interval', () {
        httpClient._batteryService._batteryLevel = 15;
        httpClient._batteryService._updateBatteryState();

        expect(
          httpClient._requestThrottleInterval,
          const Duration(seconds: 5),
        );
      });

      test('medium battery returns 2 second interval', () {
        httpClient._batteryService._batteryLevel = 40;
        httpClient._batteryService._updateBatteryState();

        expect(
          httpClient._requestThrottleInterval,
          const Duration(seconds: 2),
        );
      });

      test('normal battery returns 1 second interval', () {
        httpClient._batteryService._batteryLevel = 80;
        httpClient._batteryService._updateBatteryState();

        expect(
          httpClient._requestThrottleInterval,
          const Duration(seconds: 1),
        );
      });
    });

    group('Polling Interval', () {
      test('low battery multiplies default interval by 5', () {
        httpClient._batteryService._batteryLevel = 10;
        httpClient._batteryService._updateBatteryState();

        final interval = httpClient.getPollingInterval(
          normalInterval: const Duration(seconds: 10),
        );
        expect(interval, const Duration(seconds: 50));
      });

      test('medium battery multiplies default interval by 2', () {
        httpClient._batteryService._batteryLevel = 35;
        httpClient._batteryService._updateBatteryState();

        final interval = httpClient.getPollingInterval(
          normalInterval: const Duration(seconds: 10),
        );
        expect(interval, const Duration(seconds: 20));
      });

      test('normal battery uses default interval', () {
        httpClient._batteryService._batteryLevel = 100;
        httpClient._batteryService._updateBatteryState();

        final interval = httpClient.getPollingInterval(
          normalInterval: const Duration(seconds: 10),
        );
        expect(interval, const Duration(seconds: 10));
      });
    });
  });

  group('APIPollingService', () {
    late APIPollingService pollingService;

    setUp(() {
      pollingService = APIPollingService();
    });

    group('Background Sync Decision', () {
      test('should skip background sync in low battery mode', () {
        pollingService._batteryService._batteryLevel = 15;
        pollingService._batteryService._updateBatteryState();

        expect(pollingService.shouldPerformBackgroundSync(), false);
      });

      test('should perform background sync in normal battery mode', () {
        pollingService._batteryService._batteryLevel = 100;
        pollingService._batteryService._updateBatteryState();

        expect(pollingService.shouldPerformBackgroundSync(), true);
      });
    });

    group('High-Resolution Asset Decision', () {
      test('should not fetch high-res assets in low battery', () {
        pollingService._batteryService._batteryLevel = 15;
        pollingService._batteryService._updateBatteryState();

        expect(pollingService.shouldFetchHighResAssets(), false);
      });

      test('should not fetch high-res assets in medium battery', () {
        pollingService._batteryService._batteryLevel = 40;
        pollingService._batteryService._updateBatteryState();

        expect(pollingService.shouldFetchHighResAssets(), false);
      });

      test('should fetch high-res assets when battery > 50%', () {
        pollingService._batteryService._batteryLevel = 75;
        pollingService._batteryService._updateBatteryState();

        expect(pollingService.shouldFetchHighResAssets(), true);
      });
    });
  });
}
