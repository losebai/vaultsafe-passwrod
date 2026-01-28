/// 版本信息模型
class AppVersion {
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;

  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
  });

  factory AppVersion.fromString(String version) {
    final parts = version.split('-');
    final versionPart = parts[0];
    final preRelease = parts.length > 1 ? parts[1] : null;

    final numbers = versionPart.split('.').map(int.parse).toList();
    return AppVersion(
      major: numbers[0],
      minor: numbers.length > 1 ? numbers[1] : 0,
      patch: numbers.length > 2 ? numbers[2] : 0,
      preRelease: preRelease,
    );
  }

  @override
  String toString() {
    final version = '$major.$minor.$patch';
    return preRelease != null ? '$version-$preRelease' : version;
  }

  bool operator >(other) {
    if (major != other.major) return major > other.major;
    if (minor != other.minor) return minor > other.minor;
    if (patch != other.patch) return patch > other.patch;
    return false;
  }

  bool operator >=(other) => this > other || this == other;

  bool operator <(other) => other > this;

  bool operator <=(other) => other > this || this == other;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppVersion &&
        other.major == major &&
        other.minor == minor &&
        other.patch == patch &&
        other.preRelease == preRelease;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);
}

/// 更新类型
enum UpdateType {
  /// 应用更新
  app,

  /// 数据更新
  data,

  /// 两者都有
  both,
}

/// 更新信息
class UpdateInfo {
  final String version;
  final AppVersion parsedVersion;
  final UpdateType type;
  final String changelog;
  final String downloadUrl;
  final int fileSize;
  final String? md5Checksum;
  final bool forceUpdate;
  final DateTime releaseDate;

  UpdateInfo({
    required this.version,
    required this.type,
    required this.changelog,
    required this.downloadUrl,
    required this.fileSize,
    this.md5Checksum,
    this.forceUpdate = false,
    required this.releaseDate,
  }) : parsedVersion = AppVersion.fromString(version);

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String,
      type: UpdateType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => UpdateType.app,
      ),
      changelog: json['changelog'] as String,
      downloadUrl: json['downloadUrl'] as String,
      fileSize: json['fileSize'] as int,
      md5Checksum: json['md5Checksum'] as String?,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'type': type.name,
      'changelog': changelog,
      'downloadUrl': downloadUrl,
      'fileSize': fileSize,
      'md5Checksum': md5Checksum,
      'forceUpdate': forceUpdate,
      'releaseDate': releaseDate.toIso8601String(),
    };
  }
}

/// 下载进度信息
class DownloadProgress {
  final int downloaded;
  final int total;
  final double progress;
  final String speed;
  final String remainingTime;

  const DownloadProgress({
    required this.downloaded,
    required this.total,
    required this.progress,
    required this.speed,
    required this.remainingTime,
  });

  factory DownloadProgress.initial() {
    return const DownloadProgress(
      downloaded: 0,
      total: 100,
      progress: 0,
      speed: '0 KB/s',
      remainingTime: '计算中...',
    );
  }

  DownloadProgress copyWith({
    int? downloaded,
    int? total,
    double? progress,
    String? speed,
    String? remainingTime,
  }) {
    return DownloadProgress(
      downloaded: downloaded ?? this.downloaded,
      total: total ?? this.total,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }
}

/// 更新状态
enum UpdateStatus {
  /// 检查中
  checking,

  /// 无更新
  upToDate,

  /// 有可用更新
  available,

  /// 下载中
  downloading,

  /// 下载完成
  downloaded,

  /// 安装中
  installing,

  /// 已安装
  installed,

  /// 错误
  error,

  /// 已取消
  cancelled,
}
