import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultsafe/core/storage/storage_service.dart';
import 'package:vaultsafe/core/logging/log_service.dart';
import 'package:vaultsafe/shared/models/totp_entry.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';

/// TOTP 条目 Notifier
class TotpEntriesNotifier extends StateNotifier<AsyncValue<List<TotpEntry>>> {
  TotpEntriesNotifier(this._storageService)
      : log = LogService.instance,
        super(const AsyncValue.loading());

  final StorageService _storageService;
  final LogService log;

  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _storageService.getTotpEntries();
      log.i('Loaded ${entries.length} TOTP entries', source: 'TotpProvider');
      state = AsyncValue.data(entries);
    } catch (e, st) {
      log.e('Error loading TOTP entries', source: 'TotpProvider', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEntry(TotpEntry entry) async {
    try {
      await _storageService.saveTotpEntry(entry);
      log.i('新增 TOTP: ${entry.name}', source: 'UserOperation');
      await loadEntries();
    } catch (e, st) {
      state.whenData((entries) {
        state = AsyncValue.error(e, st);
      });
    }
  }

  Future<void> updateEntry(TotpEntry entry) async {
    try {
      await _storageService.saveTotpEntry(entry);
      log.i('修改 TOTP: ${entry.name}', source: 'UserOperation');
      await loadEntries();
    } catch (e, st) {
      state.whenData((entries) {
        state = AsyncValue.error(e, st);
      });
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final entry = state.value?.firstWhere((e) => e.id == id);
      await _storageService.deleteTotpEntry(id);
      if (entry != null) {
        log.i('删除 TOTP: ${entry.name}', source: 'UserOperation');
      }
      await loadEntries();
    } catch (e, st) {
      state.whenData((entries) {
        state = AsyncValue.error(e, st);
      });
    }
  }

  /// 从 otpauth:// URI 添加 TOTP 条目
  Future<bool> addFromUri(String uri) async {
    final entry = TotpEntry.fromOtpAuthUri(uri);
    if (entry == null) return false;
    await addEntry(entry);
    return true;
  }

  /// 手动创建 TOTP 条目
  Future<void> addManual({
    required String name,
    required String account,
    required String secret,
    String issuer = '',
    int digits = 6,
    int period = 30,
    String algorithm = 'SHA1',
  }) async {
    final now = DateTime.now();
    final entry = TotpEntry(
      id: const Uuid().v4(),
      name: name,
      issuer: issuer,
      account: account,
      secret: secret.toUpperCase(),
      digits: digits,
      period: period,
      algorithm: algorithm,
      createdAt: now,
      updatedAt: now,
    );
    await addEntry(entry);
  }
}

/// TOTP 条目 Provider
final totpEntriesProvider = StateNotifierProvider<TotpEntriesNotifier, AsyncValue<List<TotpEntry>>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return TotpEntriesNotifier(storageService);
});
