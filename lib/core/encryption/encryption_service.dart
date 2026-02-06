import 'dart:typed_data';
import 'dart:convert';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Isolate 中执行密钥派生的参数
class _DeriveKeyParams {
  final String password;
  final Uint8List salt;
  final int iterations;
  final int keySize;

  _DeriveKeyParams({
    required this.password,
    required this.salt,
    required this.iterations,
    required this.keySize,
  });
}

/// Isolate 消息包装器
class _IsolateMessage {
  final _DeriveKeyParams params;
  final SendPort sendPort;

  _IsolateMessage({
    required this.params,
    required this.sendPort,
  });
}

/// 在 Isolate 中执行的密钥派生函数
Uint8List _deriveKeyInIsolate(_DeriveKeyParams params) {
  final mac = HMac(SHA256Digest(), 64);
  final pkcs = PBKDF2KeyDerivator(mac);

  final pkdf2Params = Pbkdf2Parameters(
    params.salt,
    params.iterations,
    params.keySize,
  );

  pkcs.init(pkdf2Params);
  return pkcs.process(Uint8List.fromList(utf8.encode(params.password)));
}

/// Isolate 入口点
void _isolateEntryPoint(_IsolateMessage message) {
  final result = _deriveKeyInIsolate(message.params);
  message.sendPort.send(result);
}

/// Encryption service using PBKDF2 + AES-256-GCM
/// All encryption happens locally on the device
class EncryptionService {
  static const int _keySize = 32; // 256 bits
  static const int _nonceSize = 12; // 96 bits for GCM
  static const int _iterations = 100000;
  static const int _saltSize = 16;

  /// Derive master key from master password using PBKDF2-HMAC-SHA256
  /// 同步版本（在主线程执行，会导致卡顿）
  static Uint8List deriveKey(String password, Uint8List salt) {
    final mac = HMac(SHA256Digest(), 64);
    final pkcs = PBKDF2KeyDerivator(mac);

    final params = Pbkdf2Parameters(
      salt,
      _iterations,
      _keySize,
    );

    pkcs.init(params);
    return pkcs.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Derive master key from master password using PBKDF2-HMAC-SHA256
  /// 异步版本（在 Isolate 中执行，不会阻塞 UI）
  static Future<Uint8List> deriveKeyAsync(String password, Uint8List salt) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _isolateEntryPoint,
      _IsolateMessage(
        params: _DeriveKeyParams(
          password: password,
          salt: salt,
          iterations: _iterations,
          keySize: _keySize,
        ),
        sendPort: receivePort.sendPort,
      ),
    );

    final result = await receivePort.first as Uint8List;
    receivePort.close();

    return result;
  }

  /// Generate a random salt for key derivation
  static Uint8List generateSalt() {
    final random = FortunaRandom();
    random.seed(KeyParameter(_generateRandomSeed()));
    return random.nextBytes(_saltSize);
  }

  /// Generate random nonce for AES-GCM
  static Uint8List generateNonce() {
    final random = FortunaRandom();
    random.seed(KeyParameter(_generateRandomSeed()));
    return random.nextBytes(_nonceSize);
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
