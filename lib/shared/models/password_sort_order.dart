import 'package:vaultsafe/shared/models/password_entry.dart';

/// 密码列表的排序方式。
enum PasswordSortOrder {
  createdAtDescending('创建时间（最新优先）'),
  createdAtAscending('创建时间（最早优先）'),
  updatedAtDescending('更新时间（最近优先）'),
  updatedAtAscending('更新时间（最早优先）'),
  nameAscending('名称（升序）'),
  nameDescending('名称（降序）');

  const PasswordSortOrder(this.label);

  final String label;

  /// 排序副本，避免修改 provider 持有的原始列表。
  List<PasswordEntry> sort(List<PasswordEntry> entries) {
    return List<PasswordEntry>.of(entries)
      ..sort((a, b) {
        final comparison = switch (this) {
          createdAtDescending => b.createdAt.compareTo(a.createdAt),
          createdAtAscending => a.createdAt.compareTo(b.createdAt),
          updatedAtDescending => b.updatedAt.compareTo(a.updatedAt),
          updatedAtAscending => a.updatedAt.compareTo(b.updatedAt),
          nameAscending =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          nameDescending =>
            b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        };
        // 字段相同时用 ID 保证刷新后的顺序一致。
        return comparison != 0 ? comparison : a.id.compareTo(b.id);
      });
  }
}
