import 'package:vaultsafe/core/sync/sync_auth_type.dart';
import 'package:vaultsafe/core/sync/sync_interval.dart';

/// Sync configuration model
class SyncConfig {
  final bool enabled;
  final String endpointUrl;
  final SyncAuthType authType;
  final String? token;
  final String? username;
  final String? password;
  final Map<String, String>? customHeaders;
  final SyncInterval interval;
  final DateTime? lastSyncedAt;

  SyncConfig({
    required this.enabled,
    required this.endpointUrl,
    required this.authType,
    this.token,
    this.username,
    this.password,
    this.customHeaders,
    required this.interval,
    this.lastSyncedAt,
  });

  SyncConfig copyWith({
    bool? enabled,
    String? endpointUrl,
    SyncAuthType? authType,
    String? token,
    String? username,
    String? password,
    Map<String, String>? customHeaders,
    SyncInterval? interval,
    DateTime? lastSyncedAt,
  }) {
    return SyncConfig(
      enabled: enabled ?? this.enabled,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      authType: authType ?? this.authType,
      token: token ?? this.token,
      username: username ?? this.username,
      password: password ?? this.password,
      customHeaders: customHeaders ?? this.customHeaders,
      interval: interval ?? this.interval,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'endpointUrl': endpointUrl,
      'authType': authType.name,
      'token': token,
      'username': username,
      'password': password,
      'customHeaders': customHeaders,
      'interval': interval.name,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      enabled: json['enabled'] as bool,
      endpointUrl: json['endpointUrl'] as String,
      authType: SyncAuthType.values.firstWhere(
        (e) => e.name == json['authType'],
        orElse: () => SyncAuthType.bearer,
      ),
      token: json['token'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      customHeaders: json['customHeaders'] as Map<String, String>?,
      interval: SyncInterval.values.firstWhere(
        (e) => e.name == json['interval'],
        orElse: () => SyncInterval.none,
      ),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
    );
  }

  static SyncConfig get defaultConfig => SyncConfig(
        enabled: false,
        endpointUrl: '',
        authType: SyncAuthType.bearer,
        interval: SyncInterval.none,
      );
}
