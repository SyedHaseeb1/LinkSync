import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksync/features/queue/models/sync_task.dart';
import 'package:linksync/features/queue/repositories/database_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_queue.g.dart';

@Riverpod(keepAlive: true)
class TransferQueue extends _$TransferQueue {
  final _db = DatabaseRepository();

  @override
  Future<List<SyncTask>> build() async {
    return _db.getAllTasks();
  }

  Future<void> addTask(SyncTask task) async {
    await _db.insertTask(task);
    state = AsyncData([task, ...?state.value]);
  }

  Future<void> updateProgress(String id, double progress, SyncTaskStatus status, [double speed = 0.0]) async {
    await _db.updateTaskProgress(id, progress, status, speed);
    if (state.hasValue) {
      state = AsyncData(state.value!.map((t) {
        if (t.id == id) {
          return t.copyWith(progress: progress, status: status, speed: speed);
        }
        return t;
      }).toList());
    }
  }

  Future<void> removeTask(String id) async {
    await _db.deleteTask(id);
    if (state.hasValue) {
      state = AsyncData(state.value!.where((t) => t.id != id).toList());
    }
  }
}
