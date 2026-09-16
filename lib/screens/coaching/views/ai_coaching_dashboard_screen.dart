import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// AI コーチング ダッシュボード画面（Phase 4: shared_core 側 API 未整備のため準備中）
class AiCoachingDashboardScreen extends StatelessWidget {
  const AiCoachingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI コーチング'),
        backgroundColor: kPrimaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '近日公開予定です',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
