import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:vaultsafe/shared/providers/totp_provider.dart';

/// 添加 TOTP 验证器页面
class AddTotpScreen extends ConsumerStatefulWidget {
  const AddTotpScreen({super.key});

  @override
  ConsumerState<AddTotpScreen> createState() => _AddTotpScreenState();
}

class _AddTotpScreenState extends ConsumerState<AddTotpScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 手动输入的控制器
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _accountController = TextEditingController();
  final _secretController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 扫码输入的控制器
  final _uriController = TextEditingController();

  // QR 状态
  bool _isLoading = false;
  bool _isQrLoading = false;
  String? _qrError;
  String? _qrPreviewPath;

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加验证器'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: '二维码', icon: Icon(Icons.qr_code)),
            Tab(text: '手动输入', icon: const Icon(Icons.edit)),
            Tab(text: '粘贴链接', icon: const Icon(Icons.link)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 二维码
          _buildQrTab(theme),
          // 手动输入
          _buildManualTab(theme),
          // 粘贴链接
          _buildUriTab(theme),
        ],
      ),
    );
  }

  Widget _buildQrTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 提示信息
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '上传包含二维码的图片，或将截图粘贴到此处，自动识别双重验证二维码。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

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
            if (_isDesktop) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isQrLoading ? null : _pasteQrFromClipboard,
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('粘贴截图'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),

        // 预览区域
        if (_qrPreviewPath != null || _isQrLoading || _qrError != null)
          Container(
            height: 200,
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
                                size: 48, color: theme.colorScheme.error),
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
                                height: 180,
                                fit: BoxFit.contain,
                              ),
                            )
                          : null,
            ),
          ),
      ],
    );
  }

  Widget _buildManualTab(ThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 发行者
          TextFormField(
            controller: _issuerController,
            decoration: const InputDecoration(
              labelText: '发行者（可选）',
              hintText: '例如：Google、GitHub',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // 账户
          TextFormField(
            controller: _accountController,
            decoration: const InputDecoration(
              labelText: '账户',
              hintText: '例如：user@example.com',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入账户';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 密钥
          TextFormField(
            controller: _secretController,
            decoration: const InputDecoration(
              labelText: '密钥（Secret Key）',
              hintText: 'Base32 编码的密钥',
              prefixIcon: Icon(Icons.key),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入密钥';
              }
              // 验证 Base32 格式
              final clean = value
                  .toUpperCase()
                  .replaceAll(RegExp(r'[^A-Z2-7]'), '');
              if (clean.length < 16) {
                return '密钥长度不足（至少16个字符）';
              }
              return null;
            },
            onChanged: (value) {
              // 自动转大写
              final upper = value.toUpperCase();
              if (upper != value) {
                _secretController.value = TextEditingValue(
                  text: upper,
                  selection: TextSelection.collapsed(offset: upper.length),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // 提示信息
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '在启用双重验证时，服务商通常会显示一串密钥。将密钥输入上方即可。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 添加按钮
          FilledButton(
            onPressed: _isLoading ? null : _addManual,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildUriTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 提示信息
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '粘贴服务商提供的 otpauth:// 链接，通常在启用双重验证时可以获取。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // URI 输入
        TextFormField(
          controller: _uriController,
          decoration: InputDecoration(
            labelText: 'otpauth:// 链接',
            hintText: 'otpauth://totp/...',
            prefixIcon: const Icon(Icons.link),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.paste),
              tooltip: '从剪贴板粘贴',
              onPressed: _pasteFromClipboard,
            ),
          ),
          maxLines: 3,
          minLines: 1,
        ),
        const SizedBox(height: 24),

        // 添加按钮
        FilledButton(
          onPressed: _isLoading ? null : _addFromUri,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('添加'),
        ),
      ],
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
            _qrError = '二维码内容不是有效的验证器链接\n识别内容: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}';
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

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        if (mounted) {
          Navigator.of(context).pop(true);
        }
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
