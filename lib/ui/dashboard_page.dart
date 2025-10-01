import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../services/queue_manager.dart';
import '../services/file_monitor_service.dart';
import '../services/background_service.dart';
import '../services/notification_service.dart';
import '../models/upload_task.dart';
import '../config.dart';
import 'widgets/upload_card.dart';
import 'widgets/gradient_app_bar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  StreamSubscription<List<UploadTask>>? _queueSubscription;
  List<UploadTask> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDashboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queueSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        _refreshDashboard();
        break;
      case AppLifecycleState.paused:
        // App went to background - services continue running
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      default:
        break;
    }
  }

  Future<void> _initializeDashboard() async {
    try {
      // Listen to queue updates
      _queueSubscription = QueueManager.instance.queueStream.listen((tasks) {
        if (mounted) {
          setState(() {
            _tasks = tasks;
          });
        }
      });

      // Initial load
      setState(() {
        _tasks = QueueManager.instance.allTasks;
      });
    } catch (e) {
      print('Error initializing dashboard: $e');
    }
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) return;

    setState(() {
      _tasks = QueueManager.instance.allTasks;
    });
  }

  Future<void> _pickFilesManually() async {
    try {
      setState(() {
        _isLoading = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions:
            AppConfig.videoExtensions.map((ext) => ext.substring(1)).toList(),
        allowMultiple: true,
      );

      if (result != null) {
        int addedCount = 0;

        for (PlatformFile file in result.files) {
          if (file.path != null) {
            final task = UploadTask(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_manual',
              filePath: file.path!,
              fileName: file.name,
              destinationPath:
                  '/visitorcamera/camera1/${file.name}', // Default camera
              fileSize: file.size,
              createdAt: DateTime.now(),
              cameraFolder: AppConfig.getCameraFolderName(file.path!),
            );

            await QueueManager.instance.addTask(task);
            addedCount++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $addedCount files to upload queue'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rescanFolders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final foundFiles = await FileMonitorService.instance.scanForFiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${foundFiles.length} video files'),
            backgroundColor:
                foundFiles.isNotEmpty ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning folders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testBackgroundTask() async {
    try {
      await BackgroundService.executeTestTask();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background task scheduled'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing background task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Uploader'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload Mode: ${AppConfig.uploadMode}'),
            const SizedBox(height: 8),
            Text('S3 Endpoint: ${AppConfig.s3Endpoint}'),
            const SizedBox(height: 8),
            Text('Bucket: ${AppConfig.bucketName}'),
            const SizedBox(height: 8),
            Text('Monitor Directory: ${AppConfig.monitorDirectory}'),
            const SizedBox(height: 16),
            const Text(
              'This app automatically uploads video files from the ImouLife folder to your S3-compatible storage.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = QueueManager.instance.stats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', stats.total, Colors.blue),
                _buildStatItem('Active', stats.active, Colors.orange),
                _buildStatItem('Completed', stats.completed, Colors.green),
                _buildStatItem('Failed', stats.failed, Colors.red),
              ],
            ),
            if (stats.total > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: stats.completionRate / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 4),
              Text(
                '${stats.completionRate.toStringAsFixed(1)}% completed',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickFilesManually,
                  icon: const Icon(Icons.add_box),
                  label: const Text('Pick Files'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _rescanFolders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rescan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testBackgroundTask,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test Background'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await QueueManager.instance.clearAll();
                    await NotificationService.clearAllNotifications();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    if (_tasks.isEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No upload tasks',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Pick files manually or wait for automatic detection',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return UploadCard(
            task: task,
            onRetry: () => QueueManager.instance.retryTask(task.id),
            onCancel: () => QueueManager.instance.removeTask(task.id),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Video Uploader',
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          _buildActionButtons(),
          _buildTasksList(),
        ],
      ),
      floatingActionButton: _isLoading
          ? const CircularProgressIndicator()
          : FloatingActionButton(
              onPressed: _showAppInfo,
              child: const Icon(Icons.info),
            ),
    );
  }
}
