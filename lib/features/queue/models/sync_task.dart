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
  final String filePath;
  final int fileSize;
  final double progress;
  final SyncTaskStatus status;
  final DateTime createdAt;

  SyncTask({
    required this.id,
    required this.type,
    required this.sourceDeviceId,
    required this.targetDeviceId,
    required this.filePath,
    required this.fileSize,
    this.progress = 0.0,
    required this.status,
    required this.createdAt,
  });

  SyncTask copyWith({
    double? progress,
    SyncTaskStatus? status,
  }) {
    return SyncTask(
      id: id,
      type: type,
      sourceDeviceId: sourceDeviceId,
      targetDeviceId: targetDeviceId,
      filePath: filePath,
      fileSize: fileSize,
      progress: progress ?? this.progress,
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
      'filePath': filePath,
      'fileSize': fileSize,
      'progress': progress,
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
      filePath: map['filePath'],
      fileSize: map['fileSize'],
      progress: map['progress'],
      status: SyncTaskStatus.values[map['status']],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
