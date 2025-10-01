// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadTask _$UploadTaskFromJson(Map<String, dynamic> json) => UploadTask(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      cameraFolder: json['cameraFolder'] as String,
      destinationPath: json['destinationPath'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: $enumDecodeNullable(_$UploadStatusEnumMap, json['status']) ??
          UploadStatus.queued,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt'] as String),
    );

Map<String, dynamic> _$UploadTaskToJson(UploadTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'filePath': instance.filePath,
      'fileName': instance.fileName,
      'cameraFolder': instance.cameraFolder,
      'destinationPath': instance.destinationPath,
      'fileSize': instance.fileSize,
      'createdAt': instance.createdAt.toIso8601String(),
      'status': _$UploadStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'retryCount': instance.retryCount,
      'errorMessage': instance.errorMessage,
      'completedAt': instance.completedAt?.toIso8601String(),
      'lastAttemptAt': instance.lastAttemptAt?.toIso8601String(),
    };

const _$UploadStatusEnumMap = {
  UploadStatus.queued: 'queued',
  UploadStatus.uploading: 'uploading',
  UploadStatus.completed: 'completed',
  UploadStatus.failed: 'failed',
  UploadStatus.paused: 'paused',
  UploadStatus.cancelled: 'cancelled',
};
