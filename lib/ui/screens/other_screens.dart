import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksync/features/queue/services/transfer_queue.dart';
import 'package:linksync/features/queue/models/sync_task.dart';
import 'package:intl/intl.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(transferQueueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfers')),
      body: tasksAsync.when(
        data: (tasks) => tasks.isEmpty
            ? const Center(child: Text('No active or recent transfers'))
            : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    leading: Icon(_getTaskIcon(task.type)),
                    title: Text(task.filePath.split('/').last),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_getSizeString(task.fileSize)} • ${DateFormat.jm().format(task.createdAt)}'),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: task.progress),
                      ],
                    ),
                    trailing: Text(task.status.name.toUpperCase()),
                    onLongPress: () {
                      ref.read(transferQueueProvider.notifier).removeTask(task.id);
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
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
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Device Name'),
            subtitle: const Text('My Device'),
            onTap: () {},
          ),
          SwitchListTile(
            title: const Text('Wallpaper Sync'),
            value: true,
            onChanged: (v) {},
          ),
          SwitchListTile(
            title: const Text('Clipboard Sync'),
            value: false,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }
}
