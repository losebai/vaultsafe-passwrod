import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaultsafe/core/sync/sync_config.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
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

        return SyncData(
          deviceId: response.data['device_id'] as String,
          timestamp: response.data['timestamp'] as int,
          encryptedData: response.data['encrypted_data'] as String,
          version: response.data['version'] as String,
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
        final credentials = base64Encode(
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
