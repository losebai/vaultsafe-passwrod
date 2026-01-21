import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/features/passwords/add_password_screen.dart';
import 'package:vaultsafe/features/passwords/password_detail_screen.dart';

/// 密码列表界面
class PasswordsScreen extends ConsumerStatefulWidget {
  const PasswordsScreen({super.key});

  @override
  ConsumerState<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends ConsumerState<PasswordsScreen> {
  String _searchQuery = '';
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    ref.read(passwordEntriesProvider.notifier).loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesByGroupProvider(_selectedGroupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('密码'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
            tooltip: '搜索',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGroupFilter(),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                final filtered = _searchQuery.isEmpty
                    ? entries
                    : entries.where((e) =>
                        e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        e.username.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '还没有密码',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击 + 添加第一个密码',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return _buildPasswordTile(entry);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('错误: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddPasswordScreen()),
          );
        },
        tooltip: '添加密码',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupFilter() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            label: const Text('全部'),
            selected: _selectedGroupId == null,
            onSelected: (selected) {
              setState(() => _selectedGroupId = selected ? null : _selectedGroupId);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('个人'),
            selected: _selectedGroupId == 'personal',
            onSelected: (selected) {
              setState(() => _selectedGroupId = selected ? 'personal' : null);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('工作'),
            selected: _selectedGroupId == 'work',
            onSelected: (selected) {
              setState(() => _selectedGroupId = selected ? 'work' : null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTile(entry) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(entry.title[0].toUpperCase()),
      ),
      title: Text(entry.title),
      subtitle: Text(entry.username),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () {
          // TODO: 复制用户名
        },
        tooltip: '复制',
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PasswordDetailScreen(entry: entry),
          ),
        );
      },
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: PasswordSearchDelegate(ref),
    );
  }
}

/// 密码搜索代理
class PasswordSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  PasswordSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => '搜索密码';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
        tooltip: '清空',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
      tooltip: '返回',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final entriesAsync = ref.watch(passwordEntriesProvider);

    return entriesAsync.when(
      data: (entries) {
        final results = query.isEmpty
            ? entries
            : entries.where((e) =>
                e.title.toLowerCase().contains(query.toLowerCase()) ||
                e.username.toLowerCase().contains(query.toLowerCase())).toList();

        if (results.isEmpty) {
          return const Center(child: Text('没有找到匹配的密码'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final entry = results[index];
            return ListTile(
              title: Text(entry.title),
              subtitle: Text(entry.username),
              onTap: () {
                close(context, entry.id);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PasswordDetailScreen(entry: entry),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('错误: $err')),
    );
  }
}
