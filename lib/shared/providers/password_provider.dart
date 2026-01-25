import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/storage/storage_service.dart';
import 'package:vaultsafe/core/logging/log_service.dart';
import 'package:vaultsafe/shared/models/password_entry.dart';
import 'package:vaultsafe/shared/models/password_group.dart';

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Password entries notifier
class PasswordEntriesNotifier extends StateNotifier<AsyncValue<List<PasswordEntry>>> {
  PasswordEntriesNotifier(this._storageService) : super(const AsyncValue.loading());

  final StorageService _storageService;

  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _storageService.getPasswordEntries();
      log.i('Loaded ${entries.length} password entries from database', source: 'PasswordProvider');
      if (entries.isNotEmpty) {
        for (var entry in entries.take(5)) {
          log.d('Entry: ${entry.title} (${entry.username})', source: 'PasswordProvider');
        }
      }
      state = AsyncValue.data(entries);
      log.i('Provider state updated with ${entries.length} entries', source: 'PasswordProvider');
    } catch (e, st) {
      log.e('Error loading entries', source: 'PasswordProvider', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEntry(PasswordEntry entry) async {
    try {
      await _storageService.savePasswordEntry(entry);
      await loadEntries();
    } catch (e, st) {
      state.whenData((entries) {
        state = AsyncValue.error(e, st);
      });
    }
  }

  Future<void> updateEntry(PasswordEntry entry) async {
    try {
      await _storageService.savePasswordEntry(entry);
      await loadEntries();
    } catch (e, st) {
      state.whenData((entries) {
        state = AsyncValue.error(e, st);
      });
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _storageService.deletePasswordEntry(id);
      await loadEntries();
    } catch (e, st) {
      state.whenData((entries) {
        state = AsyncValue.error(e, st);
      });
    }
  }

  List<PasswordEntry> searchEntries(String query) {
    final entries = state.value ?? [];
    if (query.isEmpty) return entries;

    return entries.where((e) =>
        e.title.toLowerCase().contains(query.toLowerCase()) ||
        e.username.toLowerCase().contains(query.toLowerCase())).toList();
  }
}

/// Password groups notifier
class PasswordGroupsNotifier extends StateNotifier<AsyncValue<List<PasswordGroup>>> {
  PasswordGroupsNotifier(this._storageService) : super(const AsyncValue.loading());

  final StorageService _storageService;

  Future<void> loadGroups() async {
    state = const AsyncValue.loading();
    try {
      final groups = await _storageService.getGroups();
      state = AsyncValue.data(groups);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGroup(PasswordGroup group) async {
    try {
      await _storageService.saveGroup(group);
      await loadGroups();
    } catch (e, st) {
      state.whenData((groups) {
        state = AsyncValue.error(e, st);
      });
    }
  }

  Future<void> updateGroup(PasswordGroup group) async {
    try {
      await _storageService.saveGroup(group);
      await loadGroups();
    } catch (e, st) {
      state.whenData((groups) {
        state = AsyncValue.error(e, st);
      });
    }
  }

  Future<void> deleteGroup(String id) async {
    try {
      await _storageService.deleteGroup(id);
      await loadGroups();
    } catch (e, st) {
      state.whenData((groups) {
        state = AsyncValue.error(e, st);
      });
    }
  }
}

/// Providers
final passwordEntriesProvider = StateNotifierProvider<PasswordEntriesNotifier, AsyncValue<List<PasswordEntry>>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return PasswordEntriesNotifier(storageService);
});

final passwordGroupsProvider = StateNotifierProvider<PasswordGroupsNotifier, AsyncValue<List<PasswordGroup>>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return PasswordGroupsNotifier(storageService);
});

/// Filtered entries by group
final entriesByGroupProvider = Provider.family<AsyncValue<List<PasswordEntry>>, String?>((ref, groupId) {
  final entriesAsync = ref.watch(passwordEntriesProvider);

  return entriesAsync.when(
    data: (entries) {
      if (groupId == null || groupId.isEmpty) {
        return AsyncValue.data(entries);
      }
      final filtered = entries.where((e) => e.groupId == groupId).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
