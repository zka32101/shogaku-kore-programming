import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/revenue_cat_service.dart';

// 購読状態を表すモデル
class SubscriptionState {
  final bool isSubscribed;
  final List<Package>? availableOfferings;
  final DateTime? expirationDate;
  final bool isLoading;
  final String? errorMessage;

  const SubscriptionState({
    required this.isSubscribed,
    this.availableOfferings,
    this.expirationDate,
    this.isLoading = false,
    this.errorMessage,
  });

  SubscriptionState copyWith({
    bool? isSubscribed,
    List<Package>? availableOfferings,
    DateTime? expirationDate,
    bool? isLoading,
    String? errorMessage,
  }) =>
      SubscriptionState(
        isSubscribed: isSubscribed ?? this.isSubscribed,
        availableOfferings: availableOfferings ?? this.availableOfferings,
        expirationDate: expirationDate ?? this.expirationDate,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// 購読状態管理 NotifierProvider
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final RevenueCatService _revenueCatService = RevenueCatService();

  SubscriptionNotifier() : super(const SubscriptionState(isSubscribed: false));

  /// 購読状態を更新
  Future<void> refreshSubscriptionStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final isSubscribed = await _revenueCatService.isSubscribed();
      final offerings = await _revenueCatService.getOfferings();
      final expirationDate =
          await _revenueCatService.getSubscriptionExpirationDate();

      state = state.copyWith(
        isSubscribed: isSubscribed,
        availableOfferings: offerings,
        expirationDate: expirationDate,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh subscription: $e',
      );
    }
  }

  /// サブスク購入
  Future<bool> purchaseSubscription(Package package) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await _revenueCatService.purchaseSubscription(
        package: package,
      );
      if (success) {
        await refreshSubscriptionStatus();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Purchase failed',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Purchase error: $e',
      );
      return false;
    }
  }

  /// 購入を復元
  Future<bool> restorePurchases() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await _revenueCatService.restorePurchases();
      if (success) {
        await refreshSubscriptionStatus();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Restore failed',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Restore error: $e',
      );
      return false;
    }
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  (ref) => SubscriptionNotifier(),
);

// 購読ステータスストリーム（リアルタイム更新）
final subscriptionStatusStreamProvider = StreamProvider<bool>((ref) {
  return RevenueCatService().subscriptionStatusStream;
});
