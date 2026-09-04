import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/services/optimized_http_client.dart';

void main() {
  group('OptimizedHttpClient', () {
    late OptimizedHttpClient httpClient;

    setUp(() {
      httpClient = OptimizedHttpClient();
    });

    group('Request Throttle Interval', () {
      test('low battery returns 5 second interval', () {
        httpClient.setBatteryLevelForTesting(15);
        // Verify by checking that polling interval is affected
        expect(
          httpClient.getPollingInterval(normalInterval: const Duration(seconds: 1)),
          const Duration(seconds: 5),
        );
      });

      test('medium battery returns 2 second interval', () {
        httpClient.setBatteryLevelForTesting(40);
        expect(
          httpClient.getPollingInterval(normalInterval: const Duration(seconds: 1)),
          const Duration(seconds: 2),
        );
      });

      test('normal battery returns 1 second interval', () {
        httpClient.setBatteryLevelForTesting(80);
        expect(
          httpClient.getPollingInterval(normalInterval: const Duration(seconds: 1)),
          const Duration(seconds: 1),
        );
      });
    });

    group('Polling Interval', () {
      test('low battery multiplies default interval by 5', () {
        httpClient.setBatteryLevelForTesting(10);

        final interval = httpClient.getPollingInterval(
          normalInterval: const Duration(seconds: 10),
        );
        expect(interval, const Duration(seconds: 50));
      });

      test('medium battery multiplies default interval by 2', () {
        httpClient.setBatteryLevelForTesting(35);

        final interval = httpClient.getPollingInterval(
          normalInterval: const Duration(seconds: 10),
        );
        expect(interval, const Duration(seconds: 20));
      });

      test('normal battery uses default interval', () {
        httpClient.setBatteryLevelForTesting(100);

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
        pollingService.setBatteryLevelForTesting(15);

        expect(pollingService.shouldPerformBackgroundSync(), false);
      });

      test('should perform background sync in normal battery mode', () {
        pollingService.setBatteryLevelForTesting(100);

        expect(pollingService.shouldPerformBackgroundSync(), true);
      });
    });

    group('High-Resolution Asset Decision', () {
      test('should not fetch high-res assets in low battery', () {
        pollingService.setBatteryLevelForTesting(15);

        expect(pollingService.shouldFetchHighResAssets(), false);
      });

      test('should not fetch high-res assets in medium battery', () {
        pollingService.setBatteryLevelForTesting(40);

        expect(pollingService.shouldFetchHighResAssets(), false);
      });

      test('should fetch high-res assets when battery > 50%', () {
        pollingService.setBatteryLevelForTesting(75);

        expect(pollingService.shouldFetchHighResAssets(), true);
      });
    });
  });
}
