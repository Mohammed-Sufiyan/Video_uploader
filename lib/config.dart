/// Configuration settings for the video uploader app
/// Modify these settings according to your backend setup

class AppConfig {
  // === UPLOAD CONFIGURATION ===

  /// Upload mode: 'presigned' or 'direct'
  /// Use 'presigned' for production (recommended)
  /// Use 'direct' only for testing with proper authentication
  static const String uploadMode = 'presigned';

  /// S3-compatible endpoint URL
  static const String s3Endpoint =
      'https://moore-market.objectstore.e2enetworks.net';

  /// Bucket name
  static const String bucketName = 'moore-market';

  /// Folder paths for different cameras
  static const Map<String, String> cameraFolders = {
    'camera1': '/visitorcamera/camera1',
    'camera2': '/visitorcamera/camera2',
  };

  /// Default camera folder (used when camera type cannot be determined)
  static const String defaultCameraFolder = '/visitorcamera/camera1';

  // === PRESIGNED URL CONFIGURATION ===

  /// Backend endpoint for generating presigned URLs
  /// Replace with your actual backend URL

  // static const String presignedUrlEndpoint = 'https://your-backend.com/api/presigned-url';
  static const String presignedUrlEndpoint = 'http://192.168.1.27:3000/presign';

  /// API key for presigned URL requests (if required)
  static const String? presignedApiKey =
      null; // Set your API key here if needed

  // === FILE MONITORING CONFIGURATION ===

  /// Directory to monitor for new video files
  /// Default: Imou Life app download directory
  static const String monitorDirectory =
      '/storage/emulated/0/Download/ImouLife/';

  /// Alternative directories to monitor (will try in order)
  static const List<String> alternativeDirectories = [
    '/storage/emulated/0/Download/ImouLife/',
    '/storage/emulated/0/DCIM/ImouLife/',
    '/storage/emulated/0/Documents/ImouLife/',
  ];

  /// Video file extensions to monitor
  static const List<String> videoExtensions = [
    '.mp4',
    '.avi',
    '.mov',
    '.mkv',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v'
  ];

  // === UPLOAD BEHAVIOR ===

  /// Maximum concurrent uploads
  static const int maxConcurrentUploads = 2;

  /// Maximum retry attempts per file
  static const int maxRetryAttempts = 3;

  /// Base retry delay in seconds
  static const int baseRetryDelay = 30;

  /// Use exponential backoff for retries
  static const bool useExponentialBackoff = true;

  /// Upload timeout in seconds
  static const int uploadTimeoutSeconds = 300; // 5 minutes

  /// Minimum file age before upload (in seconds)
  /// This prevents uploading files that are still being written
  static const int minFileAgeSeconds = 30;

  // === NOTIFICATION CONFIGURATION ===

  /// Notification channel ID
  static const String notificationChannelId = 'video_upload_channel';

  /// Notification channel name
  static const String notificationChannelName = 'Video Upload Service';

  /// Notification channel description
  static const String notificationChannelDescription =
      'Handles background video uploads';

  /// Show detailed progress notifications
  static const bool showDetailedProgress = true;

  /// Update progress every N percent
  static const int progressUpdateInterval = 5;

  // === BACKGROUND SERVICE CONFIGURATION ===

  /// WorkManager task identifier
  static const String workManagerTaskId = 'video_upload_task';

  /// Background task execution interval (in minutes)
  /// Minimum is 15 minutes for periodic tasks
  static const int backgroundTaskInterval = 15;

  /// Enable debug logging
  static const bool enableDebugLogging = true; // Set to false in production

  // === STORAGE CONFIGURATION ===

  /// Local database name for tracking uploads
  static const String localDbName = 'video_uploads.db';

  /// Keep upload history for N days
  static const int keepHistoryDays = 30;

  // === NETWORK CONFIGURATION ===

  /// Require WiFi for uploads (battery saving)
  static const bool requireWifiForUpload = false;

  /// Require device charging for uploads (battery saving)
  static const bool requireChargingForUpload = false;

  /// Connection timeout for HTTP requests
  static const int connectionTimeoutSeconds = 30;

  /// Read timeout for HTTP requests
  static const int readTimeoutSeconds = 60;

  // === HELPER METHODS ===

  /// Get camera folder based on file name or path
  static String getCameraFolder(String filePath) {
    // Try to determine camera from file path/name
    String fileName = filePath.toLowerCase();

    if (fileName.contains('camera1') || fileName.contains('cam1')) {
      return cameraFolders['camera1']!;
    } else if (fileName.contains('camera2') || fileName.contains('cam2')) {
      return cameraFolders['camera2']!;
    }

    // Default to camera1 if cannot determine
    return defaultCameraFolder;
  }

  /// Get camera folder name for backend API (just the folder name, not full path)
  static String getCameraFolderName(String filePath) {
    // Try to determine camera from file path/name
    String fileName = filePath.toLowerCase();
    
    print('DEBUG: getCameraFolderName called with filePath: "$filePath"');
    print('DEBUG: fileName (lowercase): "$fileName"');

    if (fileName.contains('camera1') || fileName.contains('cam1')) {
      print('DEBUG: Detected camera1, returning "camera1"');
      return 'camera1';
    } else if (fileName.contains('camera2') || fileName.contains('cam2')) {
      print('DEBUG: Detected camera2, returning "camera2"');
      return 'camera2';
    }

    // Default to camera1 if cannot determine
    print('DEBUG: No camera detected, defaulting to "camera1"');
    return 'camera1';
  }

  /// Check if file is a supported video format
  static bool isVideoFile(String filePath) {
    String extension = filePath.toLowerCase();
    return videoExtensions.any((ext) => extension.endsWith(ext));
  }

  /// Get presigned URL request headers
  static Map<String, String> getPresignedUrlHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (presignedApiKey != null) {
      headers['Authorization'] = 'Bearer $presignedApiKey';
    }

    return headers;
  }

  /// Validate configuration
  static List<String> validateConfig() {
    List<String> errors = [];

    if (uploadMode != 'presigned' && uploadMode != 'direct') {
      errors.add('uploadMode must be "presigned" or "direct"');
    }

    if (s3Endpoint.isEmpty) {
      errors.add('s3Endpoint cannot be empty');
    }

    if (bucketName.isEmpty) {
      errors.add('bucketName cannot be empty');
    }

    if (uploadMode == 'presigned' && presignedUrlEndpoint.isEmpty) {
      errors.add('presignedUrlEndpoint is required when using presigned mode');
    }

    if (maxConcurrentUploads < 1 || maxConcurrentUploads > 10) {
      errors.add('maxConcurrentUploads should be between 1 and 10');
    }

    if (maxRetryAttempts < 0 || maxRetryAttempts > 10) {
      errors.add('maxRetryAttempts should be between 0 and 10');
    }

    return errors;
  }
}
