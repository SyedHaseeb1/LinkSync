enum SyncTaskType {
  sendFile,
  receiveFile,
  folderSync,
  wallpaperSync,
}

enum SyncTaskStatus {
  queued,
  running,
  paused,
  completed,
  failed,
}

class SyncTask {
  final String id;
  final SyncTaskType type;
  final String sourceDeviceId;
  final String targetDeviceId;
  final String targetDeviceName;
  final String filePath;
  final int fileSize;
  final double progress;
  final double speed;
  final SyncTaskStatus status;
  final DateTime createdAt;

  SyncTask({
    required this.id,
    required this.type,
    required this.sourceDeviceId,
    required this.targetDeviceId,
    required this.targetDeviceName,
    required this.filePath,
    required this.fileSize,
    this.progress = 0.0,
    this.speed = 0.0,
    required this.status,
    required this.createdAt,
  });

  SyncTask copyWith({
    double? progress,
    double? speed,
    SyncTaskStatus? status,
  }) {
    return SyncTask(
      id: id,
      type: type,
      sourceDeviceId: sourceDeviceId,
      targetDeviceId: targetDeviceId,
      targetDeviceName: targetDeviceName,
      filePath: filePath,
      fileSize: fileSize,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'sourceDeviceId': sourceDeviceId,
      'targetDeviceId': targetDeviceId,
      'targetDeviceName': targetDeviceName,
      'filePath': filePath,
      'fileSize': fileSize,
      'progress': progress,
      'speed': speed,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncTask.fromMap(Map<String, dynamic> map) {
    return SyncTask(
      id: map['id'],
      type: SyncTaskType.values[map['type']],
      sourceDeviceId: map['sourceDeviceId'],
      targetDeviceId: map['targetDeviceId'],
      targetDeviceName: map['targetDeviceName'],
      filePath: map['filePath'],
      fileSize: map['fileSize'],
      progress: map['progress'],
      speed: map['speed'] ?? 0.0,
      status: SyncTaskStatus.values[map['status']],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
