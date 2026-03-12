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
    BonsoirService service = BonsoirService(
      name: deviceName,
      type: AppConstants.mDnsType,
      port: int.parse(AppConstants.defaultPort),
      attributes: {
        'id': deviceId,
        'os': Platform.operatingSystem,
      },
    );

    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  Future<void> stopBroadcast() async {
    await _broadcast?.stop();
    _broadcast = null;
  }

  Future<void> startDiscovery() async {
    _discovery = BonsoirDiscovery(type: AppConstants.mDnsType);
    await _discovery!.ready;

    _discovery!.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved ||
          event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        if (event.service == null || event.service!.attributes['id'] == null) return;
        
        final device = Device(
          id: event.service!.attributes['id']!,
          name: event.service!.name,
          os: event.service!.attributes['os'] ?? 'Unknown',
          ip: (event.service as ResolvedBonsoirService).host ?? 'Unknown',
          port: event.service!.port,
        );

        if (!state.any((d) => d.id == device.id)) {
          state = [...state, device];
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        state = state.where((d) => d.name != event.service?.name).toList();
      }
    });

    await _discovery!.start();
  }

  Future<void> stopDiscovery() async {
    await _discovery?.stop();
    _discovery = null;
    state = [];
  }
}
