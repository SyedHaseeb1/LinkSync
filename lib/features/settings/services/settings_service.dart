import 'package:flutter/foundation.dart';
import 'package:linksync/core/constants/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

part 'settings_service.g.dart';

@riverpod
class SettingsService extends _$SettingsService {
  static const _keyDeviceId = 'device_id';
  static const _keyDeviceName = 'device_name';
  static const _keySavePath = 'save_path';
  static const _keySessionPin = 'session_pin';

  @override
  FutureOr<Map<String, String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? deviceId = prefs.getString(_keyDeviceId);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_keyDeviceId, deviceId);
    }

    String? deviceName = prefs.getString(_keyDeviceName);
    if (deviceName == null) {
      deviceName = _getDefaultDeviceName();
      await prefs.setString(_keyDeviceName, deviceName);
    }

    String? savePath = prefs.getString(_keySavePath);
    if (savePath == null) {
      savePath = await _getDefaultSavePath();
      await prefs.setString(_keySavePath, savePath);
    }

    // Ephemeral PIN for the current session
    String? sessionPin = prefs.getString(_keySessionPin);
    if (sessionPin == null) {
      // Generate 4-digit PIN
      sessionPin = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
      await prefs.setString(_keySessionPin, sessionPin);
    }

    return {
      'id': deviceId,
      'name': deviceName,
      'savePath': savePath,
      'pin': sessionPin,
    };
  }

  String _getDefaultDeviceName() {
    if (kIsWeb) return 'Web Browser';
    return Platform.localHostname;
  }

  Future<String> _getDefaultSavePath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/LinkSync';
    }
    final directory = await getApplicationDocumentsDirectory();
    final linkSyncDir = Directory('${directory.path}/LinkSync');
    if (!await linkSyncDir.exists()) {
      await linkSyncDir.create(recursive: true);
    }
    return linkSyncDir.path;
  }

  Future<void> updateName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceName, name);
    state = AsyncData({
      ...state.value!,
      'name': name,
    });
  }

  Future<void> updateSavePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavePath, path);
    state = AsyncData({
      ...state.value!,
      'savePath': path,
    });
  }
}
