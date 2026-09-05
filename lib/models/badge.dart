/// Achievement badge model
class Badge {
  final String icon;
  final String name;
  final String description;
  final String category;
  final bool isUnlocked;

  /// Progress towards unlocking badge (0〜progressTarget)
  final int? progressCurrent;
  final int? progressTarget;

  const Badge({
    required this.icon,
    required this.name,
    required this.description,
    required this.category,
    required this.isUnlocked,
    this.progressCurrent,
    this.progressTarget,
  });

  /// Returns progress ratio for badge unlock (0.0 to 1.0)
  double? get progressRatio {
    if (progressCurrent == null || progressTarget == null || progressTarget == 0) return null;
    return (progressCurrent! / progressTarget!).clamp(0.0, 1.0);
  }
}
