import 'package:vaultsafe/shared/models/password_entry_type.dart';

/// 密码分组模型
class PasswordGroup {
  final String id;
  final String name;
  final String? parentId;  // 支持层级结构（暂时未使用）
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

  /// 获取默认分组的图标
  static String getDefaultIcon(int order) {
    const icons = [
      'folder',
      'work',
      'star',
      'card',
      'favorite',
      'cloud',
      'shield',
      'home',
      'lock',
    ];
    return icons[order % icons.length];
  }

  /// 获取默认分组的颜色
  static String getDefaultColor(int order) {
    const colors = [
      '#FF6B6F0', // 蓝色
      '#4CAF50', // 橙色
      '#FFB71C1', // 绿色
      '#2196F3', // 黄色
      '#9C27B0', // 棕色
      '#E91E63', // 橙色
      '#673AB7', // 紫色
      '#607D8B0', // 蓝色
    ];
    return colors[order % colors.length];
  }

  /// 创建默认分组
  static PasswordGroup createDefault(String id, String name, int order) {
    final now = DateTime.now();
    return PasswordGroup(
      id: id,
      name: name,
      order: order,
      icon: getDefaultIcon(order),
      color: getDefaultColor(order),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 生成唯一ID
  static String generateId() {
    return 'group_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}