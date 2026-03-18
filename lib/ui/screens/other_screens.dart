import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksync/features/queue/services/transfer_queue.dart';
import 'package:linksync/features/queue/models/sync_task.dart';
import 'package:linksync/features/settings/services/settings_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:linksync/features/transfer/services/socket_service.dart';
import 'package:linksync/features/discovery/models/device.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  /*  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(transferQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer Dashboard - ${tasksAsync.value?.first.targetDeviceName}'),
        elevation: 0,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active or recent transfers', style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          final totalSpeed = tasks
              .where((t) => t.status == SyncTaskStatus.running)
              .fold(0.0, (sum, t) => sum + t.speed);

          return Column(
            children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  width: double.infinity,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Column(
                    children: [
                      const Text('Total Transfer Speed', style: TextStyle(fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(
                        _getSpeedString(totalSpeed),
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                ),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Do not close or minimize the application until transfers are 100% complete.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildThumbnailCard(context, task),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.filePath.split('/').last,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_getSizeString(task.fileSize)} • ${task.status.name.toUpperCase()}',
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value: task.progress,
                                            minHeight: 8,
                                            backgroundColor: Colors.white,
                                            color: task.status == SyncTaskStatus.failed
                                                ? Colors.red
                                                : task.status == SyncTaskStatus.completed
                                                    ? Colors.green
                                                    : Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${(task.progress * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  if (task.status == SyncTaskStatus.running) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _getSpeedString(task.speed),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () {
                                ref.read(transferQueueProvider.notifier).removeTask(task.id);
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading transfers: $e')),
      ),
      floatingActionButton: (ref.watch(activeDeviceProvider) != null && ref.watch(isSenderProvider))
          ? FloatingActionButton.extended(
              onPressed: () async {
                final device = ref.read(activeDeviceProvider);
                if (device == null) return;

                final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                if (result != null && result.files.isNotEmpty) {
                  final settings = ref.read(settingsServiceProvider).value;
                  for (final file in result.files) {
                    if (file.path == null) continue;
                    final task = SyncTask(
                      id: const Uuid().v4(),
                      type: SyncTaskType.sendFile,
                      sourceDeviceId: settings?['id'] ?? 'unknown',
                      targetDeviceId: device.id,
                      targetDeviceName: device.name,
                      filePath: file.path!,
                      fileSize: file.size,
                      status: SyncTaskStatus.running,
                      createdAt: DateTime.now(),
                    );
                    await ref.read(transferQueueProvider.notifier).addTask(task);
                    try {
                      await ref.read(socketServiceProvider.notifier).sendFile(device.ip, file.path!, task.id, device.pin ?? '');
                      await ref.read(transferQueueProvider.notifier).updateProgress(task.id, 1.0, SyncTaskStatus.completed);
                    } catch (e) {
                      await ref.read(transferQueueProvider.notifier).updateProgress(task.id, 0.0, SyncTaskStatus.failed);
                    }
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Files'),
            )
          : null,
    );
  }*/

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(transferQueueProvider);
    final activeDevice = ref.watch(activeDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeDevice != null
              ? 'Sending to ${activeDevice.name}'
              : 'Transfer Dashboard',
        ),
        elevation: 0,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No active or recent transfers',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          // ✅ Total speed
          final totalSpeed = tasks
              .where((t) => t.status == SyncTaskStatus.running)
              .fold(0.0, (sum, t) => sum + t.speed);

          return Column(
            children: [
              // 🔥 HEADER (Clear status)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeDevice != null
                          ? 'Sending files to ${activeDevice.name}'
                          : 'Transfer in progress',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getSpeedString(totalSpeed),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tasks.where((t) => t.status == SyncTaskStatus.running).length} active transfers',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // ⚠️ Warning
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keep app open until all transfers complete',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

              // 📂 FILE LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    final fileName = task.filePath.split('/').last;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 📄 FILE NAME
                            Row(
                              children: [
                                // 📄 File name takes remaining space
                                Expanded(
                                  child: Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),

                                // ❌ Remove button
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    ref
                                        .read(transferQueueProvider.notifier)
                                        .removeTask(task.id);
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            // 📊 META INFO
                            Text(
                              '${_getSizeString(task.fileSize)} • ${_getReadableStatus(task.status)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 📈 PROGRESS
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: task.progress,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.shade300,
                                      color: _getProgressColor(context, task),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${(task.progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            // 🚀 SPEED + DEVICE
                            if (task.status == SyncTaskStatus.running) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getSpeedString(task.speed),
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    task.targetDeviceName ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading transfers: $e')),
      ),

      // ➕ ADD FILES
      floatingActionButton:
          (activeDevice != null && ref.watch(isSenderProvider))
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                );

                if (result == null || result.files.isEmpty) return;

                final settings = ref.read(settingsServiceProvider).value;

                for (final file in result.files) {
                  if (file.path == null) continue;

                  final task = SyncTask(
                    id: const Uuid().v4(),
                    type: SyncTaskType.sendFile,
                    sourceDeviceId: settings?['id'] ?? 'unknown',
                    targetDeviceId: activeDevice.id,
                    targetDeviceName: activeDevice.name,
                    filePath: file.path!,
                    fileSize: file.size,
                    status: SyncTaskStatus.running,
                    createdAt: DateTime.now(),
                  );

                  await ref.read(transferQueueProvider.notifier).addTask(task);

                  // 🔥 background send (no UI blocking)
                  unawaited(_sendFile(task, activeDevice, ref));
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Files'),
            )
          : null,
    );
  }

  // ✅ Background send
  Future<void> _sendFile(SyncTask task, Device device, WidgetRef ref) async {
    try {
      await ref
          .read(socketServiceProvider.notifier)
          .sendFile(device.ip, task.filePath, task.id, device.pin ?? '');

      await ref
          .read(transferQueueProvider.notifier)
          .updateProgress(task.id, 1.0, SyncTaskStatus.completed);
    } catch (e) {
      await ref
          .read(transferQueueProvider.notifier)
          .updateProgress(task.id, 0.0, SyncTaskStatus.failed);
    }
  }

  // ✅ Helpers

  String _getReadableStatus(SyncTaskStatus status) {
    switch (status) {
      case SyncTaskStatus.running:
        return 'Transferring';
      case SyncTaskStatus.completed:
        return 'Completed';
      case SyncTaskStatus.failed:
        return 'Failed';
      default:
        return status.name;
    }
  }

  Color _getProgressColor(BuildContext context, SyncTask task) {
    if (task.status == SyncTaskStatus.failed) return Colors.red;
    if (task.status == SyncTaskStatus.completed) return Colors.green;
    return Theme.of(context).primaryColor;
  }

  IconData _getTaskIcon(SyncTaskType type) {
    switch (type) {
      case SyncTaskType.sendFile:
        return Icons.upload;
      case SyncTaskType.receiveFile:
        return Icons.download;
      case SyncTaskType.wallpaperSync:
        return Icons.wallpaper;
      case SyncTaskType.folderSync:
        return Icons.folder_copy;
    }
  }

  String _getSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getSpeedString(double bytesPerSecond) {
    if (bytesPerSecond < 1024)
      return '${bytesPerSecond.toStringAsFixed(1)} B/s';
    if (bytesPerSecond < 1024 * 1024)
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  Widget _buildThumbnailCard(BuildContext context, SyncTask task) {
    final ext = task.filePath.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

    if (isImage &&
        (task.type == SyncTaskType.sendFile ||
            task.status == SyncTaskStatus.completed)) {
      final file = File(task.filePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackAvatar(context, task.type),
          ),
        );
      }
    }

    return _fallbackAvatar(context, task.type);
  }

  Widget _fallbackAvatar(BuildContext context, SyncTaskType type) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        _getTaskIcon(type),
        size: 32,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            ListTile(
              title: const Text('Device Name'),
              subtitle: Text(settings['name'] ?? 'Unknown'),
              onTap: () =>
                  _showEditNameDialog(context, ref, settings['name'] ?? ''),
            ),
            ListTile(
              title: const Text('Download Folder'),
              subtitle: Text(settings['savePath'] ?? 'Unknown'),
              onTap: () =>
                  _pickSavePath(context, ref, settings['savePath'] ?? ''),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Device ID: (Tap to copy)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ListTile(
              title: Text(
                settings['id'] ?? 'Unknown',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                // TODO: Copy to clipboard
              },
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _pickSavePath(
    BuildContext context,
    WidgetRef ref,
    String currentPath,
  ) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await ref.read(settingsServiceProvider.notifier).updateSavePath(result);
    }
  }

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(settingsServiceProvider.notifier)
                  .updateName(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
