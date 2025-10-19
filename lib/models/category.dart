class Category {
  final String id;
  final String userId;
  final String name;
  final String? nameNepali;
  final String? icon;
  final String color;
  final String type; // 'expense' or 'income'
  final bool isDefault;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    this.nameNepali,
    this.icon,
    this.color = '#6366f1',
    this.type = 'expense',
    this.isDefault = false,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      nameNepali: json['name_nepali'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String? ?? '#6366f1',
      type: json['type'] as String? ?? 'expense',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'name_nepali': nameNepali,
      'icon': icon,
      'color': color,
      'type': type,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? nameNepali,
    String? icon,
    String? color,
    String? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      nameNepali: nameNepali ?? this.nameNepali,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get display name based on language preference
  String getDisplayName(String language) {
    if (language == 'ne' && nameNepali != null && nameNepali!.isNotEmpty) {
      return nameNepali!;
    }
    return name;
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, nameNepali: $nameNepali, icon: $icon, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.nameNepali == nameNepali &&
        other.icon == icon &&
        other.color == color &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        nameNepali.hashCode ^
        icon.hashCode ^
        color.hashCode ^
        isDefault.hashCode;
  }
}
