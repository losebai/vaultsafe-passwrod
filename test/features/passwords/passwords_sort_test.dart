import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/core/storage/storage_service.dart';
import 'package:vaultsafe/features/passwords/passwords_screen.dart';
import 'package:vaultsafe/shared/models/password_entry.dart';
import 'package:vaultsafe/shared/models/password_group.dart';
import 'package:vaultsafe/shared/models/password_sort_order.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';

void main() {
  testWidgets('sort menu orders passwords by each field in both directions',
      (tester) async {
    await pumpPasswords(tester);

    expect(visibleTitles(tester), ['zebra', 'Bravo', 'alpha']);

    const cases = {
      '创建时间（最早优先）': ['alpha', 'Bravo', 'zebra'],
      '创建时间（最新优先）': ['zebra', 'Bravo', 'alpha'],
      '更新时间（最近优先）': ['alpha', 'Bravo', 'zebra'],
      '更新时间（最早优先）': ['zebra', 'Bravo', 'alpha'],
      '名称（升序）': ['alpha', 'Bravo', 'zebra'],
      '名称（降序）': ['zebra', 'Bravo', 'alpha'],
    };
    for (final entry in cases.entries) {
      await selectSort(tester, entry.key);
      expect(visibleTitles(tester), entry.value, reason: entry.key);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps sorting when searching and switching groups',
      (tester) async {
    await pumpPasswords(tester);
    await selectSort(tester, '名称（升序）');

    await tester.enterText(find.byType(TextField), 'team');
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), ['alpha', 'zebra']);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.widgetWithText(FilterChip, '工作'));
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), ['alpha', 'zebra']);

    await selectSort(tester, '创建时间（最新优先）');
    expect(visibleTitles(tester), ['zebra', 'alpha']);

    await tester.tap(find.widgetWithText(FilterChip, '全部'));
    await tester.pumpAndSettle();
    expect(visibleTitles(tester), ['zebra', 'Bravo', 'alpha']);
    expect(tester.takeException(), isNull);
  });
}

Future<void> pumpPasswords(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(TestStorageService()),
      ],
      child: const MaterialApp(home: PasswordsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> selectSort(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.sort));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(
    CheckedPopupMenuItem<PasswordSortOrder>,
    label,
  ));
  await tester.pumpAndSettle();
}

List<String> visibleTitles(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data)
    .whereType<String>()
    .where((text) => ['alpha', 'Bravo', 'zebra'].contains(text))
    .toList();

class TestStorageService extends StorageService {
  @override
  Future<List<PasswordEntry>> getPasswordEntries() async => List.unmodifiable([
        entry('Bravo', 2, 2, 'personal'),
        entry('alpha', 1, 3, 'work'),
        entry('zebra', 3, 1, 'work'),
      ]);

  @override
  Future<List<PasswordGroup>> getGroups() async => [
        PasswordGroup.createDefault('work', '工作', 0),
      ];

  PasswordEntry entry(
      String title, int createdDay, int updatedDay, String group) {
    return PasswordEntry(
      id: title,
      title: title,
      website: '',
      username: group == 'work' ? 'team' : 'personal',
      encryptedPassword: EncryptedData(nonce: '', ciphertext: '', tag: ''),
      groupId: group,
      createdAt: DateTime(2026, 9, createdDay),
      updatedAt: DateTime(2026, 10, updatedDay),
    );
  }
}
