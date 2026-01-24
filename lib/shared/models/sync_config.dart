/// 同步配置模型
class SyncConfig {
  final bool enabled;
  final String endpointUrl;
  final SyncAuthType authType;
  final String? token;
  final String? username;
  final String? password;
  final SyncInterval interval;
  final DateTime? lastSyncedAt;
  final String? lastSyncError;

  const SyncConfig({
    this.enabled = false,
    this.endpointUrl = '',
    this.authType = SyncAuthType.bearer,
    this.token,
    this.username,
    this.password,
    this.interval = SyncInterval.none,
    this.lastSyncedAt,
    this.lastSyncError,
  });

  SyncConfig copyWith({
    bool? enabled,
    String? endpointUrl,
    SyncAuthType? authType,
    String? token,
    String? username,
    String? password,
    SyncInterval? interval,
    DateTime? lastSyncedAt,
    String? lastSyncError,
  }) {
    return SyncConfig(
      enabled: enabled ?? this.enabled,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      authType: authType ?? this.authType,
      token: token ?? this.token,
      username: username ?? this.username,
      password: password ?? this.password,
      interval: interval ?? this.interval,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'endpointUrl': endpointUrl,
      'authType': authType.index,
      'token': token,
      'username': username,
      'password': password,
      'interval': interval.index,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'lastSyncError': lastSyncError,
    };
  }

  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      enabled: json['enabled'] ?? false,
      endpointUrl: json['endpointUrl'] ?? '',
      authType: SyncAuthType.values[json['authType'] ?? 0],
      token: json['token'],
      username: json['username'],
      password: json['password'],
      interval: SyncInterval.values[json['interval'] ?? 0],
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'])
          : null,
      lastSyncError: json['lastSyncError'],
    );
  }
}

enum SyncAuthType {
  bearer,
  basic,
  custom,
}

enum SyncInterval {
  none,
  every5Min,
  every15Min,
  hourly,
  daily,
}

extension SyncAuthTypeExtension on SyncAuthType {
  String get label {
    switch (this) {
      case SyncAuthType.bearer:
        return 'Bearer Token';
      case SyncAuthType.basic:
        return 'Basic Auth';
      case SyncAuthType.custom:
        return '自定义 Header';
    }
  }

  String get description {
    switch (this) {
      case SyncAuthType.bearer:
        return '使用 Bearer Token 认证';
      case SyncAuthType.basic:
        return '使用用户名和密码认证';
      case SyncAuthType.custom:
        return '自定义请求头认证';
    }
  }
}

extension SyncIntervalExtension on SyncInterval {
  String get label {
    switch (this) {
      case SyncInterval.none:
        return '手动同步';
      case SyncInterval.every5Min:
        return '每 5 分钟';
      case SyncInterval.every15Min:
        return '每 15 分钟';
      case SyncInterval.hourly:
        return '每小时';
      case SyncInterval.daily:
        return '每天';
    }
  }

  Duration get duration {
    switch (this) {
      case SyncInterval.none:
        return Duration.zero;
      case SyncInterval.every5Min:
        return const Duration(minutes: 5);
      case SyncInterval.every15Min:
        return const Duration(minutes: 15);
      case SyncInterval.hourly:
        return const Duration(hours: 1);
      case SyncInterval.daily:
        return const Duration(days: 1);
    }
  }
}
