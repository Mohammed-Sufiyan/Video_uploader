// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigModel _$ConfigModelFromJson(Map<String, dynamic> json) => ConfigModel(
      uploadMode: json['uploadMode'] as String,
      s3Endpoint: json['s3Endpoint'] as String,
      bucketName: json['bucketName'] as String,
      cameraFolders: Map<String, String>.from(json['cameraFolders'] as Map),
      presignedUrlEndpoint: json['presignedUrlEndpoint'] as String,
      presignedApiKey: json['presignedApiKey'] as String?,
      monitorDirectories: (json['monitorDirectories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      videoExtensions: (json['videoExtensions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      maxConcurrentUploads: (json['maxConcurrentUploads'] as num).toInt(),
      maxRetryAttempts: (json['maxRetryAttempts'] as num).toInt(),
      baseRetryDelay: (json['baseRetryDelay'] as num).toInt(),
      useExponentialBackoff: json['useExponentialBackoff'] as bool,
      uploadTimeoutSeconds: (json['uploadTimeoutSeconds'] as num).toInt(),
      minFileAgeSeconds: (json['minFileAgeSeconds'] as num).toInt(),
      showDetailedProgress: json['showDetailedProgress'] as bool,
      progressUpdateInterval: (json['progressUpdateInterval'] as num).toInt(),
      backgroundTaskInterval: (json['backgroundTaskInterval'] as num).toInt(),
      enableDebugLogging: json['enableDebugLogging'] as bool,
      requireWifiForUpload: json['requireWifiForUpload'] as bool,
      requireChargingForUpload: json['requireChargingForUpload'] as bool,
      connectionTimeoutSeconds:
          (json['connectionTimeoutSeconds'] as num).toInt(),
      readTimeoutSeconds: (json['readTimeoutSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$ConfigModelToJson(ConfigModel instance) =>
    <String, dynamic>{
      'uploadMode': instance.uploadMode,
      's3Endpoint': instance.s3Endpoint,
      'bucketName': instance.bucketName,
      'cameraFolders': instance.cameraFolders,
      'presignedUrlEndpoint': instance.presignedUrlEndpoint,
      'presignedApiKey': instance.presignedApiKey,
      'monitorDirectories': instance.monitorDirectories,
      'videoExtensions': instance.videoExtensions,
      'maxConcurrentUploads': instance.maxConcurrentUploads,
      'maxRetryAttempts': instance.maxRetryAttempts,
      'baseRetryDelay': instance.baseRetryDelay,
      'useExponentialBackoff': instance.useExponentialBackoff,
      'uploadTimeoutSeconds': instance.uploadTimeoutSeconds,
      'minFileAgeSeconds': instance.minFileAgeSeconds,
      'showDetailedProgress': instance.showDetailedProgress,
      'progressUpdateInterval': instance.progressUpdateInterval,
      'backgroundTaskInterval': instance.backgroundTaskInterval,
      'enableDebugLogging': instance.enableDebugLogging,
      'requireWifiForUpload': instance.requireWifiForUpload,
      'requireChargingForUpload': instance.requireChargingForUpload,
      'connectionTimeoutSeconds': instance.connectionTimeoutSeconds,
      'readTimeoutSeconds': instance.readTimeoutSeconds,
    };

UploadStats _$UploadStatsFromJson(Map<String, dynamic> json) => UploadStats(
      totalFiles: (json['totalFiles'] as num).toInt(),
      completedFiles: (json['completedFiles'] as num).toInt(),
      failedFiles: (json['failedFiles'] as num).toInt(),
      queuedFiles: (json['queuedFiles'] as num).toInt(),
      totalBytes: (json['totalBytes'] as num).toInt(),
      uploadedBytes: (json['uploadedBytes'] as num).toInt(),
      lastUploadTime: json['lastUploadTime'] == null
          ? null
          : DateTime.parse(json['lastUploadTime'] as String),
      totalUploadTime:
          Duration(microseconds: (json['totalUploadTime'] as num).toInt()),
    );

Map<String, dynamic> _$UploadStatsToJson(UploadStats instance) =>
    <String, dynamic>{
      'totalFiles': instance.totalFiles,
      'completedFiles': instance.completedFiles,
      'failedFiles': instance.failedFiles,
      'queuedFiles': instance.queuedFiles,
      'totalBytes': instance.totalBytes,
      'uploadedBytes': instance.uploadedBytes,
      'lastUploadTime': instance.lastUploadTime?.toIso8601String(),
      'totalUploadTime': instance.totalUploadTime.inMicroseconds,
    };
