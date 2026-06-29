class UserWork {
  final String id;
  final String challengeId;
  final String challengeTitle;
  final String blockCode;
  final String resultImage; // Base64 or file path
  final DateTime createdAt;
  final String difficulty;
  final bool isStarred;

  const UserWork({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.blockCode,
    required this.resultImage,
    required this.createdAt,
    required this.difficulty,
    this.isStarred = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'blockCode': blockCode,
      'resultImage': resultImage,
      'createdAt': createdAt.toIso8601String(),
      'difficulty': difficulty,
      'isStarred': isStarred,
    };
  }

  factory UserWork.fromMap(Map<String, dynamic> map) {
    return UserWork(
      id: map['id'] ?? '',
      challengeId: map['challengeId'] ?? '',
      challengeTitle: map['challengeTitle'] ?? '',
      blockCode: map['blockCode'] ?? '',
      resultImage: map['resultImage'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      difficulty: map['difficulty'] ?? '',
      isStarred: map['isStarred'] ?? false,
    );
  }
}
