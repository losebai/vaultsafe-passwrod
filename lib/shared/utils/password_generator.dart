import 'dart:math';
import 'package:collection/collection.dart';

/// Password generator utility
class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  /// Generate a strong random password
  static String generate({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool excludeAmbiguous = false,
  }) {
    final random = Random.secure();
    var chars = '';

    if (includeLowercase) chars += _lowercase;
    if (includeUppercase) chars += _uppercase;
    if (includeNumbers) chars += _numbers;
    if (includeSymbols) chars += _symbols;

    if (excludeAmbiguous) {
      final ambiguous = 'il1Lo0O';
      chars = chars.split('').where((c) => !ambiguous.contains(c)).join();
    }

    if (chars.isEmpty) {
      chars = _lowercase + _numbers;
    }

    final password = List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();

    return password;
  }

  /// Generate a memorable passphrase (e.g., "correct-horse-battery-staple")
  static String generatePassphrase({
    int wordCount = 4,
    String separator = '-',
  }) {
    // Simplified word list (should use a larger dictionary in production)
    const words = [
      'correct', 'horse', 'battery', 'staple', 'apple', 'banana', 'cherry',
      'dragon', 'elephant', 'flower', 'guitar', 'house', 'island', 'jungle',
      'kite', 'lemon', 'mountain', 'notebook', 'ocean', 'piano', 'quest',
      'river', 'sun', 'tree', 'umbrella', 'village', 'water', 'zebra',
    ];

    final random = Random.secure();
    final selectedWords = List.generate(
      wordCount,
      (_) => words[random.nextInt(words.length)],
    );

    return selectedWords.join(separator);
  }

  /// Calculate password strength (0-4)
  static int calculateStrength(String password) {
    if (password.isEmpty) return 0;

    var score = 0;

    // Length
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSymbols = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasLowercase) score++;
    if (hasUppercase) score++;
    if (hasNumbers) score++;
    if (hasSymbols) score++;

    // Cap at 4
    return score.clamp(0, 4);
  }

  /// Get strength label
  static String getStrengthLabel(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }

  /// Get strength color
  static String getStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return '#F44336'; // Red
      case 2:
        return '#FF9800'; // Orange
      case 3:
        return '#FFC107'; // Amber
      case 4:
        return '#4CAF50'; // Green
      default:
        return '#9E9E9E'; // Grey
    }
  }
}
