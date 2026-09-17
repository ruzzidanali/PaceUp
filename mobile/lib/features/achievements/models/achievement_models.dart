class AchievementResponse {
  final String id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final String requirementType;
  final double requirementValue;
  final DateTime? unlockedAt;

  const AchievementResponse({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirementType,
    required this.requirementValue,
    required this.unlockedAt,
  });

  factory AchievementResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return AchievementResponse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      requirementType: json['requirementType'] as String,
      requirementValue:
          (json['requirementValue'] as num).toDouble(),
      unlockedAt: json['unlockedAt'] == null
          ? null
          : DateTime.parse(
              json['unlockedAt'] as String,
            ),
    );
  }

  bool get isUnlocked => unlockedAt != null;
}