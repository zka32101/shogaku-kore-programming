
## 최근 개선사항 (2026-09-08)

### DateTime 생성자 수정
- 모든 테스트 파일의 DateTime 생성자를 DateTime.utc() 형식으로 일관되게 수정
- 총 51개 인스턴스 수정: DateTime(YYYY, MM, DD) → DateTime.utc(YYYY, MM, DD)
- Dart null-safety 컴파일 요구사항을 충족하기 위해 const 컨텍스트에서 DateTime 객체 사용 정규화

수정된 파일:
- test/models/: challenge_test.dart, daily_login_reward_test.dart, leaderboards_rankings_test.dart, learning_analytics_test.dart, character_customization_test.dart, activities_minigames_test.dart, shop_store_test.dart, streaks_daily_rewards_test.dart, user_profile_test.dart
- test/providers/: leaderboard_provider_test.dart
- test/widgets/: extracted_widgets_test.dart

