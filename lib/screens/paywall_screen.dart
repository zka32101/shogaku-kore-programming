import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../providers/subscription_provider.dart';
import '../utils/constants.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  bool _isYearlySelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プレミアム版に登録'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.star, size: 60, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  '${AppConstants.appName}プレミアム',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '無制限でクイズを学習できます',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Features Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'プレミアムの特典',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  context,
                  icon: Icons.remove_circle,
                  title: '広告なし',
                  description: 'クイズ中の広告がなくなります',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  context,
                  icon: Icons.all_inclusive,
                  title: '無制限クイズ',
                  description: '毎日無制限にクイズができます',
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  context,
                  icon: Icons.psychology,
                  title: 'AI相談機能',
                  description: '分からない問題を質問できます',
                ),
              ],
            ),
          ),

          const Divider(),

          // Pricing Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '価格',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final offerings =
                        ref.watch(subscriptionProvider).availableOfferings;
                    final monthlyPackage = _findPackage(
                      offerings,
                      PackageType.monthly,
                    );
                    final yearlyPackage = _findPackage(
                      offerings,
                      PackageType.annual,
                    );
                    final monthlyPrice =
                        monthlyPackage?.storeProduct.priceString ?? '¥300';
                    final yearlyPrice =
                        yearlyPackage?.storeProduct.priceString ?? '¥2,400';

                    return Row(
                      children: [
                        Expanded(
                          child: _buildPlanCard(
                            context,
                            label: '月額プラン',
                            price: monthlyPrice,
                            caption: '毎月お支払い',
                            selected: !_isYearlySelected,
                            onTap: () =>
                                setState(() => _isYearlySelected = false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPlanCard(
                            context,
                            label: '年額プラン',
                            price: yearlyPrice,
                            caption: 'お得（2ヶ月分無料相当）',
                            selected: _isYearlySelected,
                            onTap: () =>
                                setState(() => _isYearlySelected = true),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'プレミアムに登録する',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleRestore,
                    child: const Text('以前の購入を復元'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  '利用規約に同意する必要があります',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Open terms
                      },
                      child: const Text('利用規約'),
                    ),
                    const Text('・'),
                    TextButton(
                      onPressed: () {
                        // Open privacy policy
                      },
                      child: const Text('プライバシーポリシー'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Package? _findPackage(List<Package>? offerings, PackageType type) {
    if (offerings == null) return null;
    for (final package in offerings) {
      if (package.packageType == type) return package;
    }
    return null;
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String label,
    required String price,
    required String caption,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? Colors.blue.shade50 : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);

    try {
      final subscription = ref.read(subscriptionProvider);
      final offerings = subscription.availableOfferings;

      if (offerings == null || offerings.isEmpty) {
        throw Exception('購読プランが利用できません');
      }

      final selectedType =
          _isYearlySelected ? PackageType.annual : PackageType.monthly;
      final selectedPackage =
          _findPackage(offerings, selectedType) ?? offerings.first;

      await ref
          .read(subscriptionProvider.notifier)
          .purchaseSubscription(selectedPackage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登録が完了しました！')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(subscriptionProvider.notifier)
          .restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('復元が完了しました！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('復元に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
