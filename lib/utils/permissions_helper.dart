import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Helper class to manage permissions for the app
class PermissionsHelper {
  /// Requests all necessary permissions depending on platform
  static Future<bool> requestAllPermissions() async {
    try {
      if (Platform.isAndroid) {
        bool granted = await _requestManageExternalStorage();

        if (!granted) {
          print('MANAGE_EXTERNAL_STORAGE permission denied');
          return false;
        }

        bool notificationGranted = await _requestNotificationPermission();

        return granted && notificationGranted;
      } else if (Platform.isIOS) {
        return await _requestIOSPermissions();
      }
      return false;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if permissions are granted
  static Future<bool> checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        return await Permission.manageExternalStorage.isGranted;
      } else if (Platform.isIOS) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  /// Request MANAGE_EXTERNAL_STORAGE permission (Android 11+)
  static Future<bool> _requestManageExternalStorage() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  /// Request notification permission
  static Future<bool> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      print('Notification permission request error: $e');
      return true; // Ignore if notification permission fails
    }
  }

  /// Request necessary permissions on iOS
  static Future<bool> _requestIOSPermissions() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      print('iOS permission request error: $e');
      return true; // Do not block on iOS permission error
    }
  }

  /// Open app settings to enable permissions manually
  static Future<void> launchAppSettings() async {
    try {
      bool opened = await openAppSettings();
      if (!opened) {
        print('Could not open app settings');
      }
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  /// Provide rationale shown to the user when requesting permission
  static String getPermissionRationale() {
    return 'This app needs file access permission to monitor video files and upload them automatically. '
        'Please grant MANAGE_EXTERNAL_STORAGE permission in the settings.';
  }
}
