import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/update/version_info.dart';
import 'package:vaultsafe/core/update/update_service.dart';
import 'package:vaultsafe/core/update/update_downloader.dart';
import 'package:vaultsafe/core/update/update_installer.dart';
import 'package:vaultsafe/core/logging/log_service.dart';

/// 更新状态管理
class UpdateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _updateService = UpdateService();
  final UpdateDownloader _downloader = UpdateDownloader();
  final LogService log = LogService.instance;

  UpdateNotifier() : super(const UpdateState());

  /// 检查更新
  Future<void> checkUpdate() async {
    state = state.copyWith(status: UpdateStatus.checking);

    final result = await _updateService.checkUpdate();

    if (result.hasUpdate && result.updateInfo != null) {
      state = state.copyWith(
        status: result.updateInfo!.forceUpdate
            ? UpdateStatus.available
            : UpdateStatus.available,
        updateInfo: result.updateInfo,
        currentVersion: result.currentVersion,
      );
    } else if (result.error != null) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: result.error,
      );
    } else {
      state = state.copyWith(
        status: UpdateStatus.upToDate,
        currentVersion: result.currentVersion,
      );
    }
  }

  /// 下载更新
  Future<void> downloadUpdate() async {
    if (state.updateInfo == null) return;

    state = state.copyWith(status: UpdateStatus.downloading);

    final result = await _downloader.downloadUpdate(
      state.updateInfo!,
      onProgress: (progress) {
        state = state.copyWith(downloadProgress: progress);
      },
    );

    if (result.success) {
      state = state.copyWith(
        status: UpdateStatus.downloaded,
        downloadPath: result.filePath,
      );
    } else {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: result.error,
      );
    }
  }

  /// 取消下载
  void cancelDownload() {
    _downloader.cancelDownload();
    state = state.copyWith(status: UpdateStatus.cancelled);
  }

  /// 安装更新
  Future<void> installUpdate() async {
    if (state.downloadPath == null) return;

    state = state.copyWith(status: UpdateStatus.installing);

    try {
      final installer = UpdateInstaller();
      final success = await installer.installUpdate(
        state.downloadPath!,
        updateConfig: true, // 安装时自动更新配置
      );

      if (success) {
        state = state.copyWith(status: UpdateStatus.installed);
        log.i('更新安装成功', source: 'UpdateNotifier');
      } else {
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: '安装失败，请手动安装下载的更新文件',
        );
        log.e('更新安装失败', source: 'UpdateNotifier');
      }
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e.toString(),
      );
      log.e('安装更新异常', source: 'UpdateNotifier', error: e);
    }
  }

  /// 重置状态
  void reset() {
    state = const UpdateState();
  }
}

/// 更新状态
class UpdateState {
  final UpdateStatus status;
  final UpdateInfo? updateInfo;
  final AppVersion? currentVersion;
  final DownloadProgress? downloadProgress;
  final String? downloadPath;
  final String? errorMessage;

  const UpdateState({
    this.status = UpdateStatus.upToDate,
    this.updateInfo,
    this.currentVersion,
    this.downloadProgress,
    this.downloadPath,
    this.errorMessage,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateInfo? updateInfo,
    AppVersion? currentVersion,
    DownloadProgress? downloadProgress,
    String? downloadPath,
    String? errorMessage,
  }) {
    return UpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      currentVersion: currentVersion ?? this.currentVersion,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadPath: downloadPath ?? this.downloadPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider
final updateNotifierProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier();
});

/// 更新界面
class UpdateScreen extends ConsumerStatefulWidget {
  const UpdateScreen({super.key});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateNotifierProvider.notifier).checkUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('检查更新'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 当前版本信息
            _buildCurrentVersion(updateState, theme),
            const SizedBox(height: 24),

            // 更新状态
            _buildUpdateStatus(updateState, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentVersion(UpdateState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                '当前版本',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.currentVersion?.toString() ?? '未知版本',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateStatus(UpdateState state, ThemeData theme) {
    switch (state.status) {
      case UpdateStatus.checking:
        return const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在检查更新...'),
            ],
          ),
        );

      case UpdateStatus.upToDate:
        return _buildUpToDateCard(theme);

      case UpdateStatus.available:
        return _buildUpdateAvailableCard(state, theme);

      case UpdateStatus.downloading:
        return _buildDownloadingCard(state, theme);

      case UpdateStatus.downloaded:
        return _buildDownloadedCard(theme);

      case UpdateStatus.installing:
        return const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在安装更新...'),
            ],
          ),
        );

      case UpdateStatus.installed:
        return _buildInstalledCard(theme);

      case UpdateStatus.error:
        return _buildErrorCard(state, theme);

      case UpdateStatus.cancelled:
        return _buildCancelledCard(theme);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUpToDateCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            '已是最新版本',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '您当前使用的是最新版本',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAvailableCard(UpdateState state, ThemeData theme) {
    final updateInfo = state.updateInfo!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.system_update,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '发现新版本',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'v${updateInfo.version}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              updateInfo.changelog,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.read(updateNotifierProvider.notifier).downloadUpdate();
            },
            icon: const Icon(Icons.download),
            label: const Text('下载更新'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingCard(UpdateState state, ThemeData theme) {
    final progress = state.downloadProgress ?? DownloadProgress.initial();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('正在下载更新...'),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress.progress,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text(
            '${(progress.progress * 100).toStringAsFixed(1)}%',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('${progress.speed} - ${progress.remainingTime}'),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              ref.read(updateNotifierProvider.notifier).cancelDownload();
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.download_done,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            '下载完成',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('更新已下载，点击安装'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.read(updateNotifierProvider.notifier).installUpdate();
            },
            icon: const Icon(Icons.install_mobile),
            label: const Text('安装更新'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstalledCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            '更新安装成功',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('请重启应用以完成更新'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(UpdateState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '更新失败',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage ?? '未知错误',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(updateNotifierProvider.notifier).checkUpdate();
                  },
                  child: const Text('重试'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cancel,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            '下载已取消',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
