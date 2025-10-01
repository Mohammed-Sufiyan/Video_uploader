import 'dart:io';
import 'dart:isolate';
import 'package:workmanager/workmanager.dart';
import '../config.dart';
import '../services/file_monitor_service.dart';
import '../services/queue_manager.dart';
import '../services/notification_service.dart';
import '../services/upload_service.dart';
import '../models/upload_task.dart';
import '../utils/file_utils.dart';

/// Background service for continuous file monitoring and uploads
class BackgroundService {
  static BackgroundService? _instance;
  static BackgroundService get instance => _instance ??= BackgroundService._();

  BackgroundService._();

  /// Initialize and register background tasks
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: AppConfig.enableDebugLogging,
      );

      await _registerBackgroundTasks();
      print('Background service initialized');
    } catch (e) {
      print('Error initializing background service: $e');
    }
  }

  /// Register periodic background tasks
  static Future<void> _registerBackgroundTasks() async {
    try {
      // Cancel existing tasks
      await Workmanager().cancelAll();

      // Register periodic task for file monitoring and uploads
      await Workmanager().registerPeriodicTask(
        AppConfig.workManagerTaskId,
        AppConfig.workManagerTaskId,
        frequency: Duration(minutes: AppConfig.backgroundTaskInterval),
        constraints: Constraints(
          networkType: AppConfig.requireWifiForUpload
              ? NetworkType.unmetered
              : NetworkType.connected,
          requiresCharging: AppConfig.requireChargingForUpload,
          requiresBatteryNotLow: true,
        ),
        inputData: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'config': AppConfig.enableDebugLogging,
        },
      );

      print('Background task registered: ${AppConfig.workManagerTaskId}');
    } catch (e) {
      print('Error registering background tasks: $e');
    }
  }

  /// Start foreground monitoring (when app is active)
  Future<void> startForegroundService() async {
    try {
      await NotificationService.initialize();
      await FileMonitorService.instance.startMonitoring();

      // Show persistent notification
      await NotificationService.showServiceStatus(
        status: 'Active',
        totalFiles: 0,
        completedFiles: 0,
        failedFiles: 0,
      );

      print('Foreground service started');
    } catch (e) {
      print('Error starting foreground service: $e');
    }
  }

  /// Stop foreground monitoring
  Future<void> stopForegroundService() async {
    try {
      await FileMonitorService.instance.stopMonitoring();
      await NotificationService.clearAllNotifications();
      print('Foreground service stopped');
    } catch (e) {
      print('Error stopping foreground service: $e');
    }
  }

  /// Test background task execution
  static Future<void> executeTestTask() async {
    try {
      await Workmanager().registerOneOffTask(
        'test-task',
        AppConfig.workManagerTaskId,
        initialDelay: Duration(seconds: 5),
        inputData: {
          'isTestTask': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      print('Test background task scheduled');
    } catch (e) {
      print('Error executing test task: $e');
    }
  }

  /// Check service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'fileMonitorActive': FileMonitorService.instance.isMonitoring,
      'queueStats': QueueManager.instance.stats.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('Background task started: $task');
      print('Input data: $inputData');

      // Initialize services in isolate
      await _initializeBackgroundServices();

      switch (task) {
        case AppConfig.workManagerTaskId:
          await _executeMainBackgroundTask(inputData);
          break;
        default:
          print('Unknown task: $task');
          break;
      }

      print('Background task completed: $task');
      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

/// Initialize services in the background isolate
Future<void> _initializeBackgroundServices() async {
  try {
    await NotificationService.initialize();
    print('Background services initialized');
  } catch (e) {
    print('Error initializing background services: $e');
  }
}

/// Execute the main background task
Future<void> _executeMainBackgroundTask(Map<String, dynamic>? inputData) async {
  try {
    print('Executing main background task...');

    // Check if this is a test task
    if (inputData?['isTestTask'] == true) {
      await _executeTestBackgroundTask();
      return;
    }

    // Scan for new video files
    final foundFiles = await _scanForVideoFiles();
    print('Found ${foundFiles.length} video files');

    if (foundFiles.isNotEmpty) {
      await NotificationService.showServiceStatus(
        status: 'Processing',
        totalFiles: foundFiles.length,
        completedFiles: 0,
        failedFiles: 0,
      );

      int processedCount = 0;
      int failedCount = 0;

      for (String filePath in foundFiles) {
        try {
          final success = await _processVideoFile(filePath);
          if (success) {
            processedCount++;
          } else {
            failedCount++;
          }

          await NotificationService.showServiceStatus(
            status: 'Processing',
            totalFiles: foundFiles.length,
            completedFiles: processedCount,
            failedFiles: failedCount,
          );
        } catch (e) {
          print('Error processing file $filePath: $e');
          failedCount++;
        }
      }

      await NotificationService.showServiceStatus(
        status: 'Completed',
        totalFiles: foundFiles.length,
        completedFiles: processedCount,
        failedFiles: failedCount,
      );

      print(
          'Background task completed: $processedCount/${foundFiles.length} files processed');
    } else {
      print('No new video files found');
    }
  } catch (e) {
    print('Error in main background task: $e');
  }
}

/// Execute test background task
Future<void> _executeTestBackgroundTask() async {
  try {
    print('Executing test background task...');

    await NotificationService.showUploadComplete(
      fileName: 'Test Background Task',
      success: true,
    );

    print('Test background task completed');
  } catch (e) {
    print('Error in test background task: $e');
  }
}

/// Scan directories for video files
Future<List<String>> _scanForVideoFiles() async {
  List<String> foundFiles = [];

  try {
    for (String directoryPath in AppConfig.alternativeDirectories) {
      final directory = Directory(directoryPath);

      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File && FileUtils.isVideoFile(entity.path)) {
            final validation = await FileUtils.validateFile(entity.path);
            if (validation.isValid) {
              foundFiles.add(entity.path);
            }
          }
        }
      }
    }
  } catch (e) {
    print('Error scanning for video files: $e');
  }

  return foundFiles;
}

/// Process a single video file
Future<bool> _processVideoFile(String filePath) async {
  try {
    print('Processing video file: $filePath');

    final task = UploadTask(
      id: FileUtils.generateUniqueId(),
      filePath: filePath,
      fileName: FileUtils.getFileName(filePath),
      destinationPath: FileUtils.getDestinationPath(filePath),
      fileSize: await FileUtils.getFileSize(filePath),
      createdAt: DateTime.now(),
      cameraFolder: AppConfig.getCameraFolderName(filePath),
    );

    await NotificationService.showUploadProgress(
      fileName: task.fileName,
      progress: 0.0,
      queuedCount: 0,
      status: 'Starting',
    );

    final uploadService = UploadService();

    final success = await uploadService.uploadFile(
      task,
      onProgress: (progress) async {
        await NotificationService.showUploadProgress(
          fileName: task.fileName,
          progress: progress,
          queuedCount: 0,
        );
      },
    );

    await NotificationService.showUploadComplete(
      fileName: task.fileName,
      success: success,
      errorMessage: success ? null : 'Upload failed',
    );

    // Delete local file if upload was successful
    if (success && AppConfig.enableDebugLogging) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          // Uncomment to actually delete files after successful upload
          // await file.delete();
          print('Local file would be deleted: $filePath');
        }
      } catch (e) {
        print('Error deleting local file: $e');
      }
    }

    return success;
  } catch (e) {
    print('Error processing video file $filePath: $e');

    await NotificationService.showUploadComplete(
      fileName: FileUtils.getFileName(filePath),
      success: false,
      errorMessage: e.toString(),
    );

    return false;
  }
}
