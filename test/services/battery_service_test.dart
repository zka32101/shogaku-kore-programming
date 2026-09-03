import 'package:flutter_test/flutter_test.dart';
import 'package:shogaku_kore_programming/services/battery_service.dart';

void main() {
  group('BatteryService', () {
    late BatteryService batteryService;

    setUp(() {
      batteryService = BatteryService();
    });

    test('singleton instance returns same object', () {
      final service1 = BatteryService();
      final service2 = BatteryService();
      expect(identical(service1, service2), true);
    });

    group('Animation Duration Multiplier', () {
      test('low battery (< 20%) returns 0.5x multiplier', () {
        // Simulate low battery condition
        batteryService.setBatteryLevelForTesting(19);
        expect(batteryService.animationDurationMultiplier, 0.5);
      });

      test('medium battery (20-50%) returns 0.75x multiplier', () {
        batteryService.setBatteryLevelForTesting(35);
        expect(batteryService.animationDurationMultiplier, 0.75);
      });

      test('normal battery (> 50%) returns 1.0x multiplier', () {
        batteryService.setBatteryLevelForTesting(100);
        expect(batteryService.animationDurationMultiplier, 1.0);
      });
    });

    group('Animation Frame Rate', () {
      test('low battery returns 24 fps', () {
        batteryService.setBatteryLevelForTesting(15);
        expect(batteryService.animationFrameRate, 24);
      });

      test('medium battery returns 30 fps', () {
        batteryService.setBatteryLevelForTesting(30);
        expect(batteryService.animationFrameRate, 30);
      });

      test('normal battery returns 60 fps', () {
        batteryService.setBatteryLevelForTesting(75);
        expect(batteryService.animationFrameRate, 60);
      });
    });

    group('Battery State Flags', () {
      test('isLowBattery is true when level < 20%', () {
        batteryService.setBatteryLevelForTesting(10);
        expect(batteryService.isLowBattery, true);
        expect(batteryService.isMediumBattery, false);
      });

      test('isMediumBattery is true when level 20-50%', () {
        batteryService.setBatteryLevelForTesting(40);
        expect(batteryService.isLowBattery, false);
        expect(batteryService.isMediumBattery, true);
      });

      test('both flags are false when battery is normal (> 50%)', () {
        batteryService.setBatteryLevelForTesting(85);
        expect(batteryService.isLowBattery, false);
        expect(batteryService.isMediumBattery, false);
      });
    });
  });
}
