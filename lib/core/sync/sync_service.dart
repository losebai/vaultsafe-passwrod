import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaultsafe/core/sync/sync_auth_type.dart';
import 'package:vaultsafe/core/sync/sync_config.dart';
import 'package:uuid/uuid.dart';

/// Sync service for encrypted data synchronization
class SyncService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  SyncConfig? _config;

  SyncConfig? get config => _config;

  /// Initialize sync service with configuration
  Future<void> init(SyncConfig config) async {
    _config = config;
  }

  /// Upload encrypted data to sync endpoint
  Future<bool> uploadData(String encryptedData) async {
    if (_config == null || !_config!.enabled) {
      throw Exception('Sync is not enabled');
    }

    try {
      final response = await _dio.post(
        _config!.endpointUrl,
        data: {
          'device_id': await _getDeviceId(),
          'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'encrypted_data': encryptedData,
          'version': '1.0',
        },
        options: Options(
          headers: await _buildHeaders(),
          contentType: Headers.jsonContentType,
        ),
      );

      final success = response.statusCode == 200 || response.statusCode == 201;

      if (success) {
        _updateLastSyncTime();
      }

      return success;
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Download encrypted data from sync endpoint
  Future<SyncData?> downloadData() async {
    if (_config == null || !_config!.enabled) {
      throw Exception('Sync is not enabled');
    }

    try {
      final response = await _dio.get(
        _config!.endpointUrl,
        options: Options(
          headers: await _buildHeaders(),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        _updateLastSyncTime();

        // 确保 response.data 是 Map 类型
        if (response.data is! Map) {
          throw Exception('服务器返回数据格式错误：期望 JSON 对象，实际收到 ${response.data.runtimeType}');
        }

        final data = response.data as Map;

        // 将整个响应转换为 JSON 字符串（包含完整的备份数据结构）
        final responseJson = jsonEncode(data);

        // 安全获取元数据字段
        final dataMap = data['data'] is Map ? data['data'] as Map : null;
        final nonce = dataMap?['nonce'];
        final exportedAt = data['exportedAt'];
        final version = data['version'];

        // 验证必需字段
        if (nonce == null || version == null || exportedAt == null) {
          throw Exception('服务器返回数据格式不完整，缺少必需字段');
        }

        // 验证字段类型
        if (nonce is! String || version is! String || exportedAt is! String) {
          throw Exception('服务器返回数据类型错误：nonce/version/exportedAt 必须是字符串');
        }

        return SyncData(
          deviceId: nonce,
          timestamp: DateTime.parse(exportedAt).millisecondsSinceEpoch ~/ 1000,
          encryptedData: responseJson, // 存储完整的 JSON 响应
          version: version,
        );
      }

      return null;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  /// Build HTTP headers based on auth type
  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_config == null) return headers;

    switch (_config!.authType) {
      case SyncAuthType.bearer:
        final token = await _getDecryptedToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
        break;
      case SyncAuthType.basic:
        final username = _config!.username ?? '';
        final password = await _getDecryptedPassword();
        final credentials = base64.encode(
          utf8.encode('$username:$password'),
        );
        headers['Authorization'] = 'Basic $credentials';
        break;
      case SyncAuthType.custom:
        if (_config!.customHeaders != null) {
          headers.addAll(_config!.customHeaders!);
        }
        break;
    }

    return headers;
  }

  Future<String> _getDeviceId() async {
    String? deviceId = await _secureStorage.read(key: 'device_id');
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _secureStorage.write(key: 'device_id', value: deviceId);
    }
    return deviceId;
  }

  Future<String?> _getDecryptedToken() async {
    // Token should be stored encrypted and decrypted here
    // For now, return from config
    return _config?.token;
  }

  Future<String?> _getDecryptedPassword() async {
    // Password should be stored encrypted and decrypted here
    return _config?.password;
  }

  void _updateLastSyncTime() {
    _config = _config?.copyWith(lastSyncedAt: DateTime.now());
  }

  /// Test sync connection
  Future<bool> testConnection() async {
    try {
      await downloadData();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Sync data model
class SyncData {
  final String deviceId;
  final int timestamp;
  final String encryptedData;
  final String version;

  SyncData({
    required this.deviceId,
    required this.timestamp,
    required this.encryptedData,
    required this.version,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}
