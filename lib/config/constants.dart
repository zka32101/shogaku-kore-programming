class AppConstants {
  static const String appName = '小学コレ！プログラミング';
  static const String appSubtitle = 'コード探険';
  static const int freeStageLimit = 10;
  static const int totalStages = 60;

  // Python言語について
  static const String pythonDescription = 'Python（パイソン）は、世界中のプロが使う人気No.1のことば！';
  static const String pythonFeatures = '''
🐍 Pythonってこんなことば！
• 英語みたいに読みやすい
• はじめての人にやさしい
• 世界中のプロが使ってる
• ゲームもAIもアプリも作れる

🚀 Pythonでできること：
• 🎮 ゲームを作る
• 🤖 AI（人工知能）を作る
• 📱 スマホアプリを作る
• 🎨 絵やアニメをかく
• 🔢 計算をいっしゅんで
• ⛏️ マイクラを自動でそうさ
  ''';

  // プログラミングでできることの説明
  static const String whatCanYouDoWithProgramming = '''
🎮 キミの好きなゲームも、ぜんぶプログラミングでできてるよ！

プログラミングを覚えると、こんなことができるんだ：

🎮 ゲームを作る
マリオやポケモンみたいなゲームも、キミが作れる！

🤖 ロボットやAIを動かす
おしゃべりするAIや、うごくロボットも作れるよ。

📱 スマホアプリを作る
みんなが毎日つかうアプリも、キミの作品にできる！

🎨 絵やアニメをかく
コンピューターで、うごく絵やCGも作れるんだ。

🌍 世界とつながる
キミの作ったものを、世界中の人に見てもらえる！

🌟 なりたいものになろう！
プログラミングは「やってみたい！」をホンモノにする、まほうの力だよ。
  ''';

  // ナビゲーション
  static const int navHome = 0;
  static const int navLearn = 1;
  static const int navAchievement = 2;
  static const int navSettings = 3;
}

class StageLevel {
  static const String beginner = '初級';
  static const String intermediate = '中級';
  static const String advanced = '上級';
}

class ChallengeType {
  static const String visual = 'visual';  // ブロックプログラミング
  static const String quiz = 'quiz';      // Pythonクイズ
}
