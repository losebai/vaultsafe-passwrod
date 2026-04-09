import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:vaultsafe/core/security/totp_service.dart';
import 'package:vaultsafe/shared/models/totp_entry.dart';
import 'package:vaultsafe/shared/providers/totp_provider.dart';
import 'package:vaultsafe/features/totp/add_totp_screen.dart';

/// 桌面端添加 TOTP 弹窗
class _AddTotpDialog extends ConsumerStatefulWidget {
  const _AddTotpDialog();

  @override
  ConsumerState<_AddTotpDialog> createState() => _AddTotpDialogState();
}

class _AddTotpDialogState extends ConsumerState<_AddTotpDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _accountController = TextEditingController();
  final _secretController = TextEditingController();
  final _uriController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isQrLoading = false;
  String? _qrError;
  String? _qrPreviewPath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _issuerController.dispose();
    _accountController.dispose();
    _secretController.dispose();
    _uriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Text('添加验证器'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '二维码', icon: Icon(Icons.qr_code, size: 18)),
                Tab(text: '手动输入', icon: Icon(Icons.edit, size: 18)),
                Tab(text: '粘贴链接', icon: Icon(Icons.link, size: 18)),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQrTab(theme),
                  _buildManualTab(theme),
                  _buildUriTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isQrLoading ? null : _pickQrImage,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('上传图片'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isQrLoading ? null : _pasteQrFromClipboard,
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('粘贴截图'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 预览/状态区域
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: _isQrLoading
                  ? const CircularProgressIndicator()
                  : _qrError != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 40, color: theme.colorScheme.error),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _qrError!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : _qrPreviewPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_qrPreviewPath!),
                                height: 160,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner,
                                    size: 48,
                                    color: theme.colorScheme.outline),
                                const SizedBox(height: 8),
                                Text(
                                  '上传二维码图片或粘贴截图',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab(ThemeData theme) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _issuerController,
              decoration: const InputDecoration(
                labelText: '发行者（可选）',
                hintText: '例如：Google、GitHub',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: '账户',
                hintText: '例如：user@example.com',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return '请输入账户';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _secretController,
              decoration: const InputDecoration(
                labelText: '密钥（Secret Key）',
                hintText: 'Base32 编码的密钥',
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return '请输入密钥';
                final clean =
                    value.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
                if (clean.length < 16) return '密钥长度不足（至少16个字符）';
                return null;
              },
              onChanged: (value) {
                final upper = value.toUpperCase();
                if (upper != value) {
                  _secretController.value = TextEditingValue(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _addManual,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUriTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _uriController,
            decoration: InputDecoration(
              labelText: 'otpauth:// 链接',
              hintText: 'otpauth://totp/...',
              prefixIcon: const Icon(Icons.link),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste),
                tooltip: '从剪贴板粘贴',
                onPressed: _pasteFromClipboard,
              ),
            ),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _addFromUri,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('添加'),
          ),
        ],
      ),
    );
  }

  // ============ QR Code Methods ============

  Future<void> _pickQrImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    setState(() {
      _qrPreviewPath = filePath;
      _qrError = null;
      _isQrLoading = true;
    });

    try {
      final bytes = await File(filePath).readAsBytes();
      await _decodeQrBytes(bytes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrError = '读取图片失败: $e';
          _isQrLoading = false;
        });
      }
    }
  }

  Future<void> _pasteQrFromClipboard() async {
    setState(() {
      _qrError = null;
      _isQrLoading = true;
      _qrPreviewPath = null;
    });

    try {
      final bytes = await Pasteboard.image;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          setState(() {
            _qrError = '剪贴板中没有图片';
            _isQrLoading = false;
          });
        }
        return;
      }
      await _decodeQrBytes(bytes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrError = '读取剪贴板失败: $e';
          _isQrLoading = false;
        });
      }
    }
  }

  Future<void> _decodeQrBytes(Uint8List imageBytes) async {
    try {
      final decoder = QrCodeDartDecoder(
        formats: [BarcodeFormat.qrCode],
      );
      final result = await decoder.decodeFile(imageBytes);

      if (result == null || result.text.isEmpty) {
        if (mounted) {
          setState(() {
            _qrError = '未能在图片中识别到二维码';
            _isQrLoading = false;
          });
        }
        return;
      }

      final text = result.text.trim();

      if (!text.startsWith('otpauth://')) {
        if (mounted) {
          setState(() {
            _qrError =
                '二维码内容不是有效的验证器链接\n识别内容: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}';
            _isQrLoading = false;
          });
        }
        return;
      }

      // 解析成功，添加 TOTP
      final success =
          await ref.read(totpEntriesProvider.notifier).addFromUri(text);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _qrError = '无法解析此二维码，请检查是否为双重验证二维码';
            _isQrLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrError = '二维码解析失败: $e';
          _isQrLoading = false;
        });
      }
    }
  }

  // ============ Other Methods ============

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _uriController.text = data!.text!;
    }
  }

  Future<void> _addManual() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _issuerController.text.isNotEmpty
          ? _issuerController.text
          : _accountController.text;

      await ref.read(totpEntriesProvider.notifier).addManual(
            name: name,
            account: _accountController.text,
            secret: _secretController.text,
            issuer: _issuerController.text,
          );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addFromUri() async {
    final uri = _uriController.text.trim();
    if (uri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 otpauth:// 链接')),
      );
      return;
    }
    if (!uri.startsWith('otpauth://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无效的链接格式，应以 otpauth:// 开头')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success =
          await ref.read(totpEntriesProvider.notifier).addFromUri(uri);
      if (success) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法解析此链接，请检查格式')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// TOTP 双重因子验证页面
class TotpScreen extends ConsumerStatefulWidget {
  const TotpScreen({super.key});

  @override
  ConsumerState<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends ConsumerState<TotpScreen> {
  Timer? _refreshTimer;
  bool _isRightPanelOpen = false;
  TotpEntry? _selectedEntry;

  bool get _isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    Future.microtask(() => ref.read(totpEntriesProvider.notifier).loadEntries());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(totpEntriesProvider);

    // 桌面端布局：左列表 + 右详情面板
    if (_isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // 主内容区域
            Expanded(
              child: Column(
                children: [
                  _buildDesktopToolbar(theme),
                  Expanded(
                    child: entriesAsync.when(
                      data: (entries) {
                        if (entries.isEmpty) return _buildEmptyState(theme);
                        return _buildDesktopGrid(entries);
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('加载失败: $err')),
                    ),
                  ),
                ],
              ),
            ),
            // 右侧详情面板
            _buildRightPanel(theme),
          ],
        ),
      );
    }

    // 移动端布局
    return Scaffold(
      appBar: AppBar(
        title: const Text('双重因子验证'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAdd(),
            tooltip: '添加验证器',
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) return _buildEmptyState(theme);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) => _buildTotpCard(entries[index], theme),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
      ),
    );
  }

  // 桌面端顶部工具栏
  Widget _buildDesktopToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
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
            '双重因子验证',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 0, 72, 120),
            ),
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: () => _navigateToAdd(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加验证器'),
          ),
        ],
      ),
    );
  }

  // 桌面端网格列表
  Widget _buildDesktopGrid(List<TotpEntry> entries) {
    const double cardWidth = 250;
    const double cardHeight = 70;
    const double spacing = 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(5),
            child: SizedBox(
              width: constraints.maxWidth,
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: spacing,
                runSpacing: spacing,
                children: entries.map((entry) {
                  final isSelected = _selectedEntry?.id == entry.id;
                  return SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: GestureDetector(
                      onTap: () => _openDetail(entry),
                      child: _buildGridCard(entry, isSelected),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  // 桌面端网格卡片（简洁版，与密码页面一致）
  Widget _buildGridCard(TotpEntry entry, bool isSelected) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // 图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  entry.issuer.isNotEmpty ? entry.issuer[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 名称
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.issuer.isNotEmpty ? entry.issuer : entry.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    entry.account,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 右侧详情面板
  Widget _buildRightPanel(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isRightPanelOpen ? 400 : 0,
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
      child: _isRightPanelOpen && _selectedEntry != null
          ? ClipRect(
              child: _buildDetailContent(theme),
            )
          : null,
    );
  }

  // 右侧面板详情内容
  Widget _buildDetailContent(ThemeData theme) {
    final entry = _selectedEntry!;
    final code = TotpService.generateCode(entry);
    final remaining = TotpService.getRemainingSeconds(period: entry.period);
    final progress = TotpService.getProgress(period: entry.period);
    final isExpiring = remaining <= 5;

    return Column(
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
              Icon(Icons.phonelink_lock, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                '验证器详情',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _closeRightPanel(),
                tooltip: '关闭',
              ),
            ],
          ),
        ),
        // 详情内容
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 发行者图标和名称
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            entry.issuer.isNotEmpty ? entry.issuer[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        entry.issuer.isNotEmpty ? entry.issuer : entry.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.account,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 验证码
                Center(
                  child: GestureDetector(
                    onTap: () => _copyCode(code, entry),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatCode(code),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 4,
                              color: isExpiring ? theme.colorScheme.error : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.copy, size: 22, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 进度条和倒计时
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isExpiring ? theme.colorScheme.error : theme.colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${remaining}s',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isExpiring ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 信息卡片
                _buildInfoRow(theme, Icons.business, '发行者', entry.issuer.isNotEmpty ? entry.issuer : '-'),
                const SizedBox(height: 8),
                _buildInfoRow(theme, Icons.person, '账户', entry.account),
                const SizedBox(height: 8),
                _buildInfoRow(theme, Icons.timer, '周期', '${entry.period} 秒'),
                const SizedBox(height: 8),
                _buildInfoRow(theme, Icons.dialpad, '位数', '${entry.digits} 位'),
                const SizedBox(height: 8),
                _buildInfoRow(theme, Icons.tag, '算法', entry.algorithm),
                const SizedBox(height: 24),

                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _copyCode(code, entry),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('复制验证码'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(entry),
                        icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                        label: Text('删除验证器', style: TextStyle(color: theme.colorScheme.error)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(TotpEntry entry) {
    setState(() {
      _selectedEntry = entry;
      _isRightPanelOpen = true;
    });
  }

  void _closeRightPanel() {
    setState(() {
      _isRightPanelOpen = false;
      _selectedEntry = null;
    });
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phonelink_lock, size: 72, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('暂无验证器', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _isDesktop ? '点击上方按钮添加双重因子验证' : '点击右上角 + 添加双重因子验证',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!_isDesktop) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _navigateToAdd(),
              icon: const Icon(Icons.add),
              label: const Text('添加验证器'),
            ),
          ],
        ],
      ),
    );
  }

  // 移动端 TOTP 卡片
  Widget _buildTotpCard(TotpEntry entry, ThemeData theme) {
    final code = TotpService.generateCode(entry);
    final remaining = TotpService.getRemainingSeconds(period: entry.period);
    final progress = TotpService.getProgress(period: entry.period);
    final isExpiring = remaining <= 5;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 头部
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      entry.issuer.isNotEmpty ? entry.issuer[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.issuer.isNotEmpty ? entry.issuer : entry.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        entry.account,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(entry),
                  tooltip: '删除',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 验证码
            GestureDetector(
              onTap: () => _copyCode(code, entry),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatCode(code),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                      color: isExpiring ? theme.colorScheme.error : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.copy, size: 20, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 进度条
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isExpiring ? theme.colorScheme.error : theme.colorScheme.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$remaining',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isExpiring ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    } else if (code.length == 8) {
      return '${code.substring(0, 4)} ${code.substring(4)}';
    }
    return code;
  }

  void _copyCode(String code, TotpEntry entry) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制 ${entry.issuer.isNotEmpty ? entry.issuer : entry.name} 的验证码'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToAdd() async {
    bool? result;
    if (_isDesktop) {
      result = await showDialog<bool>(
        context: context,
        builder: (context) => const _AddTotpDialog(),
      );
    } else {
      result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AddTotpScreen()),
      );
    }
    if (result == true) {
      ref.read(totpEntriesProvider.notifier).loadEntries();
    }
  }

  void _confirmDelete(TotpEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除验证器'),
        content: Text('确定要删除 ${entry.issuer.isNotEmpty ? entry.issuer : entry.name} 的验证器吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(totpEntriesProvider.notifier).deleteEntry(entry.id);
              if (_selectedEntry?.id == entry.id) {
                _closeRightPanel();
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
}
