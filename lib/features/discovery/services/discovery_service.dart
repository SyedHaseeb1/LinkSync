import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksync/core/constants/constants.dart';
import 'package:linksync/features/discovery/models/device.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discovery_service.g.dart';

@riverpod
class DiscoveryService extends _$DiscoveryService {
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;

  @override
  List<Device> build() {
    ref.onDispose(() {
      stopDiscovery();
      stopBroadcast();
    });
    return [];
  }

  Future<void> startBroadcast(String deviceName, String deviceId) async {
    await stopBroadcast();

    final service = BonsoirService(
      name: deviceName,
      type: AppConstants.mDnsType,
      port: int.parse(AppConstants.defaultPort),
      attributes: {
        'id': deviceId,
        'os': Platform.operatingSystem,
      },
    );

    _broadcast = BonsoirBroadcast(service: service);

    // Ensure the broadcast instance is initialized for Linux/Android
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  Future<void> stopBroadcast() async {
    if (_broadcast != null) {
      await _broadcast!.stop();
      _broadcast = null;
    }
  }

  Future<void> startDiscovery() async {
    if (_discovery != null) return;

    _discovery = BonsoirDiscovery(type: AppConstants.mDnsType);

    // Mandatory initialization before calling start
    await _discovery!.ready;

    _discovery!.eventStream?.listen(_handleDiscoveryEvent);
    await _discovery!.start();
  }

  void _handleDiscoveryEvent(BonsoirDiscoveryEvent event) {
    if (event.service == null) return;
    final service = event.service!;

    switch (event.type) {
      case BonsoirDiscoveryEventType.discoveryServiceFound:
      // Found is just the announcement; resolve gets the actual IP and TXT data
        service.resolve(_discovery!.serviceResolver);
        break;

      case BonsoirDiscoveryEventType.discoveryServiceResolved:
      // Attributes (id/os) and host (IP) are now populated
        if (service.attributes.containsKey('id')) {
          final String? hostAddress = (service is ResolvedBonsoirService)
              ? service.host
              : null;

          final device = Device(
            id: service.attributes['id']!,
            name: service.name,
            os: service.attributes['os'] ?? 'Unknown',
            ip: hostAddress ?? 'Unknown',
            port: service.port,
          );

          state = [
            ...state.where((d) => d.id != device.id),
            device,
          ];
        }
        break;

      case BonsoirDiscoveryEventType.discoveryServiceLost:
        state = state.where((d) => d.name != service.name).toList();
        break;

      case BonsoirDiscoveryEventType.discoveryServiceResolveFailed:
      // Handle failed resolution if necessary
        break;

      default:
        break;
    }
  }

  Future<void> stopDiscovery() async {
    if (_discovery != null) {
      await _discovery!.stop();
      _discovery = null;
    }
  }
}