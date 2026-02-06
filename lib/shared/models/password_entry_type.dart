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

  /// 证书/密钥 (PEM格式)
  certificate('certificate', '证书', Icons.verified_user),

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

  /// 获取网站/URL字段的标签
  String get websiteLabel {
    switch (this) {
      case PasswordEntryType.website:
        return '网站';
      case PasswordEntryType.application:
        return '应用地址（可选）';
      case PasswordEntryType.server:
        return '服务器地址';
      case PasswordEntryType.database:
        return '数据库地址';
      case PasswordEntryType.wifi:
        return 'SSID（可选）';
      case PasswordEntryType.ssh:
        return '主机地址';
      case PasswordEntryType.apiKey:
        return 'API端点（可选）';
      case PasswordEntryType.certificate:
        return '颁发者（可选）';
      default:
        return '地址（可选）';
    }
  }

  /// 获取用户名字段的标签
  String get usernameLabel {
    switch (this) {
      case PasswordEntryType.website:
        return '用户名 / 邮箱';
      case PasswordEntryType.wifi:
        return 'WiFi名称';
      case PasswordEntryType.bankCard:
        return '卡号';
      case PasswordEntryType.email:
        return '邮箱地址';
      case PasswordEntryType.database:
        return '数据库名';
      case PasswordEntryType.ssh:
        return 'SSH用户名';
      case PasswordEntryType.apiKey:
        return 'API标识';
      case PasswordEntryType.certificate:
        return '证书名称';
      default:
        return '用户名';
    }
  }

  /// 获取密码/密钥字段的标签
  String get passwordLabel {
    switch (this) {
      case PasswordEntryType.wifi:
        return 'WiFi密码';
      case PasswordEntryType.bankCard:
        return 'CVV/CVC';
      case PasswordEntryType.ssh:
        return 'SSH密钥';
      case PasswordEntryType.apiKey:
        return 'API密钥';
      case PasswordEntryType.certificate:
        return '证书内容（PEM格式）';
      default:
        return '密码';
    }
  }

  /// 网站字段是否必填
  bool get isWebsiteRequired {
    switch (this) {
      case PasswordEntryType.website:
      case PasswordEntryType.server:
      case PasswordEntryType.database:
        return true;
      default:
        return false;
    }
  }

  /// 是否需要长文本输入（用于PEM证书、API密钥等）
  bool get requiresLongTextInput {
    return this == PasswordEntryType.certificate ||
           this == PasswordEntryType.apiKey ||
           this == PasswordEntryType.ssh;
  }

  /// 是否需要多行密码输入
  bool get isPasswordMultiline {
    return this == PasswordEntryType.certificate;
  }
}
