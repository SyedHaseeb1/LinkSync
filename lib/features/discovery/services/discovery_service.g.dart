// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DiscoveryService)
final discoveryServiceProvider = DiscoveryServiceProvider._();

final class DiscoveryServiceProvider
    extends $NotifierProvider<DiscoveryService, List<Device>> {
  DiscoveryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveryServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveryServiceHash();

  @$internal
  @override
  DiscoveryService create() => DiscoveryService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Device> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Device>>(value),
    );
  }
}

String _$discoveryServiceHash() => r'b26872b5992981031e659ac1611dda14ed54343c';

abstract class _$DiscoveryService extends $Notifier<List<Device>> {
  List<Device> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Device>, List<Device>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Device>, List<Device>>,
              List<Device>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
