import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config.dart';
import '../models/upload_task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static const int _notificationId = 1000;
  static const int _summaryNotificationId = 1001;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      final bool? result = await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      if (result == true) {
        await _createNotificationChannel();
        _isInitialized = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Error initializing notifications: $e');
      return false;
    }
  }

  static Future<void> _createNotificationChannel() async {
    if (!Platform.isAndroid) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      description: AppConfig.notificationChannelDescription,
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate to dashboard page when notification is tapped
  }

  static Future<void> showUploadProgress({
    required String fileName,
    required double progress,
    required int queuedCount,
    String? status,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final String title = 'Uploading Video Files';
      final String body =
          _buildProgressBody(fileName, progress, queuedCount, status);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        AppConfig.notificationChannelId,
        AppConfig.notificationChannelName,
        channelDescription: AppConfig.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        playSound: false,
        enableVibration: false,
        category: AndroidNotificationCategory.progress,
        visibility: NotificationVisibility.public,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.show(
        _notificationId,
        title,
        body,
        notificationDetails,
        payload: 'upload_progress',
      );
    } catch (e) {
      print('Error showing upload progress notification: $e');
    }
  }

  static Future<void> showUploadComplete({
    required String fileName,
    required bool success,
    String? errorMessage,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final String title = success ? 'Upload Completed' : 'Upload Failed';
      final String body = success
          ? 'Successfully uploaded: $fileName'
          : 'Failed to upload $fileName: ${errorMessage ?? 'Unknown error'}';

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        AppConfig.notificationChannelId,
        AppConfig.notificationChannelName,
        channelDescription: AppConfig.notificationChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
        playSound: true,
        enableVibration: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        notificationDetails,
        payload: success ? 'upload_success' : 'upload_failed',
      );
    } catch (e) {
      print('Error showing upload complete notification: $e');
    }
  }

  static Future<void> showServiceStatus({
    required String status,
    required int totalFiles,
    required int completedFiles,
    required int failedFiles,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const String title = 'Video Upload Service';
      final String body = _buildServiceStatusBody(
          status, totalFiles, completedFiles, failedFiles);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        AppConfig.notificationChannelId,
        AppConfig.notificationChannelName,
        channelDescription: AppConfig.notificationChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        playSound: false,
        enableVibration: false,
        category: AndroidNotificationCategory.service,
        visibility: NotificationVisibility.public,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.show(
        _summaryNotificationId,
        title,
        body,
        notificationDetails,
        payload: 'service_status',
      );
    } catch (e) {
      print('Error showing service status notification: $e');
    }
  }

  static Future<void> clearAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  static Future<void> clearNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      print('Error clearing notification $id: $e');
    }
  }

  static String _buildProgressBody(
      String fileName, double progress, int queuedCount, String? status) {
    final progressText = '${progress.toStringAsFixed(1)}%';
    final queueText = queuedCount > 0 ? ' • $queuedCount queued' : '';
    final statusText = status != null ? ' • $status' : '';

    return '$fileName ($progressText)$queueText$statusText';
  }

  static String _buildServiceStatusBody(
      String status, int totalFiles, int completedFiles, int failedFiles) {
    final completionRate = totalFiles > 0
        ? (completedFiles / totalFiles * 100).toStringAsFixed(0)
        : '0';
    return '$status • $completedFiles/$totalFiles completed ($completionRate%)${failedFiles > 0 ? ' • $failedFiles failed' : ''}';
  }

  static Future<void> updateWithTask(UploadTask task,
      {required int queuedCount}) async {
    if (task.isInProgress) {
      await showUploadProgress(
        fileName: task.fileName,
        progress: task.progress,
        queuedCount: queuedCount,
        status: task.statusText,
      );
    } else if (task.isCompleted || task.hasFailed) {
      await showUploadComplete(
        fileName: task.fileName,
        success: task.isCompleted,
        errorMessage: task.errorMessage,
      );
    }
  }
}
