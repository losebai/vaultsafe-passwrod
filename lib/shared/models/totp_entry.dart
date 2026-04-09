/// TOTP 账户模型
class TotpEntry {
  final String id;
  final String name;         // 显示名称（如 Google、GitHub）
  final String issuer;       // 发行者（如 Google、GitHub）
  final String account;      // 账户标识（如 user@example.com）
  final String secret;       // Base32 编码的密钥
  final int digits;          // 验证码位数（通常为6）
  final int period;          // 时间步长（秒，通常为30）
  final String algorithm;    // 算法（SHA1、SHA256、SHA512）
  final String groupId;      // 分组ID
  final DateTime createdAt;
  final DateTime updatedAt;

  const TotpEntry({
    required this.id,
    required this.name,
    this.issuer = '',
    required this.account,
    required this.secret,
    this.digits = 6,
    this.period = 30,
    this.algorithm = 'SHA1',
    this.groupId = 'default',
    required this.createdAt,
    required this.updatedAt,
  });

  TotpEntry copyWith({
    String? id,
    String? name,
    String? issuer,
    String? account,
    String? secret,
    int? digits,
    int? period,
    String? algorithm,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TotpEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      account: account ?? this.account,
      secret: secret ?? this.secret,
      digits: digits ?? this.digits,
      period: period ?? this.period,
      algorithm: algorithm ?? this.algorithm,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuer': issuer,
      'account': account,
      'secret': secret,
      'digits': digits,
      'period': period,
      'algorithm': algorithm,
      'groupId': groupId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TotpEntry.fromJson(Map<String, dynamic> json) {
    return TotpEntry(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      account: json['account'] as String,
      secret: json['secret'] as String,
      digits: json['digits'] as int? ?? 6,
      period: json['period'] as int? ?? 30,
      algorithm: json['algorithm'] as String? ?? 'SHA1',
      groupId: json['groupId'] as String? ?? 'default',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 从 otpauth:// URI 解析 TOTP 条目
  static TotpEntry? fromOtpAuthUri(String uri) {
    try {
      final parsed = Uri.parse(uri);
      if (parsed.scheme != 'otpauth' || parsed.host != 'totp') return null;

      final secret = parsed.queryParameters['secret'];
      if (secret == null || secret.isEmpty) return null;

      // 从路径中提取 issuer:account
      final path = Uri.decodeComponent(parsed.path.substring(1)); // 去掉前导 /
      String issuer = parsed.queryParameters['issuer'] ?? '';
      String account = path;

      // 格式可能是 "issuer:account" 或直接 "account"
      if (path.contains(':')) {
        final parts = path.split(':');
        if (issuer.isEmpty) issuer = parts[0].trim();
        account = parts.length > 1 ? parts.sublist(1).join(':').trim() : path;
      }

      final digits = int.tryParse(parsed.queryParameters['digits'] ?? '') ?? 6;
      final period = int.tryParse(parsed.queryParameters['period'] ?? '') ?? 30;
      final algorithm = parsed.queryParameters['algorithm'] ?? 'SHA1';

      final now = DateTime.now();
      return TotpEntry(
        id: 'totp_${now.millisecondsSinceEpoch}',
        name: account,
        issuer: issuer,
        account: account,
        secret: secret.toUpperCase(),
        digits: digits,
        period: period,
        algorithm: algorithm.toUpperCase(),
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      return null;
    }
  }

  /// 生成 otpauth:// URI
  String toOtpAuthUri() {
    final label = issuer.isNotEmpty ? '$issuer:$account' : account;
    return Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: '/${Uri.encodeComponent(label)}',
      queryParameters: {
        'secret': secret,
        if (issuer.isNotEmpty) 'issuer': issuer,
        'algorithm': algorithm,
        'digits': digits.toString(),
        'period': period.toString(),
      },
    ).toString();
  }
}
