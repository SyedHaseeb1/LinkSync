import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksync/features/discovery/services/discovery_service.dart';
import 'package:linksync/features/discovery/models/device.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryServiceProvider.notifier).startDiscovery();
      // For demo/test purposes, also start broadcasting
      ref.read(discoveryServiceProvider.notifier).startBroadcast('My Device', 'device-id-123');
    });
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(discoveryServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(discoveryServiceProvider.notifier).stopDiscovery();
              ref.read(discoveryServiceProvider.notifier).startDiscovery();
            },
          ),
        ],
      ),
      body: devices.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Searching for devices...'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  leading: Icon(_getDeviceIcon(device.os)),
                  title: Text(device.name),
                  subtitle: Text('${device.ip}:${device.port}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Connect to device
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open QR Scanner
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  IconData _getDeviceIcon(String os) {
    switch (os.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.apple;
      case 'windows':
        return Icons.desktop_windows;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }
}
