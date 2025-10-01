import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/upload_task.dart';
import '../config.dart';
import '../utils/file_utils.dart';
import '../utils/network_helper.dart';
import '../utils/permissions_helper.dart';

/// Service for uploading files to S3-compatible storage
class UploadService {
  final http.Client _httpClient = http.Client();

  /// Upload a file using presigned URL or direct upload
  Future<bool> uploadFile(
    UploadTask task, {
    required Function(double) onProgress,
  }) async {
    try {
      print('Starting upload for: ${task.fileName}');

      // Ensure permissions are granted
      final hasPermissions = await PermissionsHelper.checkPermissions();
      if (!hasPermissions) {
        final requested = await PermissionsHelper.requestAllPermissions();
        if (!requested) {
          throw Exception('Required permissions not granted');
        }
      }

      // Ensure network connectivity and backend reachability
      await NetworkHelper.ensureNetworkReady();

      // Validate file before upload
      final validation = await FileUtils.validateFile(task.filePath);
      if (!validation.isValid) {
        throw Exception(validation.error ?? 'File validation failed');
      }

      if (AppConfig.uploadMode == 'presigned') {
        return await _uploadWithPresignedUrl(task, onProgress);
      } else {
        return await _uploadDirect(task, onProgress);
      }
    } catch (e) {
      print('Upload error for ${task.fileName}: $e');
      throw Exception('Upload failed: $e');
    }
  }

  /// Upload using presigned URL (recommended)
  Future<bool> _uploadWithPresignedUrl(
    UploadTask task,
    Function(double) onProgress,
  ) async {
    try {
      final presignedUrl = await _getPresignedUrl(
        fileName: task.fileName,
        destinationPath: task.destinationPath,
        contentType: FileUtils.getMimeType(task.filePath),
        cameraFolder: AppConfig.getCameraFolderName(task.filePath),
      );

      if (presignedUrl == null) {
        throw Exception('Failed to get presigned URL');
      }

      return await _performPresignedUpload(
        presignedUrl: presignedUrl,
        filePath: task.filePath,
        onProgress: onProgress,
      );
    } catch (e) {
      print('Presigned upload error: $e');
      throw Exception('Presigned upload failed: $e');
    }
  }

  /// Get presigned URL from backend service
  Future<String?> _getPresignedUrl({
    required String fileName,
    required String destinationPath,
    required String contentType,
    required String cameraFolder,
  }) async {
    try {
      final requestBody = {
        'fileName': fileName,
        'fileType': contentType, // Change `contentType` key name to `fileType`
        'cameraFolder': cameraFolder,
      };

      // Debug logging
      print('DEBUG: Sending presigned URL request with:');
      print('  fileName: "$fileName"');
      print('  fileType: "$contentType"');
      print('  cameraFolder: "$cameraFolder"');
      print('  requestBody: ${jsonEncode(requestBody)}');

      final response = await _httpClient
          .post(
            Uri.parse(AppConfig.presignedUrlEndpoint),
            headers: AppConfig.getPresignedUrlHeaders(),
            body: jsonEncode(requestBody),
          )
          .timeout(Duration(seconds: AppConfig.connectionTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String? ?? data['presignedUrl'] as String?;
      } else {
        print(
            'Presigned URL request failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting presigned URL: $e');
      return null;
    }
  }

  /// Perform the actual upload using presigned URL
  Future<bool> _performPresignedUpload({
    required String presignedUrl,
    required String filePath,
    required Function(double) onProgress,
  }) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      final fileStream = file.openRead();

      final request = http.StreamedRequest('PUT', Uri.parse(presignedUrl));
      request.headers['Content-Type'] = FileUtils.getMimeType(filePath);
      request.headers['Content-Length'] = fileSize.toString();

      int uploadedBytes = 0;
      await for (final chunk in fileStream) {
        request.sink.add(chunk);
        uploadedBytes += chunk.length;

        final progress = (uploadedBytes / fileSize) * 100;
        onProgress(progress);

        await Future.delayed(const Duration(milliseconds: 10));
      }

      request.sink.close();

      final response = await request.send().timeout(
            Duration(seconds: AppConfig.uploadTimeoutSeconds),
          );

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

      if (isSuccess) {
        print('Upload completed successfully');
        if (AppConfig.enableDebugLogging) {
          print('File uploaded successfully: $filePath');
          // Optionally delete local file here if needed
          // await file.delete();
        }
      } else {
        final responseBody = await response.stream.bytesToString();
        print('Upload failed: ${response.statusCode} - $responseBody');
      }

      return isSuccess;
    } catch (e) {
      print('Error during presigned upload: $e');
      return false;
    }
  }

  /// Direct upload to S3 (not implemented, placeholder)
  Future<bool> _uploadDirect(
    UploadTask task,
    Function(double) onProgress,
  ) async {
    print('Direct upload not implemented. Use presigned URL mode.');
    for (int i = 0; i <= 100; i += 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      onProgress(i.toDouble());
    }
    return false;
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}
