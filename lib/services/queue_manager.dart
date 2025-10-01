import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import '../models/upload_task.dart';
import '../config.dart';
import 'notification_service.dart';
import 'upload_service.dart';

/// Manages the upload queue and concurrent uploads
class QueueManager {
  static QueueManager? _instance;
  static QueueManager get instance => _instance ??= QueueManager._();

  QueueManager._();

  final Queue<UploadTask> _queue = Queue<UploadTask>();
  final Map<String, UploadTask> _activeTasks = {};
  final Map<String, StreamController<UploadTask>> _taskControllers = {};
  final StreamController<List<UploadTask>> _queueController = StreamController.broadcast();

  /// Stream of queue updates
  Stream<List<UploadTask>> get queueStream => _queueController.stream;

  /// Get current queue state
  List<UploadTask> get allTasks {
    List<UploadTask> tasks = [];
    tasks.addAll(_queue);
    tasks.addAll(_activeTasks.values);
    return tasks;
  }

  /// Get queue statistics
  QueueStats get stats {
    final all = allTasks;
    return QueueStats(
      total: all.length,
      queued: _queue.length,
      active: _activeTasks.length,
      completed: all.where((t) => t.isCompleted).length,
      failed: all.where((t) => t.hasFailed).length,
    );
  }

  /// Add task to queue
  Future<void> addTask(UploadTask task) async {
    try {
      // Check if task already exists
      if (_queue.any((t) => t.id == task.id) || _activeTasks.containsKey(task.id)) {
        print('Task ${task.id} already exists in queue');
        return;
      }

      _queue.add(task);
      _notifyQueueUpdate();

      print('Added task to queue: ${task.fileName}');

      // Start processing if we have capacity
      await _processQueue();

    } catch (e) {
      print('Error adding task to queue: $e');
    }
  }

  /// Remove task from queue
  Future<void> removeTask(String taskId) async {
    try {
      // Remove from queue
      _queue.removeWhere((task) => task.id == taskId);

      // Stop active task if running
      if (_activeTasks.containsKey(taskId)) {
        await _cancelActiveTask(taskId);
      }

      _notifyQueueUpdate();
      print('Removed task from queue: $taskId');

    } catch (e) {
      print('Error removing task from queue: $e');
    }
  }

  /// Retry failed task
  Future<void> retryTask(String taskId) async {
    try {
      // Find the failed task
      UploadTask? failedTask;
      final allTasks = this.allTasks;

      for (final task in allTasks) {
        if (task.id == taskId && task.hasFailed && task.canRetry) {
          failedTask = task;
          break;
        }
      }

      if (failedTask == null) {
        print('Task $taskId not found or cannot be retried');
        return;
      }

      // Reset task status and add to queue
      final retryTask = failedTask.copyWith(
        status: UploadStatus.queued,
        progress: 0.0,
        errorMessage: null,
      );

      await removeTask(taskId);
      await addTask(retryTask);

    } catch (e) {
      print('Error retrying task $taskId: $e');
    }
  }

  /// Process the queue
  Future<void> _processQueue() async {
    while (_queue.isNotEmpty && _activeTasks.length < AppConfig.maxConcurrentUploads) {
      final task = _queue.removeFirst();
      await _startTask(task);
    }
  }

  /// Start processing a task
  Future<void> _startTask(UploadTask task) async {
    try {
      _activeTasks[task.id] = task.copyWith(status: UploadStatus.uploading);
      _notifyQueueUpdate();

      // Create stream controller for this task
      final controller = StreamController<UploadTask>();
      _taskControllers[task.id] = controller;

      // Start upload
      final uploadService = UploadService();

      // Listen to upload progress
      controller.stream.listen((updatedTask) {
        _activeTasks[task.id] = updatedTask;
        _notifyQueueUpdate();

        // Update notification
        NotificationService.updateWithTask(updatedTask, queuedCount: _queue.length);
      });

      try {
        final success = await uploadService.uploadFile(
          task,
          onProgress: (progress) {
            final updatedTask = _activeTasks[task.id]?.copyWith(progress: progress);
            if (updatedTask != null) {
              controller.add(updatedTask);
            }
          },
        );

        // Task completed
        final finalStatus = success ? UploadStatus.completed : UploadStatus.failed;
        final completedTask = _activeTasks[task.id]?.copyWith(
          status: finalStatus,
          completedAt: DateTime.now(),
          progress: success ? 100.0 : _activeTasks[task.id]?.progress ?? 0.0,
        );

        if (completedTask != null) {
          controller.add(completedTask);

          // Move to history or remove after delay
          Timer(const Duration(seconds: 5), () {
            _removeActiveTask(task.id);
          });
        }

      } catch (e) {
        // Task failed
        final failedTask = _activeTasks[task.id]?.copyWith(
          status: UploadStatus.failed,
          errorMessage: e.toString(),
          lastAttemptAt: DateTime.now(),
          retryCount: (_activeTasks[task.id]?.retryCount ?? 0) + 1,
        );

        if (failedTask != null) {
          controller.add(failedTask);

          // Check if we should retry
          if (failedTask.canRetry) {
            final delay = _calculateRetryDelay(failedTask.retryCount);
            Timer(Duration(seconds: delay), () {
              retryTask(task.id);
            });
          } else {
            // Move to history after delay
            Timer(const Duration(seconds: 10), () {
              _removeActiveTask(task.id);
            });
          }
        }
      }

      // Continue processing queue
      await _processQueue();

    } catch (e) {
      print('Error starting task ${task.id}: $e');
      _removeActiveTask(task.id);
      await _processQueue();
    }
  }

  /// Cancel active task
  Future<void> _cancelActiveTask(String taskId) async {
    if (_activeTasks.containsKey(taskId)) {
      final cancelledTask = _activeTasks[taskId]?.copyWith(status: UploadStatus.cancelled);
      if (cancelledTask != null) {
        _activeTasks[taskId] = cancelledTask;
        _notifyQueueUpdate();
      }
    }
  }

  /// Remove active task
  void _removeActiveTask(String taskId) {
    _activeTasks.remove(taskId);
    _taskControllers[taskId]?.close();
    _taskControllers.remove(taskId);
    _notifyQueueUpdate();
  }

  /// Calculate retry delay with exponential backoff
  int _calculateRetryDelay(int retryCount) {
    if (!AppConfig.useExponentialBackoff) {
      return AppConfig.baseRetryDelay;
    }

    // Exponential backoff: baseDelay * 2^retryCount
    final delay = AppConfig.baseRetryDelay * (1 << retryCount);
    return delay.clamp(AppConfig.baseRetryDelay, 300); // Max 5 minutes
  }

  /// Notify listeners of queue update
  void _notifyQueueUpdate() {
    if (!_queueController.isClosed) {
      _queueController.add(allTasks);
    }
  }

  /// Clear all tasks
  Future<void> clearAll() async {
    try {
      _queue.clear();
      for (final taskId in _activeTasks.keys.toList()) {
        await _cancelActiveTask(taskId);
      }
      _activeTasks.clear();
      _taskControllers.forEach((_, controller) => controller.close());
      _taskControllers.clear();
      _notifyQueueUpdate();
    } catch (e) {
      print('Error clearing queue: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _queueController.close();
    _taskControllers.forEach((_, controller) => controller.close());
  }
}

/// Queue statistics
class QueueStats {
  final int total;
  final int queued;
  final int active;
  final int completed;
  final int failed;

  QueueStats({
    required this.total,
    required this.queued,
    required this.active,
    required this.completed,
    required this.failed,
  });

  double get completionRate {
    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }

  @override
  String toString() {
    return 'QueueStats(total: $total, queued: $queued, active: $active, completed: $completed, failed: $failed)';
  }
}
