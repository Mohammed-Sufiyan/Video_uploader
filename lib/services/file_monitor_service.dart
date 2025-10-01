import 'dart:io';
import 'dart:async';
import '../config.dart';
import '../models/upload_task.dart';
import '../utils/file_utils.dart';
import '../utils/network_helper.dart';
import '../utils/permissions_helper.dart';
import 'queue_manager.dart';

/// Service for monitoring directories and detecting new video files
class FileMonitorService {
  static FileMonitorService? _instance;
  static FileMonitorService get instance =>
      _instance ??= FileMonitorService._();

  FileMonitorService._();

  StreamSubscription<FileSystemEvent>? _watchSubscription;
  Timer? _scanTimer;
  final Set<String> _processedFiles = {};
  bool _isMonitoring = false;

  /// Start monitoring for new files
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      print('File monitoring is already running');
      return;
    }

    try {
      // Ensure permissions before monitoring
      final hasPermissions = await PermissionsHelper.checkPermissions();
      if (!hasPermissions) {
        final requested = await PermissionsHelper.requestAllPermissions();
        if (!requested) {
          print('Required permissions not granted. Monitoring not started.');
          return;
        }
      }

      _isMonitoring = true;
      await _startDirectoryWatching();
      _startPeriodicScanning();
      print('File monitoring started');
    } catch (e) {
      print('Error starting file monitoring: $e');
      _isMonitoring = false;
    }
  }

  /// Stop monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    try {
      await _watchSubscription?.cancel();
      _scanTimer?.cancel();
      _isMonitoring = false;
      print('File monitoring stopped');
    } catch (e) {
      print('Error stopping file monitoring: $e');
    }
  }

  /// Start directory watching using FileSystemEntity.watch
  Future<void> _startDirectoryWatching() async {
    try {
      final availableDirectories = await FileUtils.getAvailableDirectories();

      if (availableDirectories.isEmpty) {
        print('No directories available for monitoring');
        return;
      }

      final primaryDirectory = availableDirectories.first;
      final directory = Directory(primaryDirectory);

      if (!await directory.exists()) {
        print('Monitor directory does not exist: $primaryDirectory');
        return;
      }

      print('Watching directory: $primaryDirectory');

      _watchSubscription = directory
          .watch(
        events: FileSystemEvent.create | FileSystemEvent.modify,
        recursive: true,
      )
          .listen((event) {
        _handleFileSystemEvent(event);
      }, onError: (error) {
        print('Directory watching error: $error');
      });
    } catch (e) {
      print('Error setting up directory watching: $e');
    }
  }

  /// Start periodic directory scanning as backup
  void _startPeriodicScanning() {
    _scanTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performDirectoryScan();
    });

    // Perform initial scan
    Future.delayed(const Duration(seconds: 5), () {
      _performDirectoryScan();
    });
  }

  /// Handle file system events
  void _handleFileSystemEvent(FileSystemEvent event) async {
    try {
      final filePath = event.path;

      // Only process video files
      if (!FileUtils.isVideoFile(filePath)) {
        return;
      }

      // Avoid processing the same file multiple times
      if (_processedFiles.contains(filePath)) {
        return;
      }

      print('File system event: ${event.type} - $filePath');

      if (event.type == FileSystemEvent.create ||
          event.type == FileSystemEvent.modify) {
        await _processNewFile(filePath);
      }
    } catch (e) {
      print('Error handling file system event: $e');
    }
  }

  /// Perform directory scan to catch missed files
  Future<void> _performDirectoryScan() async {
    try {
      print('Performing directory scan...');

      final availableDirectories = await FileUtils.getAvailableDirectories();

      for (String directoryPath in availableDirectories) {
        await _scanDirectory(directoryPath);
      }
    } catch (e) {
      print('Error during directory scan: $e');
    }
  }

  /// Scan a specific directory for video files
  Future<void> _scanDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);

      if (!await directory.exists()) {
        return;
      }

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final filePath = entity.path;
          if (FileUtils.isVideoFile(filePath) &&
              !_processedFiles.contains(filePath)) {
            await _processNewFile(filePath);
          }
        }
      }
    } catch (e) {
      print('Error scanning directory $directoryPath: $e');
    }
  }

  /// Process a new video file
  Future<void> _processNewFile(String filePath) async {
    try {
      print('Processing new file: $filePath');

      // Mark as processed to avoid duplicates
      _processedFiles.add(filePath);

      // Quick connectivity check before enqueue
      if (!await NetworkHelper.isOnline()) {
        print('Device offline. File will be queued until network is available.');
      }

      // Validate file
      final validation = await FileUtils.validateFile(filePath);
      if (!validation.isValid) {
        print('File validation failed: ${validation.error}');
        return;
      }

      // Create upload task
      final task = UploadTask(
        id: FileUtils.generateUniqueId(),
        filePath: filePath,
        fileName: FileUtils.getFileName(filePath),
        destinationPath: FileUtils.getDestinationPath(filePath),
        fileSize: validation.fileSize ?? 0,
        createdAt: DateTime.now(),
        cameraFolder: AppConfig.getCameraFolderName(filePath),
      );

      // Add to upload queue
      await QueueManager.instance.addTask(task);
      print('Added file to upload queue: ${task.fileName}');
    } catch (e) {
      print('Error processing file $filePath: $e');
    }
  }

  /// Manually scan and add files
  Future<List<String>> scanForFiles() async {
    List<String> foundFiles = [];

    try {
      final availableDirectories = await FileUtils.getAvailableDirectories();

      for (String directoryPath in availableDirectories) {
        final directory = Directory(directoryPath);

        if (await directory.exists()) {
          await for (final entity in directory.list(recursive: true)) {
            if (entity is File && FileUtils.isVideoFile(entity.path)) {
              foundFiles.add(entity.path);

              if (!_processedFiles.contains(entity.path)) {
                await _processNewFile(entity.path);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error during manual scan: $e');
    }

    return foundFiles;
  }

  bool get isMonitoring => _isMonitoring;
  int get processedFilesCount => _processedFiles.length;

  void clearProcessedFiles() {
    _processedFiles.clear();
    print('Cleared processed files history');
  }

  void markAsProcessed(String filePath) {
    _processedFiles.add(filePath);
  }

  void unmarkAsProcessed(String filePath) {
    _processedFiles.remove(filePath);
  }

  Map<String, dynamic> getStatus() {
    return {
      'isMonitoring': _isMonitoring,
      'processedFilesCount': _processedFiles.length,
      'hasWatcher': _watchSubscription != null,
      'hasTimer': _scanTimer != null,
    };
  }
}
