import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vaultsafe/features/passwords/passwords_screen.dart';
import 'package:vaultsafe/features/settings/settings_screen.dart';
import 'package:vaultsafe/features/profile/profile_screen.dart';

/// 主界面 - 响应式导航（桌面端侧边栏，移动端底部导航）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isCollapsed = true;

  final List<Widget> _screens = const [
    PasswordsScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  final List<_NavigationItem> _navItems = const [
    _NavigationItem(
      icon: Icons.password_rounded,
      selectedIcon: Icons.password_rounded,
      label: '密码',
    ),
    _NavigationItem(
      icon: Icons.person_rounded,
      selectedIcon: Icons.person_rounded,
      label: '我的',
    ),
    _NavigationItem(
      icon: Icons.settings_rounded,
      selectedIcon: Icons.settings_rounded,
      label: '设置',
    ),
  ];

  // 检测是否为桌面平台
  bool get _isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 桌面端使用网格布局
    if (_isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // 侧边栏
            _buildSideBar(),
            // 主内容区域 - 网格卡片布局
            Expanded(
              child: _buildDesktopContent(context, theme),
            ),
          ],
        ),
      );
    }

    // 移动端使用底部导航栏
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  // 构建桌面端主要内容区域
  Widget _buildDesktopContent(BuildContext context, ThemeData theme) {
    switch (_selectedIndex) {
      case 0: // 密码
        return _buildPasswordsContent();
      case 1: // 个人中心
        return _buildProfileContent(context);
      case 2: // 设置
        return _buildSettingsContent(context);
      default:
        return _screens[_selectedIndex];
    }
  }

  // 构建密码页面内容
  Widget _buildPasswordsContent() {
    return const PasswordsScreen();
  }

  // 构建个人中心内容 - 左侧导航右侧内容布局
  Widget _buildProfileContent(BuildContext context) {
    return const _ProfileLayout();
  }

  // 构建设置内容 - 左侧导航右侧内容布局
  Widget _buildSettingsContent(BuildContext context) {
    return const _SettingsLayout();
  }

  // 构建桌面端侧边栏
  Widget _buildSideBar() {
    final width = _isCollapsed ? 72.0 : 150.0;
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶部 Logo 区域
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: _isCollapsed ? 0 : 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    'VaultSafe',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 导航菜单
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return _buildNavItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                  },
                );
              },
            ),
          ),

          // 底部收缩按钮
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() => _isCollapsed = !_isCollapsed);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _isCollapsed
                        ? Icons.chevron_right
                        : Icons.chevron_left,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建导航项
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _isCollapsed ? 8 : 12,
        vertical: 4,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.8)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isCollapsed
              ? Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                )
              : Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      icon,
                      size: 24,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 导航项数据模型
class _NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// 个人中心布局 - 左侧导航右侧内容
class _ProfileLayout extends StatefulWidget {
  const _ProfileLayout();

  @override
  State<_ProfileLayout> createState() => _ProfileLayoutState();
}

class _ProfileLayoutState extends State<_ProfileLayout> {
  String? _selectedSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // 左侧导航
        Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '个人中心',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildNavButton(
                icon: Icons.person_outline,
                label: '账户信息',
                isSelected: _selectedSection == 'account',
                onTap: () => setState(() => _selectedSection = 'account'),
              ),
              const SizedBox(height: 4),
              _buildNavButton(
                icon: Icons.devices_outlined,
                label: '设备列表',
                isSelected: _selectedSection == 'devices',
                onTap: () => setState(() => _selectedSection = 'devices'),
              ),
              const SizedBox(height: 4),
              _buildNavButton(
                icon: Icons.history_outlined,
                label: '安全日志',
                isSelected: _selectedSection == 'logs',
                onTap: () => setState(() => _selectedSection = 'logs'),
              ),
              const SizedBox(height: 4),
              _buildNavButton(
                icon: Icons.lock_outline,
                label: '修改密码',
                isSelected: _selectedSection == 'password',
                onTap: () => setState(() => _selectedSection = 'password'),
              ),
            ],
          ),
        ),
        // 右侧内容
        Expanded(
          child: _selectedSection == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '请选择左侧菜单',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildProfileSectionContent(_selectedSection!),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSectionContent(String section) {
    switch (section) {
      case 'account':
        return const _ProfileAccountSection();
      case 'devices':
        return const _ProfileDevicesSection();
      case 'logs':
        return const _ProfileLogsSection();
      case 'password':
        return const _ProfilePasswordSection();
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 账户信息部分
class _ProfileAccountSection extends StatelessWidget {
  const _ProfileAccountSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '账户信息',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('用户名'),
                  subtitle: const Text('admin'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('邮箱'),
                  subtitle: const Text('user@example.com'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('注册时间'),
                  subtitle: const Text('2024-01-01'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 设备列表部分
class _ProfileDevicesSection extends StatelessWidget {
  const _ProfileDevicesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已登录设备',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: List.generate(3, (index) {
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.computer),
                      title: Text('设备 ${index + 1}'),
                      subtitle: Text('上次登录: ${DateTime.now().toString().substring(0, 10)}'),
                      trailing: const Text('当前设备'),
                    ),
                    if (index < 2) const Divider(height: 1),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// 安全日志部分
class _ProfileLogsSection extends StatelessWidget {
  const _ProfileLogsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '登录日志',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: List.generate(5, (index) {
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text('登录成功'),
                      subtitle: Text('${DateTime.now().toString().substring(0, 19)} - Windows PC'),
                    ),
                    if (index < 4) const Divider(height: 1),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// 修改密码部分
class _ProfilePasswordSection extends StatelessWidget {
  const _ProfilePasswordSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '修改密码',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '当前密码',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '新密码',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '确认新密码',
                      prefixIcon: Icon(Icons.lock_clock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('修改密码'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 设置布局 - 左侧导航右侧内容
class _SettingsLayout extends StatefulWidget {
  const _SettingsLayout();

  @override
  State<_SettingsLayout> createState() => _SettingsLayoutState();
}

class _SettingsLayoutState extends State<_SettingsLayout> {
  String? _selectedSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // 左侧导航
        Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '设置',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildNavButton(
                icon: Icons.security_outlined,
                label: '安全',
                isSelected: _selectedSection == 'security',
                onTap: () => setState(() => _selectedSection = 'security'),
              ),
              const SizedBox(height: 4),
              _buildNavButton(
                icon: Icons.sync_outlined,
                label: '同步',
                isSelected: _selectedSection == 'sync',
                onTap: () => setState(() => _selectedSection = 'sync'),
              ),
              const SizedBox(height: 4),
              _buildNavButton(
                icon: Icons.storage_outlined,
                label: '数据',
                isSelected: _selectedSection == 'data',
                onTap: () => setState(() => _selectedSection = 'data'),
              ),
            ],
          ),
        ),
        // 右侧内容
        Expanded(
          child: _selectedSection == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '请选择左侧菜单',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildSettingsSectionContent(_selectedSection!),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSectionContent(String section) {
    switch (section) {
      case 'security':
        return const _SettingsSecuritySection();
      case 'sync':
        return const _SettingsSyncSection();
      case 'data':
        return const _SettingsDataSection();
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 安全设置部分
class _SettingsSecuritySection extends StatelessWidget {
  const _SettingsSecuritySection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '安全设置',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fingerprint_outlined),
                  title: const Text('生物识别解锁'),
                  subtitle: const Text('使用指纹或面部识别解锁'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('修改主密码'),
                  subtitle: const Text('更改您的访问密码'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('自动锁定时间'),
                  subtitle: const Text('应用自动锁定的时间间隔'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 同步设置部分
class _SettingsSyncSection extends StatelessWidget {
  const _SettingsSyncSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '同步设置',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('启用同步'),
                  subtitle: const Text('在设备间同步加密数据'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('同步配置'),
                  subtitle: const Text('配置同步服务器和认证'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 数据设置部分
class _SettingsDataSection extends StatelessWidget {
  const _SettingsDataSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数据管理',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('数据存储目录'),
                  subtitle: const Text('查看或更改数据存储位置'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('导出备份'),
                  subtitle: const Text('下载加密备份文件'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: const Text('导入备份'),
                  subtitle: const Text('从备份文件恢复数据'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

