import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:vaultsafe/shared/models/totp_entry.dart';

/// TOTP 服务 - 基于 RFC 6238 实现时间基础的一次性密码
class TotpService {
  /// 生成 TOTP 验证码
  static String generateCode(TotpEntry entry) {
    return generateTotpCode(
      secret: entry.secret,
      period: entry.period,
      digits: entry.digits,
      algorithm: entry.algorithm,
    );
  }

  /// 生成 TOTP 验证码（核心方法）
  static String generateTotpCode({
    required String secret,
    int period = 30,
    int digits = 6,
    String algorithm = 'SHA1',
  }) {
    // 1. 解码 Base32 密钥
    final key = _decodeBase32(secret);

    // 2. 计算时间步长
    final timeStep = (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ period;

    // 3. 将时间步长转为 8 字节大端序
    final timeBytes = ByteData(8);
    timeBytes.setUint64(0, timeStep);

    // 4. 计算 HMAC
    final hmac = _createHmac(algorithm, key);
    final hash = hmac.convert(timeBytes.buffer.asUint8List()).bytes;

    // 5. 动态截断
    final offset = hash[hash.length - 1] & 0x0F;
    final binary = ((hash[offset] & 0x7F) << 24) |
        ((hash[offset + 1] & 0xFF) << 16) |
        ((hash[offset + 2] & 0xFF) << 8) |
        (hash[offset + 3] & 0xFF);

    // 6. 取模得到指定位数的验证码
    final otp = binary % _pow10(digits);
    return otp.toString().padLeft(digits, '0');
  }

  /// 获取当前时间步的剩余秒数（用于倒计时）
  static int getRemainingSeconds({int period = 30}) {
    final currentSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return period - (currentSeconds % period);
  }

  /// 获取当前时间步的进度（0.0 - 1.0）
  static double getProgress({int period = 30}) {
    return getRemainingSeconds(period: period) / period;
  }

  /// 生成随机 Base32 密钥（用于测试或新建）
  static String generateSecret({int length = 20}) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(length, (_) => base32Chars[random.nextInt(32)]).join();
  }

  /// 解码 Base32 字符串
  static Uint8List _decodeBase32(String input) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final sanitized = input.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');

    final buffer = <int>[];
    int bits = 0;
    int value = 0;

    for (final char in sanitized.codeUnits) {
      final charIndex = base32Chars.indexOf(String.fromCharCode(char));
      if (charIndex < 0) continue;

      value = (value << 5) | charIndex;
      bits += 5;

      if (bits >= 8) {
        bits -= 8;
        buffer.add((value >> bits) & 0xFF);
      }
    }

    return Uint8List.fromList(buffer);
  }

  /// 创建 HMAC 实例
  static Hmac _createHmac(String algorithm, Uint8List key) {
    switch (algorithm.toUpperCase()) {
      case 'SHA256':
        return Hmac(sha256, key);
      case 'SHA512':
        return Hmac(sha512, key);
      case 'SHA1':
      default:
        return Hmac(sha1, key);
    }
  }

  /// 计算 10 的 n 次方
  static int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}
