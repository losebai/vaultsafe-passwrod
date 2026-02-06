import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/models/password_entry.dart';
import 'package:vaultsafe/shared/models/password_entry_type.dart';
import 'package:vaultsafe/shared/models/password_group.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/shared/utils/password_generator.dart';
import 'package:vaultsafe/features/passwords/password_detail_screen.dart';
import 'package:vaultsafe/features/passwords/add_password_screen.dart';
import 'package:vaultsafe/core/security/password_verification_service.dart';

/// 密码列表界面
class PasswordsScreen extends ConsumerStatefulWidget {
  const PasswordsScreen({super.key});

  @override
  ConsumerState<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends ConsumerState<PasswordsScreen> {
  String _searchQuery = '';
  String? _selectedGroupId;
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  bool _isRightPanelOpen = false;
  PasswordEntry? _selectedEntry; // 当前选中的密码条目
  bool _isEditMode = false; // 是否为编辑模式
  Offset? _lastRightClickPosition; // 存储右键点击位置

  // 检测是否为桌面平台
  bool get _isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    // 延迟到第一帧渲染后再加载数据，避免在 widget 树构建期间修改 provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(passwordEntriesProvider.notifier).loadEntries();
      ref.read(passwordGroupsProvider.notifier).loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesByGroupProvider(_selectedGroupId));
    final theme = Theme.of(context);

    // 桌面端布局
    if (_isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // 主内容区域
            Expanded(
              child: Column(
                children: [
                  // 顶部工具栏
                  _buildDesktopToolbar(theme),
                  // 分组筛选
                  _buildGroupFilter(),
                  // 选择模式提示栏
                  if (_isSelectionMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          Text(
                            '已选择 ${_selectedIds.length} 项',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _selectAll,
                            child: const Text('全选'),
                          ),
                          TextButton(
                            onPressed: _clearSelection,
                            child: const Text('取消'),
                          ),
                          if (_selectedIds.isNotEmpty)
                            FilledButton.tonalIcon(
                              onPressed: _deleteSelected,
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('删除'),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.errorContainer,
                                foregroundColor: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                  // 密码列表
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
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text( 
                                  '还没有密码',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '点击右侧按钮添加第一个密码',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }

                        return _buildDesktopGrid(filtered);
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('错误: $err')),
                    ),
                  ),
                ],
              ),
            ),
            // 右侧面板（添加/编辑密码）
            _buildRightPanel(theme),
          ],
        ),
      );
    }

    // 移动端布局
    return Scaffold(
      appBar: AppBar(
        title: const Text('密码'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
            tooltip: '搜索',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _toggleRightPanel(),
            tooltip: '添加',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGroupFilter(),
          if (_isSelectionMode)
            _buildSelectionBar(theme),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                final filtered = _searchQuery.isEmpty
                    ? entries
                    : entries.where((e) =>
                        e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        e.username.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return _buildMobileList(filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('错误: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FilledButton.tonalIcon(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('删除选中'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
            )
          : null,
    );
  }

  // 桌面端顶部工具栏
  Widget _buildDesktopToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 16),
      height: 64,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '密码',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 搜索框
          SizedBox(
            width: 300,
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: '搜索密码...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 新增按钮
          FilledButton.icon(
            onPressed: () => _toggleRightPanel(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新增'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          // 全选按钮
          OutlinedButton.icon(
            onPressed: _toggleSelectionMode,
            icon: const Icon(Icons.checklist, size: 18),
            label: const Text('全选'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          // 删除按钮
          if (_selectedIds.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('删除'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  // 右侧面板
  Widget _buildRightPanel(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isRightPanelOpen ? 450 : 0,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: _isRightPanelOpen
          ? ClipRect(
              child: Column(
                children: [
                  // 面板标题栏
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isEditMode ? Icons.edit : (_selectedEntry != null ? Icons.lock : Icons.add),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isEditMode
                              ? '编辑密码'
                              : (_selectedEntry != null ? '密码详情' : '添加密码'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isEditMode)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _isEditMode = false;
                              });
                            },
                            tooltip: '取消编辑',
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _closeRightPanel(),
                          tooltip: '关闭',
                        ),
                      ],
                    ),
                  ),
                  // 面板内容
                  Expanded(
                    child: _selectedEntry != null
                        ? _EditPasswordForm(
                            entry: _selectedEntry!,
                            onSave: () async {
                              // 等待 provider 完成数据刷新
                              await ref.read(passwordEntriesProvider.notifier).loadEntries();
                              // 关闭右侧面板
                              if (mounted) {
                                _closeRightPanel();
                              }
                            },
                            onCancel: () {
                              _closeRightPanel();
                            },
                          )
                        : _AddPasswordForm(
                            onSave: () {
                              _closeRightPanel();
                            },
                          ),
                          ),
                ],
              ),
            )
          : null,
    );
  }

  // 切换右侧面板（添加模式）
  void _toggleRightPanel() {
    setState(() {
      _isRightPanelOpen = !_isRightPanelOpen;
      if (_isRightPanelOpen) {
        _selectedEntry = null; // 清除选中项，进入添加模式
        _clearSelection();
      }
    });
  }

  // 打开密码编辑（需要验证）
  Future<void> _openPasswordEdit(PasswordEntry entry) async {
    // 验证主密码
    final verified = await requestPasswordVerification(
      context,
      ref,
      reason: '编辑密码',
    );

    if (!verified || !mounted) {
      return; // 验证失败或取消
    }

    setState(() {
      _selectedEntry = entry;
      _isEditMode = true;
      _isRightPanelOpen = true;
      _clearSelection();
    });
  }

  // 关闭右侧面板
  void _closeRightPanel() {
    setState(() {
      _isRightPanelOpen = false;
      _selectedEntry = null;
    });
  }

  // 移动端选择栏
  Widget _buildSelectionBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Text(
            '已选择 ${_selectedIds.length} 项',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _selectAll,
            child: const Text('全选'),
          ),
          TextButton(
            onPressed: _clearSelection,
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // 桌面端网格布局
  Widget _buildDesktopGrid(List<PasswordEntry> entries) {
    // 使用固定宽度的卡片，不受右侧面板影响
    const double cardWidth = 250; // 固定卡片宽度
    const double cardHeight = 70; // 固定卡片高度
    const double spacing = 10; // 间距

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(5),
            child: SizedBox(
              width: constraints.maxWidth, // 明确设置宽度为父级的最大宽度
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: spacing,
                runSpacing: spacing,
                children: entries.map((entry) {
                  final isSelected = _selectedIds.contains(entry.id);
                  return SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _buildPasswordCard(entry, isSelected),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  // 移动端列表布局
  Widget _buildMobileList(List<PasswordEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = _selectedIds.contains(entry.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPasswordCard(entry, isSelected),
        );
      },
    );
  }

  // 空状态
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_open_rounded,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有密码',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '点击 + 添加第一个密码',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  // 构建密码卡片
  Widget _buildPasswordCard(PasswordEntry entry, bool isSelected) {
    final theme = Theme.of(context);

    // 桌面端使用 GestureDetector 来支持右键菜单
    if (_isDesktop) {
      return GestureDetector(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(entry.id);
          } else {
            _openPasswordEdit(entry);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleSelection(entry.id);
          }
        },
        onSecondaryTapDown: (details) {
          // 存储右键点击位置
          _lastRightClickPosition = details.globalPosition;
          // 右键点击显示菜单
          _showContextMenu(context, entry);
        },
        child: _buildPasswordCardContent(entry, isSelected, theme),
      );
    }

    // 移动端点击直接进入编辑
    return InkWell(
      onTap: () async {
        if (_isSelectionMode) {
          _toggleSelection(entry.id);
        } else {
          // 验证后进入编辑模式
          final verified = await requestPasswordVerification(
            context,
            ref,
            reason: '编辑密码',
          );

          if (!verified || !mounted) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddPasswordScreen(entry: entry),
            ),
          );
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _toggleSelectionMode();
          _toggleSelection(entry.id);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: _buildPasswordCardContent(entry, isSelected, theme),
    );
  }

  // 密码卡片内容
  Widget _buildPasswordCardContent(PasswordEntry entry, bool isSelected, ThemeData theme) {
    return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 类型图标
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 72, 120).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    entry.type.icon,
                    size: 18,
                    color: const Color.fromARGB(255, 0, 72, 120),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color.fromARGB(255, 30, 30, 30),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.username,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color.fromARGB(255, 120, 120, 120),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 右侧操作按钮
              if (!_isSelectionMode) ...[
                // 显示密码按钮
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  onPressed: () async {
                  try {
                    final authService = ref.read(authServiceProvider);
                    final masterKey = authService.masterKey;
                    if (masterKey == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('密码库已锁定')),
                        );
                      }
                      return;
                    }

                    // 解密密码
                    final decrypted = EncryptionService.decrypt(entry.encryptedPassword, masterKey);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('密码: $decrypted'),
                          duration: const Duration(seconds: 3),
                          action: SnackBarAction(
                            label: '复制',
                            textColor: const Color.fromARGB(255, 0, 72, 120),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: decrypted));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已复制到剪贴板')),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('解密失败: $e')),
                      );
                    }
                  }
                },
                tooltip: '显示密码',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                color: const Color.fromARGB(255, 0, 72, 120),
              ),
              // 复制按钮
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已复制 ${entry.title} 的密码')),
                  );
                },
                tooltip: '复制密码',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                color: const Color.fromARGB(255, 0, 72, 120),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupFilter() {
    // 从数据库读取分组列表
    final groupsAsync = ref.watch(passwordGroupsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 分组筛选列表
          Expanded(
            child: groupsAsync.when(
              data: (groups) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // "全部"选项
                      FilterChip(
                        label: const Text('全部'),
                        selected: _selectedGroupId == null,
                        onSelected: (selected) {
                          setState(() => _selectedGroupId = selected ? null : _selectedGroupId);
                        },
                      ),
                      const SizedBox(width: 8),
                      // 动态生成分组选项
                      ...groups.map((group) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(group.name),
                            selected: _selectedGroupId == group.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedGroupId = selected ? group.id : null;
                              });
                            },
                            // 所有分组都可以删除
                            onDeleted: () {
                              _deleteGroup(group.id);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          // 新增分组按钮
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: _showAddGroupDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新增分组'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 显示新增分组对话框
  void _showAddGroupDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增分组'),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '分组名称',
              hintText: '例如：社交媒体、金融账户等',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _addGroup(value.trim());
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final groupName = controller.text.trim();
              if (groupName.isNotEmpty) {
                _addGroup(groupName);
                Navigator.of(context).pop();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    ).then((_) {
      controller.dispose();
    });
  }

  // 添加新分组
  void _addGroup(String groupName) async {
    // 检查是否已存在同名分组
    final groupsAsync = ref.read(passwordGroupsProvider);
    groupsAsync.whenData((groups) async {
      // 检查是否已存在同名分组
      if (groups.any((g) => g.name == groupName)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('分组"$groupName"已存在')),
          );
        }
        return;
      }

      // 创建新的分组对象
      final now = DateTime.now();
      final newGroup = PasswordGroup(
        id: const Uuid().v4(),
        name: groupName,
        order: groups.length,
        createdAt: now,
        updatedAt: now,
      );

      // 保存到数据库
      await ref.read(passwordGroupsProvider.notifier).addGroup(newGroup);

      // 自动选中新创建的分组
      setState(() {
        _selectedGroupId = newGroup.id;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加分组：$groupName')),
        );
      }
    });
  }

  // 删除分组
  void _deleteGroup(String groupId) {
    // 显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: SizedBox(
          width: 300,
          child: const Text('删除分组不会删除该分组下的密码条目，确定要删除吗？'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              // 在异步操作前关闭对话框
              Navigator.of(context).pop();

              // 从数据库删除分组
              await ref.read(passwordGroupsProvider.notifier).deleteGroup(groupId);

              // 如果删除的是当前选中的分组，清空选择
              if (_selectedGroupId == groupId) {
                setState(() {
                  _selectedGroupId = null;
                });
              }

              // 显示提示消息
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已删除分组')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 切换选择模式
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  // 切换单项选择
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // 全选
  void _selectAll() {
    final entriesAsync = ref.read(entriesByGroupProvider(_selectedGroupId));
    entriesAsync.whenData((entries) {
      setState(() {
        _selectedIds.addAll(entries.map((e) => e.id));
      });
    });
  }

  // 清除选择
  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  // 删除选中项
  void _deleteSelected() {
    if (_selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 个密码吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              for (final id in _selectedIds) {
                await ref.read(passwordEntriesProvider.notifier).deleteEntry(id);
              }
              _clearSelection();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已删除选中的密码')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 显示右键菜单
  void _showContextMenu(BuildContext context, PasswordEntry entry) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    // 使用存储的右键点击位置，如果没有则默认为屏幕中心
    final position = _lastRightClickPosition ?? Offset.zero;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'copy_username',
          child: Row(
            children: const [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: 12),
              Text('复制用户名'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'copy_password',
          child: Row(
            children: const [
              Icon(Icons.password, size: 18),
              SizedBox(width: 12),
              Text('复制密码'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 12),
              Text('编辑'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );

    if (result != null) {
      switch (result) {
        case 'copy_username':
          await _copyUsername(entry);
          break;
        case 'copy_password':
          await _copyPassword(entry);
          break;
        case 'edit':
          await _openPasswordEdit(entry);
          break;
        case 'delete':
          await _deleteEntry(entry);
          break;
      }
    }
  }

  // 复制用户名
  Future<void> _copyUsername(PasswordEntry entry) async {
    await Clipboard.setData(ClipboardData(text: entry.username));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已复制用户名: ${entry.username}')),
      );
    }
  }

  // 复制密码
  Future<void> _copyPassword(PasswordEntry entry) async {
    // 验证主密码
    final verified = await requestPasswordVerification(
      context,
      ref,
      reason: '复制密码',
    );

    if (!verified) {
      return; // 验证失败或取消
    }

    try {
      final authService = ref.read(authServiceProvider);
      final masterKey = authService.masterKey;
      if (masterKey == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码库已锁定')),
          );
        }
        return;
      }

      final decrypted = EncryptionService.decrypt(entry.encryptedPassword, masterKey);
      await Clipboard.setData(ClipboardData(text: decrypted));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制密码到剪贴板')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解密失败: $e')),
        );
      }
    }
  }

  // 删除单个密码条目
  Future<void> _deleteEntry(PasswordEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${entry.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(passwordEntriesProvider.notifier).deleteEntry(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除: ${entry.title}')),
        );
      }
    }
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: PasswordSearchDelegate(ref),
    );
  }
}

/// 添加密码表单组件
class _AddPasswordForm extends ConsumerStatefulWidget {
  final VoidCallback onSave;

  const _AddPasswordForm({required this.onSave});

  @override
  ConsumerState<_AddPasswordForm> createState() => _AddPasswordFormState();
}

class _AddPasswordFormState extends ConsumerState<_AddPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _websiteController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _notesController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  PasswordEntryType _selectedType = PasswordEntryType.website;
  String? _selectedGroupId;
  bool _syncEnabled = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _websiteController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _notesController = TextEditingController();
    _selectedGroupId = 'default';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // 分组选择器
            Consumer(
              builder: (context, ref, child) {
                final groupsAsync = ref.watch(passwordGroupsProvider);

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '分组',
                    prefixIcon: Icon(Icons.folder),
                  ),
                  items: groupsAsync.when(
                    data: (groups) {
                      return [
                        const DropdownMenuItem(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.folder_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('无分组'),
                            ],
                          ),
                        ),
                        ...groups.map((group) {
                          return DropdownMenuItem(
                            value: group.id,
                            child: Row(
                              children: [
                                const Icon(Icons.folder_outlined, size: 20),
                                const SizedBox(width: 12),
                                Text(group.name),
                              ],
                            ),
                          );
                        }),
                      ];
                    },
                    loading: () => [],
                    error: (_, __) => [],
                  ),
                  initialValue: groupsAsync.whenData((groups) {
                    final validIds = groups.map((g) => g.id).toSet();
                    return validIds.contains(_selectedGroupId) ? _selectedGroupId : null;
                  }).value,
                  onChanged: (value) {
                    setState(() => _selectedGroupId = value);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // 类型选择器
            DropdownButtonFormField<PasswordEntryType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: '密钥类型',
                prefixIcon: Icon(Icons.category),
              ),
              items: PasswordEntryType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20),
                      const SizedBox(width: 12),
                      Text(type.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '例如：Google 账号',
                prefixIcon: Icon(Icons.title),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: _selectedType.websiteLabel,
                hintText: _selectedType == PasswordEntryType.website
                    ? '例如：https://google.com'
                    : '根据需要填写',
                prefixIcon: const Icon(Icons.language),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (_selectedType.isWebsiteRequired && (value == null || value.isEmpty)) {
                  return '请输入${_selectedType.websiteLabel}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: _selectedType.usernameLabel,
                prefixIcon: Icon(_selectedType == PasswordEntryType.wifi
                    ? Icons.wifi
                    : Icons.person),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入${_selectedType.usernameLabel}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword && !_selectedType.isPasswordMultiline,
              decoration: InputDecoration(
                labelText: _selectedType.passwordLabel,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: _selectedType.requiresLongTextInput
                    ? null
                    : SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _generatePassword,
                              tooltip: '生成密码',
                            ),
                            IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                              tooltip: '显示/隐藏密码',
                            ),
                          ],
                        ),
                      ),
              ),
              maxLines: _selectedType.isPasswordMultiline ? 8 : 1,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入${_selectedType.passwordLabel}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用同步'),
              subtitle: const Text('关闭后此密码仅保存在本地，不会同步到云端'),
              value: _syncEnabled,
              onChanged: (value) {
                setState(() {
                  _syncEnabled = value;
                });
              },
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _isLoading ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存密码'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final masterKey = authService.masterKey;

      if (masterKey == null) {
        throw Exception('密码库已锁定');
      }

      // 导入加密服务
      final encrypted = EncryptionService.encrypt(_passwordController.text, masterKey);

      final entry = PasswordEntry(
        id: const Uuid().v4(),
        title: _titleController.text,
        website: _websiteController.text,
        username: _usernameController.text,
        encryptedPassword: encrypted,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        groupId: _selectedGroupId ?? 'default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: _selectedType,
        syncEnabled: _syncEnabled,
      );

      await ref.read(passwordEntriesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      widget.onSave();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已保存')),
      );

      // 清空表单
      _titleController.clear();
      _websiteController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _notesController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('错误: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _generatePassword() {
    final password = PasswordGenerator.generate(
      length: 16,
      includeUppercase: true,
      includeLowercase: true,
      includeNumbers: true,
      includeSymbols: true,
    );

    setState(() {
      _passwordController.text = password;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _websiteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

/// 编辑密码表单组件
class _EditPasswordForm extends ConsumerStatefulWidget {
  final PasswordEntry entry;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditPasswordForm({
    required this.entry,
    required this.onSave,
    required this.onCancel,
  });

  @override
  ConsumerState<_EditPasswordForm> createState() => _EditPasswordFormState();
}

class _EditPasswordFormState extends ConsumerState<_EditPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _websiteController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _notesController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  late PasswordEntryType _selectedType;
  late String? _selectedGroupId;
  late bool _syncEnabled;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _websiteController = TextEditingController(text: widget.entry.website);
    _usernameController = TextEditingController(text: widget.entry.username);
    _passwordController = TextEditingController();
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _selectedType = widget.entry.type;
    _selectedGroupId = widget.entry.groupId;
    _syncEnabled = widget.entry.syncEnabled;
    _decryptPassword();
  }

  Future<void> _decryptPassword() async {
    try {
      final authService = ref.read(authServiceProvider);
      final masterKey = authService.masterKey;

      if (masterKey != null) {
        final decrypted = EncryptionService.decrypt(widget.entry.encryptedPassword, masterKey);
        if (mounted) {
          setState(() {
            _passwordController.text = decrypted;
          });
        }
      }
    } catch (e) {
      debugPrint('解密失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 分组选择器
            Consumer(
              builder: (context, ref, child) {
                final groupsAsync = ref.watch(passwordGroupsProvider);

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '分组',
                    prefixIcon: Icon(Icons.folder),
                  ),
                  items: groupsAsync.when(
                    data: (groups) {
                      return [
                        const DropdownMenuItem(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.folder_outlined, size: 20),
                              SizedBox(width: 12),
                              Text('无分组'),
                            ],
                          ),
                        ),
                        ...groups.map((group) {
                          return DropdownMenuItem(
                            value: group.id,
                            child: Row(
                              children: [
                                const Icon(Icons.folder_outlined, size: 20),
                                const SizedBox(width: 12),
                                Text(group.name),
                              ],
                            ),
                          );
                        }),
                      ];
                    },
                    loading: () => [],
                    error: (_, __) => [],
                  ),
                  initialValue: groupsAsync.whenData((groups) {
                    final validIds = groups.map((g) => g.id).toSet();
                    return validIds.contains(_selectedGroupId) ? _selectedGroupId : null;
                  }).value,
                  onChanged: (value) {
                    setState(() => _selectedGroupId = value);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // 类型选择器
            DropdownButtonFormField<PasswordEntryType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: '密钥类型',
                prefixIcon: Icon(Icons.category),
              ),
              items: PasswordEntryType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20),
                      const SizedBox(width: 12),
                      Text(type.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '例如：Google 账号',
                prefixIcon: Icon(Icons.title),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: _selectedType.websiteLabel,
                hintText: _selectedType == PasswordEntryType.website
                    ? '例如：https://google.com'
                    : '根据需要填写',
                prefixIcon: const Icon(Icons.language),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (_selectedType.isWebsiteRequired && (value == null || value.isEmpty)) {
                  return '请输入${_selectedType.websiteLabel}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: _selectedType.usernameLabel,
                prefixIcon: Icon(_selectedType == PasswordEntryType.wifi
                    ? Icons.wifi
                    : Icons.person),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入${_selectedType.usernameLabel}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword && !_selectedType.isPasswordMultiline,
              decoration: InputDecoration(
                labelText: _selectedType.passwordLabel,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: _selectedType.requiresLongTextInput
                    ? null
                    : SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _generatePassword,
                              tooltip: '生成密码',
                            ),
                            IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                              tooltip: '显示/隐藏密码',
                            ),
                          ],
                        ),
                      ),
              ),
              maxLines: _selectedType.isPasswordMultiline ? 8 : 1,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入${_selectedType.passwordLabel}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用同步'),
              subtitle: const Text('关闭后此密码仅保存在本地，不会同步到云端'),
              value: _syncEnabled,
              onChanged: (value) {
                setState(() {
                  _syncEnabled = value;
                });
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存修改'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final masterKey = authService.masterKey;

      if (masterKey == null) {
        throw Exception('密码库已锁定');
      }

      // 加密新密码
      final encrypted = EncryptionService.encrypt(_passwordController.text, masterKey);

      final updatedEntry = widget.entry.copyWith(
        title: _titleController.text,
        website: _websiteController.text,
        username: _usernameController.text,
        encryptedPassword: encrypted,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        groupId: _selectedGroupId,
        type: _selectedType,
        updatedAt: DateTime.now(),
        syncEnabled: _syncEnabled,
      );

      await ref.read(passwordEntriesProvider.notifier).updateEntry(updatedEntry);

      if (!mounted) return;

      widget.onSave();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已更新')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('错误: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _generatePassword() {
    final password = PasswordGenerator.generate(
      length: 16,
      includeUppercase: true,
      includeLowercase: true,
      includeNumbers: true,
      includeSymbols: true,
    );

    setState(() {
      _passwordController.text = password;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _websiteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

/// 密码详情面板
class _PasswordDetailPanel extends ConsumerStatefulWidget {
  final PasswordEntry entry;

  const _PasswordDetailPanel({required this.entry});

  @override
  ConsumerState<_PasswordDetailPanel> createState() => _PasswordDetailPanelState();
}

class _PasswordDetailPanelState extends ConsumerState<_PasswordDetailPanel> {
  bool _showPassword = false;
  String? _decryptedPassword;

  @override
  void initState() {
    super.initState();
    _decryptPassword();
  }

  Future<void> _decryptPassword() async {
    try {
      final authService = ref.read(authServiceProvider);
      final masterKey = authService.masterKey;

      if (masterKey != null) {
        final decrypted = EncryptionService.decrypt(widget.entry.encryptedPassword, masterKey);
        if (mounted) {
          setState(() {
            _decryptedPassword = decrypted;
          });
        }
      }
    } catch (e) {
      debugPrint('解密失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和首字母图标
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 72, 120).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    widget.entry.title.isNotEmpty ? widget.entry.title[0].toUpperCase() : '?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color.fromARGB(255, 0, 72, 120),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.entry.type.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 详情卡片
          _buildDetailCard(
            theme,
            icon: Icons.person,
            label: widget.entry.type.usernameLabel,
            value: widget.entry.username,
          ),
          const SizedBox(height: 16),

          // Only show website if not empty or required
          if (widget.entry.website.isNotEmpty || widget.entry.type.isWebsiteRequired) ...[
            _buildDetailCard(
              theme,
              icon: Icons.language,
              label: widget.entry.type.websiteLabel,
              value: widget.entry.website,
            ),
            const SizedBox(height: 16),
          ],

          // 密码卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock, size: 20, color: Color.fromARGB(255, 0, 72, 120)),
                    const SizedBox(width: 12),
                    Text(
                      widget.entry.type.passwordLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    // 显示/隐藏密码按钮
                    IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                      tooltip: _showPassword ? '隐藏密码' : '显示密码',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    // 复制按钮
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: _decryptedPassword != null
                          ? () {
                              Clipboard.setData(ClipboardData(text: _decryptedPassword!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已复制到剪贴板')),
                              );
                            }
                          : null,
                      tooltip: '复制密码',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _showPassword
                      ? (_decryptedPassword ?? '正在解密...')
                      : '•' * 12,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFamily: _showPassword ? 'monospace' : null,
                    color: _showPassword
                        ? const Color.fromARGB(255, 0, 72, 120)
                        : theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // 备注
          if (widget.entry.notes != null && widget.entry.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              theme,
              icon: Icons.notes,
              label: '备注',
              value: widget.entry.notes!,
              isMultiline: true,
            ),
          ],

          const SizedBox(height: 24),

          // 时间信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '时间信息',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTimeInfo('创建时间', widget.entry.createdAt, theme),
                const SizedBox(height: 8),
                _buildTimeInfo('更新时间', widget.entry.updatedAt, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color.fromARGB(255, 0, 72, 120)),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已复制 $label')),
              );
            },
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color.fromARGB(255, 0, 72, 120),
              ),
              maxLines: isMultiline ? null : 1,
              overflow: isMultiline ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, DateTime dateTime, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          _formatDateTime(dateTime),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color.fromARGB(255, 0, 72, 120),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
