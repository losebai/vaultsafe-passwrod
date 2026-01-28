import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:vaultsafe/core/update/version_info.dart';
import 'package:vaultsafe/core/logging/log_service.dart';

/// 下载管理器
class UpdateDownloader {
  final LogService log = LogService.instance;
  final Dio _dio = Dio();

  UpdateDownloader() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 300);
  }

  CancelToken? _cancelToken;
  bool _isDownloading = false;

  bool get isDownloading => _isDownloading;

  /// 下载更新
  Future<DownloadResult> downloadUpdate(
    UpdateInfo updateInfo, {
    Function(DownloadProgress)? onProgress,
  }) async {
    try {
      _isDownloading = true;
      _cancelToken = CancelToken();
      log.i('开始下载更新: ${updateInfo.version}', source: 'UpdateDownloader');

      final directory = await _getDownloadDirectory();
      final fileName = _getFileName(updateInfo.downloadUrl);
      final savePath = path.join(directory.path, fileName);

      log.i('保存路径: $savePath', source: 'UpdateDownloader');

      await _dio.download(
        updateInfo.downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = DownloadProgress(
              downloaded: received,
              total: total,
              progress: received / total,
              speed: _formatSpeed(received),
              remainingTime: _calculateRemainingTime(received, total),
            );
            onProgress?.call(progress);
          }
        },
      );

      final file = File(savePath);
      if (!await file.exists()) {
        throw Exception('下载失败：文件不存在');
      }

      // 验证文件大小
      final fileSize = await file.length();
      if (updateInfo.fileSize > 0 && fileSize != updateInfo.fileSize) {
        throw Exception('下载失败：文件大小不匹配');
      }

      // TODO: 验证 MD5 校验和
      // if (updateInfo.md5Checksum != null) {
      //   await _verifyMd5(file, updateInfo.md5Checksum!);
      // }

      log.i('下载完成: $savePath', source: 'UpdateDownloader');

      return DownloadResult(
        success: true,
        filePath: savePath,
        fileName: fileName,
      );
    } catch (e, st) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        log.i('下载已取消', source: 'UpdateDownloader');
        return const DownloadResult(
          success: false,
          error: '下载已取消',
        );
      }

      log.e('下载失败', source: 'UpdateDownloader', error: e, stackTrace: st);
      return DownloadResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isDownloading = false;
      _cancelToken = null;
    }
  }

  /// 取消下载
  void cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('用户取消下载');
    }
  }

  /// 获取下载目录
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final tempDir = await getTemporaryDirectory();
      final updateDir = Directory(path.join(tempDir.path, 'updates'));
      if (!await updateDir.exists()) {
        await updateDir.create(recursive: true);
      }
      return updateDir;
    }
    return await getTemporaryDirectory();
  }

  /// 从 URL 获取文件名
  String _getFileName(String url) {
    return path.basename(url);
  }

  /// 格式化速度
  String _formatSpeed(int downloaded) {
    // 简化处理，实际应该根据时间计算
    final speedInKB = downloaded / 1024;
    if (speedInKB < 1024) {
      return '${speedInKB.toStringAsFixed(1)} KB/s';
    }
    return '${(speedInKB / 1024).toStringAsFixed(1)} MB/s';
  }

  /// 计算剩余时间
  String _calculateRemainingTime(int received, int total) {
    if (received == 0) return '计算中...';

    final remaining = total - received;
    final percent = received / total;

    if (percent <= 0) return '计算中...';

    // 简化处理，实际应该基于下载速度计算
    final seconds = (remaining / received * 10).ceil();
    if (seconds < 60) {
      return '$seconds 秒';
    }
    final minutes = (seconds / 60).ceil();
    return '$minutes 分钟';
  }
}

/// 下载结果
class DownloadResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final String? error;

  const DownloadResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.error,
  });
}
