import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:linksync/core/constants/constants.dart';
import 'package:linksync/features/discovery/services/discovery_service.dart';
import 'package:linksync/features/transfer/services/socket_service.dart';
import 'package:linksync/features/settings/services/settings_service.dart';
import 'package:linksync/features/discovery/models/device.dart';
import 'package:linksync/features/discovery/services/qr_service.dart';
import 'dart:io';

import 'package:wakelock_plus/wakelock_plus.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _qrPayload = '';
  String _pin = '';

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeReceiver();
  }

  Future<void> _initializeReceiver() async {
    final settings = await ref.read(settingsServiceProvider.future);
    _pin = settings['pin'] ?? '';

    ref.read(isSenderProvider.notifier).setSender(false);

    // Start mDNS Broadcast
    await ref
        .read(discoveryServiceProvider.notifier)
        .startBroadcast(settings['name']!, settings['id']!);
    // Start TCP Server
    await ref.read(socketServiceProvider.notifier).startServer();

    // Compute Local IP for QR Code
    String localIp = '';
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp.isNotEmpty) break;
      }
    } catch (e) {
      debugPrint('Error getting IP: $e');
    }

    final device = Device(
      id: settings['id']!,
      name: settings['name']!,
      os: Platform.operatingSystem,
      ip: localIp,
      port: int.parse(AppConstants.defaultPort),
      pin: _pin,
    );

    if (!mounted) return;
    setState(() {
      _qrPayload = QrService.generatePayload(device);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    WakelockPlus.disable();
    // Stop broadcast when leaving receive screen
    ref.read(discoveryServiceProvider.notifier).stopBroadcast();
    // Do NOT stopServer() here because it might be actively transferring in TransfersScreen
    // Wait, since we are moving to TransfersScreen, we don't dispose the server!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Files'), elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Waiting for connection...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan this QR directly from the Sender device',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 48),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Center(
                  child: _qrPayload.isEmpty
                      ? const CircularProgressIndicator()
                      : QrImageView(
                          data: _qrPayload,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Text(
                'PIN Code: $_pin',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
