import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' show requireParentalGate;

import '../services/study_reminder_service.dart';

/// 「学習のおしらせ」（学習した後に届く、おすすめ時刻のお知らせ）の ON/OFF。
/// ON にする操作は保護者ゲートを通す。上の「学習リマインダー」が OFF の間は届かない。
class ReminderSwitchTile extends StatefulWidget {
  const ReminderSwitchTile({super.key});

  @override
  State<ReminderSwitchTile> createState() => _ReminderSwitchTileState();
}

class _ReminderSwitchTileState extends State<ReminderSwitchTile> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    StudyReminderService.instance.isEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      final passed = await requireParentalGate(context);
      if (!passed || !mounted) return;
    }
    await StudyReminderService.instance.setEnabled(value);
    if (mounted) setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: const Text('📣', style: TextStyle(fontSize: 22)),
      title: const Text('学習のおしらせ'),
      subtitle: const Text('いつも学習している時間に、1日1回までお知らせします（夜9時〜朝7時は送りません）'),
      value: _enabled ?? true,
      onChanged: _enabled == null ? null : _toggle,
    );
  }
}
