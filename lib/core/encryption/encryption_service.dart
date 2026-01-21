import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';

/// Encryption service using PBKDF2 + AES-256-GCM
/// All encryption happens locally on the device
class EncryptionService {
  static const int _keySize = 32; // 256 bits
  static const int _nonceSize = 12; // 96 bits for GCM
  static const int _iterations = 100000;
  static const int _saltSize = 16;

  /// Derive master key from master password using PBKDF2-HMAC-SHA256
  static Uint8List deriveKey(String password, Uint8List salt) {
    final mac = HMac(SHA256Digest(), 64);
    final pkcs = PBKDF2KeyDerivator(mac);

    final params = Pbkdf2Parameters(
      salt,
      _iterations,
      _keySize,
    );

    pkcs.init(params);

    final key = pkcs.process(Uint8List.fromList(utf8.encode(password)));
    return key as Uint8List;
  }

  /// Generate a random salt for key derivation
  static Uint8List generateSalt() {
    final random = FortunaRandom();
    random.seed(KeyParameter(_generateRandomSeed()));

    final salt = random.nextBytes(_saltSize);
    return salt as Uint8List;
  }

  /// Generate random nonce for AES-GCM
  static Uint8List generateNonce() {
    final random = FortunaRandom();
    random.seed(KeyParameter(_generateRandomSeed()));

    final nonce = random.nextBytes(_nonceSize);
    return nonce as Uint8List;
  }

  static Uint8List _generateRandomSeed() {
    final seed = List<int>.generate(32, (i) => DateTime.now().microsecondsSinceEpoch % 256);
    return Uint8List.fromList(seed);
  }

  /// Encrypt data using AES-256-GCM
  static EncryptedData encrypt(String plaintext, Uint8List key) {
    final nonce = generateNonce();
    final data = utf8.encode(plaintext);

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0));

    cipher.init(true, params);

    final ciphertext = cipher.process(Uint8List.fromList(data));

    // Extract tag (last 16 bytes)
    final tagStart = ciphertext.length - 16;
    final tag = ciphertext.sublist(tagStart);
    final actualCiphertext = ciphertext.sublist(0, tagStart);

    return EncryptedData(
      nonce: base64.encode(nonce),
      ciphertext: base64.encode(actualCiphertext),
      tag: base64.encode(tag),
    );
  }

  /// Decrypt data using AES-256-GCM
  static String decrypt(EncryptedData encrypted, Uint8List key) {
    final nonce = base64.decode(encrypted.nonce);
    final ciphertext = base64.decode(encrypted.ciphertext);
    final tag = base64.decode(encrypted.tag);

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0));

    cipher.init(false, params);

    final combined = Uint8List(ciphertext.length + tag.length)
      ..setAll(0, ciphertext)
      ..setAll(ciphertext.length, tag);

    final plaintext = cipher.process(combined);
    return utf8.decode(plaintext);
  }

  /// Hash password for verification (using SHA-256)
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

/// Model for encrypted data
class EncryptedData {
  final String nonce;
  final String ciphertext;
  final String tag;

  EncryptedData({
    required this.nonce,
    required this.ciphertext,
    required this.tag,
  });

  Map<String, dynamic> toJson() {
    return {
      'nonce': nonce,
      'ciphertext': ciphertext,
      'tag': tag,
    };
  }

  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      nonce: json['nonce'] as String,
      ciphertext: json['ciphertext'] as String,
      tag: json['tag'] as String,
    );
  }
}
