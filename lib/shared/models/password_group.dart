/// Password group model
class PasswordGroup {
  final String id;
  final String name;
  final String? parentId;
  final int order;
  final String? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  PasswordGroup({
    required this.id,
    required this.name,
    this.parentId,
    required this.order,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  PasswordGroup copyWith({
    String? id,
    String? name,
    String? parentId,
    int? order,
    String? icon,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      order: order ?? this.order,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'order': order,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PasswordGroup.fromJson(Map<String, dynamic> json) {
    return PasswordGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      order: json['order'] as int,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
