import 'package:flutter/foundation.dart';

/// 認定証データモデル
class Certificate {
  final String id;
  final String childName;
  final int stageNumber;
  final String stageName;
  final String level; // '初級', '中級', '上級'
  final int stars; // 1-3
  final DateTime completedAt;
  final String? filePath; // デバイス保存パス（生成後に設定）

  Certificate({
    required this.id,
    required this.childName,
    required this.stageNumber,
    required this.stageName,
    required this.level,
    required this.stars,
    required this.completedAt,
    this.filePath,
  });

  /// JSON シリアライザ（SharedPreferences 保存用）
  Map<String, dynamic> toJson() => {
    'id': id,
    'childName': childName,
    'stageNumber': stageNumber,
    'stageName': stageName,
    'level': level,
    'stars': stars,
    'completedAt': completedAt.toIso8601String(),
    'filePath': filePath,
  };

  /// JSON デシリアライザ
  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
    id: json['id'] as String,
    childName: json['childName'] as String,
    stageNumber: json['stageNumber'] as int,
    stageName: json['stageName'] as String,
    level: json['level'] as String,
    stars: json['stars'] as int,
    completedAt: DateTime.parse(json['completedAt'] as String),
    filePath: json['filePath'] as String?,
  );

  /// コピーウィズ（filePath 更新用）
  Certificate copyWith({
    String? id,
    String? childName,
    int? stageNumber,
    String? stageName,
    String? level,
    int? stars,
    DateTime? completedAt,
    String? filePath,
  }) => Certificate(
    id: id ?? this.id,
    childName: childName ?? this.childName,
    stageNumber: stageNumber ?? this.stageNumber,
    stageName: stageName ?? this.stageName,
    level: level ?? this.level,
    stars: stars ?? this.stars,
    completedAt: completedAt ?? this.completedAt,
    filePath: filePath ?? this.filePath,
  );

  @override
  String toString() =>
      'Certificate(id=$id, childName=$childName, stageNumber=$stageNumber, '
      'stageName=$stageName, level=$level, stars=$stars, '
      'completedAt=$completedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Certificate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          childName == other.childName &&
          stageNumber == other.stageNumber &&
          level == other.level &&
          stars == other.stars;

  @override
  int get hashCode =>
      id.hashCode ^
      childName.hashCode ^
      stageNumber.hashCode ^
      level.hashCode ^
      stars.hashCode;
}
