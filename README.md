# Flutter Video Uploader

A complete Flutter Android app that runs as a background service and automatically uploads video files from the ImouLife app to S3-compatible storage.

## Features

- 🔄 **Automatic Background Uploads**: Continuously monitors for new video files
- 📱 **Foreground Notifications**: Shows upload progress and status
- 🗂️ **Queue Management**: Sequential uploads with automatic retry
- 🗑️ **Auto Cleanup**: Deletes local files after successful upload
- 🔐 **Secure**: Uses presigned URLs (no embedded credentials)
- 📊 **Dashboard UI**: Material Design with progress tracking
- ⚡ **Background Service**: Runs even when app is closed

## Requirements

- Flutter SDK 3.10.0+
- Android API 21+ (Android 5.0+)
- S3-compatible storage (E2E Networks Object Store)
- Backend service for presigned URLs

## Quick Setup

### 1. Configure the App

Edit `lib/config.dart`:

```dart
class AppConfig {
  // Set your S3 endpoint
  static const String s3Endpoint = 'https://moore-market.objectstore.e2enetworks.net';
  static const String bucketName = 'moore-market';
  
  // Set your backend URL for presigned URLs
  static const String presignedUrlEndpoint = 'https://your-backend.com/api/presigned-url';
  
  // Monitor directory (ImouLife downloads)
  static const String monitorDirectory = '/storage/emulated/0/Download/ImouLife/';
}
```

### 2. Set Up Backend Service

The app requires a backend service to generate presigned URLs. See `backend-example/` for a Node.js implementation.

**Backend Requirements:**
- Endpoint: `POST /api/presigned-url`
- Request body: `{ fileName, destinationPath, contentType, bucket }`
- Response: `{ presignedUrl, bucket, key, expiresIn }`

### 3. Android Permissions

The app automatically requests these permissions:
- `INTERNET` - For uploads
- `READ_EXTERNAL_STORAGE` - File access
- `WRITE_EXTERNAL_STORAGE` - File operations
- `MANAGE_EXTERNAL_STORAGE` - Android 11+ file access
- `FOREGROUND_SERVICE` - Background operations
- `POST_NOTIFICATIONS` - Progress notifications

### 4. Build and Install

```bash
# Get dependencies
flutter pub get

# Build for Android
flutter build apk --release

# Install on device
flutter install
```

## Usage

### Automatic Mode (Recommended)

1. **Launch the app** - It will request permissions
2. **Grant permissions** - Especially `MANAGE_EXTERNAL_STORAGE`
3. **App runs in background** - Monitors ImouLife folder automatically
4. **Check notifications** - Shows upload progress
5. **Files auto-delete** - After successful upload

### Manual Mode

1. **Open the app dashboard**
2. **Tap "Pick Files"** - Select videos manually
3. **Tap "Rescan"** - Force folder scan
4. **Monitor progress** - In the dashboard

## Configuration Options

### Upload Behavior

```dart
// Maximum concurrent uploads
static const int maxConcurrentUploads = 2;

// Retry settings
static const int maxRetryAttempts = 3;
static const int baseRetryDelay = 30; // seconds
static const bool useExponentialBackoff = true;

// File validation
static const int minFileAgeSeconds = 30; // Wait for file to be complete
```

### Camera Folders

```dart
// Automatic camera detection based on filename
static const Map<String, String> cameraFolders = {
  'camera1': '/visitorcamera/camera1',
  'camera2': '/visitorcamera/camera2',
};
```

### Network Settings

```dart
// Battery optimization
static const bool requireWifiForUpload = false;
static const bool requireChargingForUpload = false;

// Timeouts
static const int uploadTimeoutSeconds = 300; // 5 minutes
static const int connectionTimeoutSeconds = 30;
```

## Backend Setup (Node.js Example)

### 1. Install Dependencies

```bash
cd backend-example
npm install
```

### 2. Configure AWS Credentials

Edit `server.js`:

```javascript
AWS.config.update({
  accessKeyId: 'YOUR_ACCESS_KEY_ID',
  secretAccessKey: 'YOUR_SECRET_ACCESS_KEY',
  region: 'us-east-1',
  endpoint: 'https://moore-market.objectstore.e2enetworks.net',
  s3ForcePathStyle: true,
});
```

### 3. Start Server

```bash
npm start
```

### 4. Update App Config

```dart
static const String presignedUrlEndpoint = 'http://your-server:3000/api/presigned-url';
```

## Troubleshooting

### Common Issues

**1. Permission Denied**
- Ensure `MANAGE_EXTERNAL_STORAGE` is granted
- Check Android version (Android 11+ requires special permission)
- Go to Settings > Apps > Video Uploader > Permissions

**2. Files Not Detected**
- Verify ImouLife folder path: `/storage/emulated/0/Download/ImouLife/`
- Check if files are being written (wait 30+ seconds)
- Use "Rescan" button in app

**3. Upload Failures**
- Check internet connection
- Verify backend service is running
- Check S3 credentials and bucket permissions
- Review app logs: `flutter logs`

**4. Background Service Stops**
- Disable battery optimization for the app
- Go to Settings > Apps > Video Uploader > Battery > Don't optimize
- Ensure WorkManager is not restricted

### Debug Mode

Enable debug logging in `config.dart`:

```dart
static const bool enableDebugLogging = true;
```

View logs:
```bash
flutter logs
```

## File Structure

```
lib/
├── config.dart                 # App configuration
├── main.dart                   # App entry point
├── models/
│   ├── upload_task.dart        # Upload task model
│   └── upload_task.g.dart      # Generated JSON serialization
├── services/
│   ├── background_service.dart # WorkManager background tasks
│   ├── file_monitor_service.dart # File system monitoring
│   ├── notification_service.dart # Foreground notifications
│   ├── queue_manager.dart      # Upload queue management
│   └── upload_service.dart     # S3 upload logic
├── ui/
│   ├── dashboard_page.dart     # Main dashboard
│   └── widgets/
│       ├── gradient_app_bar.dart # Custom app bar
│       └── upload_card.dart    # Upload task cards
└── utils/
    ├── file_utils.dart         # File operations
    └── permissions_helper.dart # Android permissions
```

## Security Notes

- ✅ **Presigned URLs**: No AWS credentials in app
- ✅ **HTTPS Only**: All network requests encrypted
- ✅ **File Validation**: Checks file integrity before upload
- ✅ **Permission Model**: Minimal required permissions

## Production Deployment

### 1. Backend Security

- Use environment variables for credentials
- Implement rate limiting
- Add authentication/authorization
- Use HTTPS with valid certificates

### 2. App Optimization

- Set `enableDebugLogging = false`
- Use release build: `flutter build apk --release`
- Test on various Android versions
- Monitor battery usage

### 3. Monitoring

- Set up backend logging
- Monitor S3 storage usage
- Track upload success rates
- Alert on failures

## License

MIT License - see LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review app logs
3. Verify backend service
4. Test with manual file selection

---

**Note**: This app is designed specifically for uploading ImouLife video files to S3-compatible storage. Modify the configuration as needed for your specific use case.