import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultafe/shared/providers/password_provider.dart';
import 'package:vaultafe/features/passwords/add_password_screen.dart';

/// Passwords list screen
class PasswordsScreen extends ConsumerStatefulWidget {
  const PasswordsScreen({super.key});

  @override
  ConsumerState<PasswordsScreen> createState() _PasswordsScreenState();
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
        title: const Text('Passwords'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
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
                          'No passwords yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first password',
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
              error: (err, stack) => Center(child: Text('Error: $err')),
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
            label: const Text('All'),
            selected: _selectedGroupId == null,
            onSelected: (selected) {
              setState(() => _selectedGroupId = selected ? null : _selectedGroupId);
            },
          ),
          const SizedBox(width: 8),
          // TODO: Add actual groups
          FilterChip(
            label: const Text('Personal'),
            selected: _selectedGroupId == 'personal',
            onSelected: (selected) {
              setState(() => _selectedGroupId = selected ? 'personal' : null);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Work'),
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
          // TODO: Copy password
        },
      ),
      onTap: () {
        // TODO: Navigate to detail
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

/// Search delegate for passwords
class PasswordSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  PasswordSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
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

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final entry = results[index];
            return ListTile(
              title: Text(entry.title),
              subtitle: Text(entry.username),
              onTap: () {
                close(context, entry.id);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
