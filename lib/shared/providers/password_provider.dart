import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/shared/models/password_entry.dart';
import 'package:vaultsafe/shared/models/password_group.dart';

/// Password entries notifier
class PasswordEntriesNotifier extends StateNotifier<AsyncValue<List<PasswordEntry>>> {
  PasswordEntriesNotifier() : super(const AsyncValue.loading());

  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Load from local storage
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEntry(PasswordEntry entry) async {
    state.whenData((entries) {
      state = AsyncValue.data([...entries, entry]);
    });
  }

  Future<void> updateEntry(PasswordEntry entry) async {
    state.whenData((entries) {
      final updated = entries.map((e) => e.id == entry.id ? entry : e).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> deleteEntry(String id) async {
    state.whenData((entries) {
      final filtered = entries.where((e) => e.id != id).toList();
      state = AsyncValue.data(filtered);
    });
  }

  List<PasswordEntry> searchEntries(String query) {
    return state.value ?? [];
  }
}

/// Password groups notifier
class PasswordGroupsNotifier extends StateNotifier<AsyncValue<List<PasswordGroup>>> {
  PasswordGroupsNotifier() : super(const AsyncValue.loading());

  Future<void> loadGroups() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Load from local storage
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGroup(PasswordGroup group) async {
    state.whenData((groups) {
      state = AsyncValue.data([...groups, group]);
    });
  }

  Future<void> updateGroup(PasswordGroup group) async {
    state.whenData((groups) {
      final updated = groups.map((g) => g.id == group.id ? group : g).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> deleteGroup(String id) async {
    state.whenData((groups) {
      final filtered = groups.where((g) => g.id != id).toList();
      state = AsyncValue.data(filtered);
    });
  }
}

/// Providers
final passwordEntriesProvider = StateNotifierProvider<PasswordEntriesNotifier, AsyncValue<List<PasswordEntry>>>((ref) {
  return PasswordEntriesNotifier();
});

final passwordGroupsProvider = StateNotifierProvider<PasswordGroupsNotifier, AsyncValue<List<PasswordGroup>>>((ref) {
  return PasswordGroupsNotifier();
});

/// Filtered entries by group
final entriesByGroupProvider = Provider.family<AsyncValue<List<PasswordEntry>>, String?>((ref, groupId) {
  final entriesAsync = ref.watch(passwordEntriesProvider);

  return entriesAsync.whenData((entries) {
    if (groupId == null || groupId.isEmpty) {
      return entries;
    }
    return entries.where((e) => e.groupId == groupId).toList();
  });
});
