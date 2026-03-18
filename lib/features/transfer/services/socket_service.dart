import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksync/core/constants/constants.dart';
import 'package:linksync/main.dart';
import 'package:linksync/ui/screens/other_screens.dart';
import 'package:linksync/features/queue/services/transfer_queue.dart';
import 'package:linksync/features/queue/models/sync_task.dart';
import 'package:linksync/features/settings/services/settings_service.dart';
import 'package:linksync/features/discovery/models/device.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'socket_service.g.dart';

class ActiveDeviceNotifier extends Notifier<Device?> {
  @override
  Device? build() => null;

  void setDevice(Device? device) {
    state = device;
  }
}

final activeDeviceProvider = NotifierProvider<ActiveDeviceNotifier, Device?>(
  () => ActiveDeviceNotifier(),
);

class IsSenderNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSender(bool value) => state = value;
}

final isSenderProvider = NotifierProvider<IsSenderNotifier, bool>(
  () => IsSenderNotifier(),
);

@Riverpod(keepAlive: true)
class SocketService extends _$SocketService {
  ServerSocket? _server;

  @override
  void build() {
    ref.onDispose(() {
      stopServer();
    });
  }

  Future<void> startServer() async {
    if (_server != null) return;
    _server = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      int.parse(AppConstants.defaultPort),
      shared: true,
    );
    _server!.listen((client) {
      _handleIncomingConnection(client);
    });
  }

  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
  }

  void _handleIncomingConnection(Socket client) async {
    final remoteIp = client.remoteAddress.address;
    print('Incoming connection from $remoteIp');

    // Protocol state
    int? metadataLength;
    Uint8List? metadataBuffer;
    SyncTask? currentTask;
    IOSink? fileSink;
    int receivedBytes = 0;
    int totalBytes = 0;
    int lastReportedBytes = 0;
    DateTime lastReportTime = DateTime.now();

    // Accumulator for partial reads
    final List<int> accumulator = [];

    try {
      await for (final Uint8List data in client) {
        accumulator.addAll(data);

        while (accumulator.isNotEmpty) {
          if (metadataLength == null) {
            // Need 4 bytes for length
            if (accumulator.length < 4) break;

            final lengthData = Uint8List.fromList(accumulator.sublist(0, 4));
            metadataLength = ByteData.sublistView(lengthData).getInt32(0);
            accumulator.removeRange(0, 4);
            print('Expecting metadata of length: $metadataLength');
          } else if (metadataBuffer == null) {
            // Need metadataLength bytes for metadata
            if (accumulator.length < metadataLength!) break;

            final metadataBytes = accumulator.sublist(0, metadataLength!);
            final metadataJson = utf8.decode(metadataBytes);
            accumulator.removeRange(0, metadataLength!);

            try {
              final Map<String, dynamic> info = jsonDecode(metadataJson);

              final settings = await ref.read(settingsServiceProvider.future);
              final receivedPin = info['pin'];
              final expectedPin = settings['pin'];

              if (expectedPin != null &&
                  expectedPin.isNotEmpty &&
                  receivedPin != expectedPin) {
                print(
                  'Pin Validation Failed. Expected: $expectedPin, Received: $receivedPin',
                );
                client.write('INVALID_PIN');
                await client.flush();
                client.destroy();
                return;
              }

              final fileName = info['name'];
              totalBytes = info['size'];
              final taskId = DateTime.now().millisecondsSinceEpoch.toString();
              final sourceDeviceId = info['senderId'] ?? 'unknown';

              // Set active device for two-way transfers
              Future.microtask(() {
                ref
                    .read(activeDeviceProvider.notifier)
                    .setDevice(
                      Device(
                        id: sourceDeviceId,
                        name: 'Connected Device',
                        // Or pass name in metadata
                        os: 'unknown',
                        ip: remoteIp,
                        port: int.parse(AppConstants.defaultPort),
                        pin: expectedPin,
                      ),
                    );
              });

              final savePath =
                  settings['savePath'] ??
                  (await Directory.systemTemp.createTemp('linksync')).path;

              final saveFile = File('$savePath/$fileName');
              // Ensure directory exists
              await Directory(savePath).create(recursive: true);

              fileSink = saveFile.openWrite();

              currentTask = SyncTask(
                id: taskId,
                type: SyncTaskType.receiveFile,
                sourceDeviceId: sourceDeviceId,
                targetDeviceId: 'me',
                targetDeviceName: 'yeets',
                filePath: saveFile.path,
                fileSize: totalBytes,
                status: SyncTaskStatus.running,
                createdAt: DateTime.now(),
              );

              await ref
                  .read(transferQueueProvider.notifier)
                  .addTask(currentTask!);
              metadataBuffer = Uint8List(0); // Mark as done
              lastReportTime = DateTime.now();
              print('Starting to receive file: $fileName ($totalBytes bytes)');
              client.write('READY'); // Optional, but helps synchronization

              Future.microtask(() {
                final nav = navigatorKey.currentState;
                if (nav != null) {
                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const TransfersScreen()),
                    (route) => route.isFirst,
                  );
                }
              });
            } catch (e) {
              print('Error parsing metadata: $e');
              client.destroy();
              return;
            }
          } else {
            // Streaming file data
            final remainingNeeded = totalBytes - receivedBytes;
            final chunk = accumulator.length > remainingNeeded
                ? accumulator.sublist(0, remainingNeeded)
                : List<int>.from(accumulator);

            fileSink?.add(chunk);
            receivedBytes += chunk.length;
            accumulator.removeRange(0, chunk.length);

            if (currentTask != null) {
              final now = DateTime.now();
              final deltaMs = now.difference(lastReportTime).inMilliseconds;
              if (deltaMs > 500) {
                final speed =
                    (receivedBytes - lastReportedBytes) / (deltaMs / 1000.0);
                ref
                    .read(transferQueueProvider.notifier)
                    .updateProgress(
                      currentTask!.id,
                      receivedBytes / totalBytes,
                      SyncTaskStatus.running,
                      speed,
                    );
                lastReportTime = now;
                lastReportedBytes = receivedBytes;
              }
            }

            if (receivedBytes >= totalBytes) {
              print('File transfer complete: ${currentTask?.filePath}');
              await fileSink?.close();
              if (currentTask != null) {
                await ref
                    .read(transferQueueProvider.notifier)
                    .updateProgress(
                      currentTask!.id,
                      1.0,
                      SyncTaskStatus.completed,
                      0.0,
                    );
              }
              client.write('COMPLETE');
              await client.flush();
              client.destroy();
              return;
            }
          }
        }
      }
    } catch (e) {
      print('Socket loop error: $e');
    } finally {
      print('Connection closed for $remoteIp');
      await fileSink?.close();
      client.destroy();
    }
  }

  Future<void> sendFile(
    String ip,
    String filePath,
    String taskId, [
    String pin = '',
  ]) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, int.parse(AppConstants.defaultPort));

      final completer = Completer<void>();

      // Listen to the socket to process responses and prevent Unhandled async exceptions
      socket.listen(
        (data) {
          final response = utf8.decode(data);
          if (response.contains('INVALID_PIN')) {
            print('Receiver rejected connection: Invalid PIN');
            if (!completer.isCompleted) completer.completeError('INVALID_PIN');
          } else if (response.contains('COMPLETE')) {
            if (!completer.isCompleted) completer.complete();
          }
        },
        onError: (e) {
          print('Sender socket async error: $e');
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!completer.isCompleted)
            completer.completeError('Socket closed unexpectedly');
        },
        cancelOnError: true,
      );

      final file = File(filePath);
      final totalSize = await file.length();
      final settings = ref.read(settingsServiceProvider).value;

      final metadata = {
        'name': file.uri.pathSegments.last,
        'size': totalSize,
        'senderId': settings?['id'] ?? 'unknown',
        'pin': pin,
        'deviceName': settings?['name'] ?? 'unknown',
      };

      final metadataJson = jsonEncode(metadata);
      final metadataBytes = utf8.encode(metadataJson);

      // Send length prefix (4 bytes)
      final lengthHeader = ByteData(4)..setInt32(0, metadataBytes.length);
      socket.add(lengthHeader.buffer.asUint8List());

      // Send metadata
      socket.add(metadataBytes);

      await socket.flush();

      // Stream file
      final stream = file.openRead();
      int sentBytes = 0;
      int lastReportedBytes = 0;
      DateTime lastReportTime = DateTime.now();

      await for (final chunk in stream) {
        socket.add(chunk);
        sentBytes += chunk.length;

        final now = DateTime.now();
        final deltaMs = now.difference(lastReportTime).inMilliseconds;
        if (deltaMs > 500) {
          final speed = (sentBytes - lastReportedBytes) / (deltaMs / 1000.0);
          // Block sender progress at 99.9% until the Receiver ACK confirms storage
          final progress = (sentBytes / totalSize).clamp(0.0, 0.999);
          ref
              .read(transferQueueProvider.notifier)
              .updateProgress(taskId, progress, SyncTaskStatus.running, speed);
          lastReportTime = now;
          lastReportedBytes = sentBytes;
        }
      }

      await socket.flush();

      // IMPORTANT: Wait for the receiver to send 'COMPLETE' before closing.
      // This ensures the file is fully stored on the receiver side.
      try {
        await completer.future.timeout(const Duration(seconds: 30));
        print('Transfer confirmed by receiver: $taskId');
      } catch (e) {
        print('Timeout or error waiting for COMPLETE: $e');
        ref
            .read(transferQueueProvider.notifier)
            .updateProgress(taskId, 0.0, SyncTaskStatus.failed, 0.0);
        rethrow;
      }
    } finally {
      await socket?.close();
    }
  }
}
