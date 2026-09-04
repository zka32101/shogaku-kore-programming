/// Avatar model for user profile customization
class Avatar {
  final String id;
  final String name;
  final String emoji;
  final bool isDefault;
  final int price; // 0 for default avatars, > 0 for shop items

  const Avatar({
    required this.id,
    required this.name,
    required this.emoji,
    this.isDefault = false,
    this.price = 0,
  });

  /// Convert Avatar to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'isDefault': isDefault,
    'price': price,
  };

  /// Create Avatar from JSON
  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    isDefault: json['isDefault'] as bool? ?? false,
    price: json['price'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Avatar &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
