import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:linksync/features/discovery/models/device.dart';
import 'package:linksync/features/discovery/services/discovery_service.dart';
import 'package:linksync/features/queue/services/transfer_queue.dart';
import 'package:linksync/features/queue/models/sync_task.dart';
import 'package:linksync/features/settings/services/settings_service.dart';
import 'package:linksync/features/transfer/services/socket_service.dart';
import 'package:linksync/ui/screens/qr_scanner_screen.dart';
import 'package:linksync/ui/screens/other_screens.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import 'package:wakelock_plus/wakelock_plus.dart';

class SendDiscoveryScreen extends ConsumerStatefulWidget {
  final List<PlatformFile> files;
  const SendDiscoveryScreen({super.key, required this.files});

  @override
  ConsumerState<SendDiscoveryScreen> createState() => _SendDiscoveryScreenState();
}

class _SendDiscoveryScreenState extends ConsumerState<SendDiscoveryScreen> {

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       ref.read(discoveryServiceProvider.notifier).startDiscovery();
    });
  }

  @override
  void dispose() {
    ref.read(discoveryServiceProvider.notifier).stopDiscovery();
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _startTransfer(Device device) async {
    final settings = ref.read(settingsServiceProvider).value;

    ref.read(activeDeviceProvider.notifier).setDevice(device);
    ref.read(isSenderProvider.notifier).setSender(true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Starting transfer to ${device.name}...')),
      );
    }

    // 🔑 Start tasks BEFORE navigation
    for (final file in widget.files) {
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

      // ⚠️ Fire & forget instead of awaiting (important)
      unawaited(_sendFile(task, device));
    }

    // ✅ Navigate AFTER scheduling
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TransfersScreen()),
      );
    }
  }

  Future<void> _sendFile(SyncTask task, Device device) async {
    try {
      await ref.read(socketServiceProvider.notifier).sendFile(
        device.ip,
        task.filePath,
        task.id,
        device.pin ?? '',
      );

      await ref.read(transferQueueProvider.notifier)
          .updateProgress(task.id, 1.0, SyncTaskStatus.completed);
    } catch (e) {
      await ref.read(transferQueueProvider.notifier)
          .updateProgress(task.id, 0.0, SyncTaskStatus.failed);
    }
  }
  Future<void> _handleDeviceSelection(Device device) async {
    if (device.pin != null && device.pin!.isNotEmpty) {
      _startTransfer(device);
    } else {
      final pin = await _showPinInputDialog(device);
      if (pin != null && pin.isNotEmpty) {
        final deviceWithPin = Device(
          id: device.id,
          name: device.name,
          os: device.os,
          ip: device.ip,
          port: device.port,
          pin: pin,
        );
        _startTransfer(deviceWithPin);
      }
    }
  }

  Future<String?> _showPinInputDialog(Device device) {
    String pin = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect to ${device.name}'),
        content: TextField(
          keyboardType: TextInputType.number,
          maxLength: 4,
          onChanged: (value) => pin = value,
          decoration: const InputDecoration(
            labelText: 'Enter 4-digit PIN',
            hintText: 'Shown on target device',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, pin),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _showScanner() async {
    if (Platform.isAndroid || Platform.isIOS) {
       final result = await Navigator.push<Device>(
         context,
         MaterialPageRoute(builder: (context) => const QrScannerScreen()),
       );

       if (result != null && mounted) {
         _handleDeviceSelection(result);
       }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Scanner only available on mobile')),
       );
    }
  }

  IconData _getDeviceIcon(String os) {
    switch (os.toLowerCase()) {
      case 'android': return Icons.android;
      case 'ios': return Icons.apple;
      case 'windows': return Icons.desktop_windows;
      case 'linux': return Icons.computer;
      case 'macos': return Icons.laptop_mac;
      default: return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(discoveryServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Receiver'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${widget.files.length} file(s) ready to send.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                        const SizedBox(height: 24),
                        const Text('Searching for nearby receivers...'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(_getDeviceIcon(device.os)),
                        ),
                        title: Text(device.name),
                        subtitle: Text(device.ip),
                        trailing: const Icon(Icons.send, color: Colors.blueAccent),
                        onTap: () => _handleDeviceSelection(device),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScanner,
        label: const Text('Scan QR'),
        icon: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
