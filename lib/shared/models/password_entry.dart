import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/shared/models/password_entry_type.dart';

/// Password entry model
class PasswordEntry {
  final String id;
  final String title;
  final String website;
  final String username;
  final EncryptedData encryptedPassword;
  final String? notes;
  final String groupId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String>? customFields;
  final PasswordEntryType type; // 密码类型

  PasswordEntry({
    required this.id,
    required this.title,
    required this.website,
    required this.username,
    required this.encryptedPassword,
    this.notes,
    required this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.customFields,
    this.type = PasswordEntryType.website, // 默认为网站类型
  });

  PasswordEntry copyWith({
    String? id,
    String? title,
    String? website,
    String? username,
    EncryptedData? encryptedPassword,
    String? notes,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? customFields,
    PasswordEntryType? type,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      website: website ?? this.website,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      notes: notes ?? this.notes,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customFields: customFields ?? this.customFields,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'website': website,
      'username': username,
      'encryptedPassword': encryptedPassword.toJson(),
      'notes': notes,
      'groupId': groupId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'customFields': customFields,
      'type': type.value, // 添加类型字段
    };
  }

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      website: json['website'] as String,
      username: json['username'] as String,
      encryptedPassword: EncryptedData.fromJson(json['encryptedPassword']),
      notes: json['notes'] as String?,
      groupId: json['groupId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      customFields: json['customFields'] as Map<String, String>?,
      type: json['type'] != null
          ? PasswordEntryType.fromValue(json['type'] as String)
          : PasswordEntryType.website, // 默认为网站类型
    );
  }
}
