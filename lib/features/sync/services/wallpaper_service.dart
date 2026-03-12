import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksync/features/transfer/services/socket_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallpaper_service.g.dart';

@riverpod
class WallpaperService extends _$WallpaperService {
  @override
  void build() {}

  Future<void> syncWallpaper(String targetIp, String imagePath) async {
    // 1. Send the image file using SocketService
    await ref.read(socketServiceProvider.notifier).sendFile(targetIp, imagePath);
    
    // 2. The receiver side needs to detect it's a wallpaper and apply it
    // In a full implementation, we'd use a channel/plugin to set wallpaper
  }

  Future<void> applyWallpaper(String imagePath) async {
    // TODO: Use a platform channel to set wallpaper
    // Example: MethodChannel('wallpaper').invokeMethod('setWallpaper', imagePath);
  }
}
