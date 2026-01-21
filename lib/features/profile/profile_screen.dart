import 'package:flutter/material.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';

/// 个人中心界面
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VaultSafe 用户',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '本地加密存储',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 统计信息
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '统计',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.password),
                  title: Text('密码总数'),
                  trailing: Text('0'), // TODO: 获取实际数量
                ),
                const ListTile(
                  leading: Icon(Icons.folder),
                  title: Text('分组'),
                  trailing: Text('0'),
                ),
                const ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('加密方式'),
                  trailing: Text('AES-256-GCM'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 安全信息
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '安全',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.verified_user),
                  title: Text('零知识架构'),
                  subtitle: Text('您的数据永远不会以未加密形式离开此设备'),
                ),
                const ListTile(
                  leading: Icon(Icons.enhanced_encryption),
                  title: Text('端到端加密'),
                  subtitle: Text('所有数据使用您的主密码加密'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 应用信息
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '关于',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const ListTile(
                  title: Text('版本'),
                  trailing: Text('1.0.0'),
                ),
                const ListTile(
                  title: Text('许可证'),
                  trailing: Text('MIT'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
