import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show CoachingDashboard;

import '../../../config/theme.dart';
import '../../../providers/profile_provider.dart';

/// AI コーチング ダッシュボード画面
///
/// ユーザーの学習パターンを分析し、個別のコーチングアドバイスを表示します。
class AiCoachingDashboardScreen extends ConsumerWidget {
  const AiCoachingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    // Use anonymousId if available, otherwise use nickname as user identifier
    final userId = profile.anonymousId.isNotEmpty
        ? profile.anonymousId
        : profile.nickname;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI コーチング'),
        backgroundColor: kPrimaryColor,
        elevation: 0,
      ),
      body: CoachingDashboard(
        userId: userId,
        primaryColor: kPrimaryColor,
      ),
    );
  }
}
