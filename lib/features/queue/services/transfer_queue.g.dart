// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_queue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransferQueue)
final transferQueueProvider = TransferQueueProvider._();

final class TransferQueueProvider
    extends $AsyncNotifierProvider<TransferQueue, List<SyncTask>> {
  TransferQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferQueueHash();

  @$internal
  @override
  TransferQueue create() => TransferQueue();
}

String _$transferQueueHash() => r'b87f12ec6c2ae3586c6c84a2bebe34f942551061';

abstract class _$TransferQueue extends $AsyncNotifier<List<SyncTask>> {
  FutureOr<List<SyncTask>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<SyncTask>>, List<SyncTask>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SyncTask>>, List<SyncTask>>,
              AsyncValue<List<SyncTask>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
