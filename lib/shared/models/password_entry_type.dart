import 'package:flutter/material.dart';

/// 密码条目类型枚举
enum PasswordEntryType {
  /// 网站密码
  website('website', '网站', Icons.language),

  /// 应用程序密码
  application('application', '应用', Icons.apps),

  /// WiFi 密码
  wifi('wifi', 'WiFi', Icons.wifi),

  /// 银行卡
  bankCard('bank_card', '银行卡', Icons.credit_card),

  /// 邮箱
  email('email', '邮箱', Icons.email),

  /// 数据库
  database('database', '数据库', Icons.storage),

  /// 服务器
  server('server', '服务器', Icons.dns),

  /// SSH 密钥
  ssh('ssh', 'SSH', Icons.terminal),

  /// API 密钥
  apiKey('api_key', 'API', Icons.key),

  /// 其他
  other('other', '其他', Icons.more_horiz);

  final String value;
  final String label;
  final IconData icon;

  const PasswordEntryType(this.value, this.label, this.icon);

  /// 从字符串值获取类型
  static PasswordEntryType fromValue(String value) {
    return PasswordEntryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PasswordEntryType.other,
    );
  }
}
