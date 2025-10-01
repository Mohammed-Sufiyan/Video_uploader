import 'package:json_annotation/json_annotation.dart';

part 'upload_task.g.dart';

/// Represents the status of an upload task
enum UploadStatus {
  queued,
  uploading,
  completed,
  failed,
  paused,
  cancelled,
}

/// Represents an upload task for a video file
@JsonSerializable()
class UploadTask {
  final String id;
  final String filePath;
  final String fileName;
  final String cameraFolder;
  final String destinationPath;
  final int fileSize;
  final DateTime createdAt;

  UploadStatus status;
  double progress;
  int retryCount;
  String? errorMessage;
  DateTime? completedAt;
  DateTime? lastAttemptAt;

  UploadTask({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.cameraFolder,
    required this.destinationPath,
    required this.fileSize,
    required this.createdAt,
    this.status = UploadStatus.queued,
    this.progress = 0.0,
    this.retryCount = 0,
    this.errorMessage,
    this.completedAt,
    this.lastAttemptAt,
  });

  /// Create a copy of this task with updated fields
  UploadTask copyWith({
    UploadStatus? status,
    double? progress,
    int? retryCount,
    String? errorMessage,
    DateTime? completedAt,
    DateTime? lastAttemptAt,
  }) {
    return UploadTask(
      id: id,
      filePath: filePath,
      fileName: fileName,
      cameraFolder: cameraFolder,
      destinationPath: destinationPath,
      fileSize: fileSize,
      createdAt: createdAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      completedAt: completedAt ?? this.completedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  /// Check if task can be retried
  bool get canRetry => status == UploadStatus.failed && retryCount < 3;

  /// Check if task is in progress
  bool get isInProgress => status == UploadStatus.uploading;

  /// Check if task is completed successfully
  bool get isCompleted => status == UploadStatus.completed;

  /// Check if task has failed
  bool get hasFailed => status == UploadStatus.failed;

  /// Get status display text
  String get statusText {
    switch (status) {
      case UploadStatus.queued:
        return 'Queued';
      case UploadStatus.uploading:
        return 'Uploading';
      case UploadStatus.completed:
        return 'Completed';
      case UploadStatus.failed:
        return 'Failed';
      case UploadStatus.paused:
        return 'Paused';
      case UploadStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get progress text
  String get progressText {
    if (isCompleted) return '100%';
    return '${progress.toStringAsFixed(1)}%';
  }

  /// Get file size text
  String get fileSizeText {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    if (fileSize < 1024 * 1024 * 1024)
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// JSON serialization support
  factory UploadTask.fromJson(Map<String, dynamic> json) =>
      _$UploadTaskFromJson(json);
  Map<String, dynamic> toJson() => _$UploadTaskToJson(this);

  @override
  String toString() {
    return 'UploadTask(id: $id, fileName: $fileName, status: $status, progress: $progress%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UploadTask && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Extension methods for UploadStatus to provide UI utilities
extension UploadStatusExtension on UploadStatus {
  /// Get color to use in UI for a status
  int get colorValue {
    switch (this) {
      case UploadStatus.queued:
        return 0xFF9E9E9E; // Grey
      case UploadStatus.uploading:
        return 0xFF2196F3; // Blue
      case UploadStatus.completed:
        return 0xFF4CAF50; // Green
      case UploadStatus.failed:
        return 0xFFF44336; // Red
      case UploadStatus.paused:
        return 0xFFFF9800; // Orange
      case UploadStatus.cancelled:
        return 0xFF795548; // Brown
    }
  }

  /// Check if status is currently active (uploading)
  bool get isActive => this == UploadStatus.uploading;

  /// Check if status means task is done (success/failure/cancelled)
  bool get isTerminal =>
      this == UploadStatus.completed ||
      this == UploadStatus.failed ||
      this == UploadStatus.cancelled;
}
