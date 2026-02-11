import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';

/// Authentication service for master password and biometrics
class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  static AuthService? _instance;
  static bool _isInitialized = false;

  Uint8List? _masterKey;

  Uint8List? get masterKey => _masterKey;

  // 私有构造，防止外部直接 new
  AuthService._internal();

  /// Initialize the AuthService singleton
  static Future<AuthService> initialize() async {
    if (_isInitialized && _instance != null) {
      return _instance!;
    }

    // 创建单例实例
    _instance = AuthService._internal();

    // 执行所有异步安全初始化
    // 检查是否已设置主密码
    // 注意：这里不读取 master_hash，因为那是验证器的一部分
    // 实际的验证逻辑在 hasMasterPassword() 方法中

    _isInitialized = true;
    return _instance!;
  }

  /// Get the current AuthService instance
  static AuthService get instance {
    if (_instance == null) {
      throw StateError('AuthService must be initialized first. Call AuthService.initialize() first.');
    }
    return _instance!;
  }


  /// 检查用户是否已设置主密码
  Future<bool> hasMasterPassword() async {
    final salt = await _secureStorage.read(key: 'master_salt');
    final verifier = await _secureStorage.read(key: 'password_verifier');
    return salt != null && verifier != null;
  }

  /// Set up master password for the first time
  Future<void> setupMasterPassword(String password) async {
    final salt = EncryptionService.generateSalt();
    // 使用异步密钥派生，避免 UI 卡顿
    final key = await EncryptionService.deriveKeyAsync(password, salt);

    // 创建一个验证器来检查密码的有效性，而不存储实际密码。
    final verifier = EncryptionService.encrypt('vaultsafe_verify', key);

    await _secureStorage.write(
      key: 'master_salt',
      value: salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );

    await _secureStorage.write(
      key: 'password_verifier',
      value: jsonEncode(verifier.toJson()),
    );

    _masterKey = key;
  }

  /// Set up master password with biometric unlock support
  Future<void> setupMasterPasswordWithBiometric(String password, bool enableBiometric) async {
    await setupMasterPassword(password);

    // 如果启用了生物识别，存储加密的主密码副本用于指纹解锁
    if (enableBiometric) {
      await _storeEncryptedMasterPassword(password);
    }
  }

  /// Store encrypted master password for biometric unlock
  Future<void> _storeEncryptedMasterPassword(String password) async {
    // 使用当前 masterKey 加密主密码
    final encryptedPassword = EncryptionService.encrypt(password, _masterKey!);

    await _secureStorage.write(
      key: 'encrypted_master_password',
      value: jsonEncode(encryptedPassword.toJson()),
    );
  }

  /// Get decrypted master password for biometric unlock
  Future<String?> getDecryptedMasterPassword() async {
    try {
      final encryptedJson = await _secureStorage.read(key: 'encrypted_master_password');
      if (encryptedJson == null) return null;

      final encryptedData = jsonDecode(encryptedJson) as Map<String, dynamic>;
      final encrypted = EncryptedData.fromJson(encryptedData);

      // 使用当前的 masterKey 解密主密码
      return EncryptionService.decrypt(encrypted, _masterKey!);
    } catch (e) {
      return null;
    }
  }

  /// Update biometric setting and re-store encrypted password if needed
  Future<void> updateBiometricEnabled(bool enabled) async {
    if (!enabled) {
      // 禁用时删除存储的加密主密码
      await _secureStorage.delete(key: 'encrypted_master_password');
    }
    // 启用时会在下次主密码解锁时自动存储
  }

  /// Store encrypted master password for biometric unlock (public method for settings)
  Future<void> storeEncryptedMasterPassword(String password) async {
    if (_masterKey == null) {
      throw StateError('Master key not available. User must be unlocked first.');
    }
    await _storeEncryptedMasterPassword(password);
  }

  /// 校验主密码
  Future<bool> verifyMasterPassword(String password) async {
    try {
      // 读取盐
      final saltHex = await _secureStorage.read(key: 'master_salt');
      if (saltHex == null) return false;

      // 密钥
      final salt = Uint8List.fromList(
        List.generate(saltHex.length ~/ 2, (i) => int.parse(saltHex.substring(i * 2, i * 2 + 2), radix: 16)),
      );

      //  用密码 + salt 派生加密密钥（使用异步版本，避免 UI 卡顿）
      final key = await EncryptionService.deriveKeyAsync(password, salt);

      // 读取加密的验证器（verifier）
      final verifierJson = await _secureStorage.read(key: 'password_verifier');
      if (verifierJson == null) return false;

      final verifierData = jsonDecode(verifierJson) as Map<String, dynamic>;
      final decrypted = EncryptionService.decrypt(
        EncryptedData.fromJson(verifierData),
        key,
      );

      if (decrypted == 'vaultsafe_verify') {
        _masterKey = key;
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Change master password
  Future<bool> changeMasterPassword(String oldPassword, String newPassword) async {
    final isValid = await verifyMasterPassword(oldPassword);
    if (!isValid) return false;

    await setupMasterPassword(newPassword);
    return true;
  }

  /// 检查是否可用生物识别认证
  Future<bool> isBiometricAvailable() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return isAvailable && isDeviceSupported;
  }

  /// 使用生物识别技术进行身份验证
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access VaultSafe',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  /// Lock the vault
  void lock() {
    _masterKey = null;
  }

  /// Check if vault is unlocked
  bool get isUnlocked => _masterKey != null;
}
