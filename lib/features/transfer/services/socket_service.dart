import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksync/core/constants/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'socket_service.g.dart';

@riverpod
class SocketService extends _$SocketService {
  ServerSocket? _server;

  @override
  void build() {
    ref.onDispose(() {
      stopServer();
    });
  }

  Future<void> startServer() async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, int.parse(AppConstants.defaultPort));
    _server!.listen((client) {
      _handleIncomingConnection(client);
    });
  }

  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
  }

  void _handleIncomingConnection(Socket client) {
    String? metadata;
    File? receiveFile;
    IOSink? sink;
    int receivedBytes = 0;
    int totalSize = 0;

    client.listen((data) async {
      if (metadata == null) {
        // Assume first packet is metadata
        metadata = String.fromCharCodes(data).trim();
        final parts = metadata!.split(':');
        if (parts.length == 3 && parts[0] == 'METADATA') {
          final fileName = parts[1];
          totalSize = int.parse(parts[2]);
          final directory = await Directory.systemTemp.createTemp('linksync');
          receiveFile = File('${directory.path}/$fileName');
          sink = receiveFile!.openWrite();
          client.write('READY');
        }
      } else {
        sink?.add(data);
        receivedBytes += data.length;
        // TODO: Update progress in UI via TransferQueue
        if (receivedBytes >= totalSize) {
          await sink?.close();
          client.write('COMPLETE');
          client.destroy();
        }
      }
    }, onDone: () async {
      await sink?.close();
    });
  }

  Future<void> sendFile(String ip, String filePath) async {
    final socket = await Socket.connect(ip, int.parse(AppConstants.defaultPort));
    final file = File(filePath);
    final totalSize = await file.length();
    
    // 1. Send metadata
    socket.write('METADATA:${file.uri.pathSegments.last}:$totalSize');
    
    // 2. Wait for READY (Simplified: just wait for some data)
    // In a real app, use a Completer for proper sync
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 3. Send file in chunks
    final stream = file.openRead();
    await socket.addStream(stream);
    
    await socket.flush();
    await socket.close();
  }
}
