import 'package:flutter/material.dart';

// 显示 API 帮助文档弹窗
void showApiHelpDialog(BuildContext context) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.code,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'REST API 文档',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 说明文字
            Text(
              '您的同步服务器需要实现以下 REST API 接口。所有数据均为 AES-256-GCM 加密后的密文。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // API 文档内容
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // POST /sync - 上传数据
                    _buildApiSection(
                      theme: theme,
                      method: 'POST',
                      endpoint: '/sync',
                      title: '上传加密数据',
                      description: '将本地加密数据上传到服务器',
                      code:
                          '''curl -X POST https://your-server.com/api/v1/sync \\
  -H "Authorization: Bearer YOUR_TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{
    "device_id": "uuid-string",
    "timestamp": 1705742400,
    "encrypted_data": "base64_encrypted_blob",
    "version": "1.0"
  }"

响应示例:
{
  "success": true,
  "message": "Data uploaded successfully"
}''',
                    ),
                    const SizedBox(height: 24),

                    // GET /sync - 下载数据
                    _buildApiSection(
                      theme: theme,
                      method: 'GET',
                      endpoint: '/sync',
                      title: '下载加密数据',
                      description: '从服务器获取最新的加密数据',
                      code:
                          '''curl -X GET https://your-server.com/api/v1/sync \\
  -H "Authorization: Bearer YOUR_TOKEN"

响应示例:
{
  "device_id": "other-device-id",
  "timestamp": 1705742500,
  "encrypted_data": "base64_encrypted_blob",
  "version": "1.0"
}''',
                    ),
                    const SizedBox(height: 24),

                    // 认证方式说明
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '认证说明',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Bearer Token: 在请求头中添加 Authorization: Bearer <token>\n'
                            '• Basic Auth: 在请求头中添加 Authorization: Basic <base64(username:password)>\n'
                            '• 自定义: 使用自定义请求头进行认证',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 数据格式说明
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '数据格式',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• device_id: 设备唯一标识符（UUID）\n'
                            '• timestamp: Unix 时间戳（秒）\n'
                            '• encrypted_data: Base64 编码的加密数据\n'
                            '• version: 数据版本号（当前为 "1.0"）',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildApiSection({
  required ThemeData theme,
  required String method,
  required String endpoint,
  required String title,
  required String description,
  required String code,
}) {
  final methodColor =
      method == 'POST' ? const Color(0xFF4CAF50) : const Color(0xFF2196F3);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 方法标签和端点
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: methodColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              method,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            endpoint,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),

      // 标题和描述
      Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),

      // 代码块
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(
          code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFFD4D4D4),
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}
