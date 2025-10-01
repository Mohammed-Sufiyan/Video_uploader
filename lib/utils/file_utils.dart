import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../config.dart';

/// Utility functions for file operations
class FileUtils {
  /// Check if file is a supported video format
  static bool isVideoFile(String filePath) {
    return AppConfig.isVideoFile(filePath);
  }

  /// Get the list of directories that exist from the configured list
  static Future<List<String>> getAvailableDirectories() async {
    List<String> availableDirectories = [];
    for (String dirPath in AppConfig.alternativeDirectories) {
      try {
        final directory = Directory(dirPath);
        if (await directory.exists()) {
          availableDirectories.add(dirPath);
        }
      } catch (e) {
        print('Error checking directory $dirPath: $e');
      }
    }
    return availableDirectories;
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error getting file size: $e');
      return 0;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Generate unique ID for upload task
  static String generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return '${timestamp}_$random';
  }

  /// Get destination path for file based on camera folder
  static String getDestinationPath(String filePath) {
    final fileName = path.basename(filePath);
    final cameraFolder = AppConfig.getCameraFolder(filePath);
    return '$cameraFolder/$fileName';
  }

  /// Get file name from full path
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Validate file for upload
  static Future<FileValidationResult> validateFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return FileValidationResult(
            isValid: false, error: 'File does not exist');
      }

      if (!isVideoFile(filePath)) {
        return FileValidationResult(
            isValid: false, error: 'File is not a supported video format');
      }

      final fileSize = await getFileSize(filePath);
      if (fileSize == 0) {
        return FileValidationResult(isValid: false, error: 'File is empty');
      }

      return FileValidationResult(isValid: true, fileSize: fileSize);
    } catch (e) {
      return FileValidationResult(
          isValid: false, error: 'Error validating file: $e');
    }
  }

  /// Get MIME type from file extension
  static String getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/x-msvideo';
      case '.mov':
        return 'video/quicktime';
      case '.mkv':
        return 'video/x-matroska';
      case '.wmv':
        return 'video/x-ms-wmv';
      case '.flv':
        return 'video/x-flv';
      case '.webm':
        return 'video/webm';
      case '.m4v':
        return 'video/x-m4v';
      default:
        return 'application/octet-stream'; // fallback MIME type
    }
  }
}

/// Result of file validation
class FileValidationResult {
  final bool isValid;
  final String? error;
  final int? fileSize;

  FileValidationResult({
    required this.isValid,
    this.error,
    this.fileSize,
  });
}
