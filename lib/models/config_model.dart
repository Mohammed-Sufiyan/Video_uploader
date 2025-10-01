import 'package:json_annotation/json_annotation.dart';

part 'config_model.g.dart';

/// Configuration model for runtime settings
@JsonSerializable()
class ConfigModel {
  final String uploadMode;
  final String s3Endpoint;
  final String bucketName;
  final Map<String, String> cameraFolders;
  final String presignedUrlEndpoint;
  final String? presignedApiKey;
  final List<String> monitorDirectories;
  final List<String> videoExtensions;
  final int maxConcurrentUploads;
  final int maxRetryAttempts;
  final int baseRetryDelay;
  final bool useExponentialBackoff;
  final int uploadTimeoutSeconds;
  final int minFileAgeSeconds;
  final bool showDetailedProgress;
  final int progressUpdateInterval;
  final int backgroundTaskInterval;
  final bool enableDebugLogging;
  final bool requireWifiForUpload;
  final bool requireChargingForUpload;
  final int connectionTimeoutSeconds;
  final int readTimeoutSeconds;

  const ConfigModel({
    required this.uploadMode,
    required this.s3Endpoint,
    required this.bucketName,
    required this.cameraFolders,
    required this.presignedUrlEndpoint,
    this.presignedApiKey,
    required this.monitorDirectories,
    required this.videoExtensions,
    required this.maxConcurrentUploads,
    required this.maxRetryAttempts,
    required this.baseRetryDelay,
    required this.useExponentialBackoff,
    required this.uploadTimeoutSeconds,
    required this.minFileAgeSeconds,
    required this.showDetailedProgress,
    required this.progressUpdateInterval,
    required this.backgroundTaskInterval,
    required this.enableDebugLogging,
    required this.requireWifiForUpload,
    required this.requireChargingForUpload,
    required this.connectionTimeoutSeconds,
    required this.readTimeoutSeconds,
  });

  /// Create ConfigModel from JSON map
  factory ConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ConfigModelFromJson(json);

  /// Convert ConfigModel to JSON map
  Map<String, dynamic> toJson() => _$ConfigModelToJson(this);
}

/// Upload statistics model
@JsonSerializable()
class UploadStats {
  final int totalFiles;
  final int completedFiles;
  final int failedFiles;
  final int queuedFiles;
  final int totalBytes;
  final int uploadedBytes;
  final DateTime? lastUploadTime;
  final Duration totalUploadTime;

  const UploadStats({
    required this.totalFiles,
    required this.completedFiles,
    required this.failedFiles,
    required this.queuedFiles,
    required this.totalBytes,
    required this.uploadedBytes,
    this.lastUploadTime,
    required this.totalUploadTime,
  });

  /// Calculate overall progress percentage
  double get overallProgress {
    if (totalBytes == 0) return 0.0;
    return (uploadedBytes / totalBytes) * 100;
  }

  /// Calculate completion rate
  double get completionRate {
    if (totalFiles == 0) return 0.0;
    return (completedFiles / totalFiles) * 100;
  }

  /// Get formatted total upload time
  String get formattedUploadTime {
    int hours = totalUploadTime.inHours;
    int minutes = totalUploadTime.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Create UploadStats from JSON map
  factory UploadStats.fromJson(Map<String, dynamic> json) =>
      _$UploadStatsFromJson(json);

  /// Convert UploadStats to JSON map
  Map<String, dynamic> toJson() => _$UploadStatsToJson(this);
}
