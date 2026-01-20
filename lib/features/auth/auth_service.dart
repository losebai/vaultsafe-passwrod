import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';

/// Authentication service for master password and biometrics
class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Uint8List? _masterKey;
  Uint8List? _salt;

  Uint8List? get masterKey => _masterKey;

  /// Check if user has set up master password
  Future<bool> hasMasterPassword() async {
    final salt = await _secureStorage.read(key: 'master_salt');
    final verifier = await _secureStorage.read(key: 'password_verifier');
    return salt != null && verifier != null;
  }

  /// Set up master password for the first time
  Future<void> setupMasterPassword(String password) async {
    final salt = EncryptionService.generateSalt();
    final key = EncryptionService.deriveKey(password, salt);

    // Create a verifier to check password validity without storing the actual password
    final verifier = EncryptionService.encrypt('vaultsafe_verify', key);

    await _secureStorage.write(
      key: 'master_salt',
      value: salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );

    await _secureStorage.write(
      key: 'password_verifier',
      value: verifier.toJson().toString(),
    );

    _masterKey = key;
    _salt = salt;
  }

  /// Verify master password and unlock the vault
  Future<bool> verifyMasterPassword(String password) async {
    try {
      final saltHex = await _secureStorage.read(key: 'master_salt');
      if (saltHex == null) return false;

      final salt = Uint8List.fromList(
        List.generate(saltHex.length ~/ 2, (i) => int.parse(saltHex.substring(i * 2, i * 2 + 2), radix: 16)),
      );

      final key = EncryptionService.deriveKey(password, salt);

      // Verify by trying to decrypt the verifier
      final verifierJson = await _secureStorage.read(key: 'password_verifier');
      if (verifierJson == null) return false;

      // Parse verifier (simplified)
      final decrypted = EncryptionService.decrypt(
        EncryptedData.fromJson(
          Map<String, dynamic>.from(
            verifierJson.replaceAll('{', '').replaceAll('}', '').split(',').map((e) {
              final parts = e.split(':');
              return MapEntry(parts[0].trim().replaceAll("'", ''), parts[1].trim().replaceAll("'", ''));
            }),
          ),
        ),
        key,
      );

      if (decrypted == 'vaultsafe_verify') {
        _masterKey = key;
        _salt = salt;
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

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return isAvailable && isDeviceSupported;
  }

  /// Authenticate with biometrics
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
