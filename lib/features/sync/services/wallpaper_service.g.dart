// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallpaper_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WallpaperService)
final wallpaperServiceProvider = WallpaperServiceProvider._();

final class WallpaperServiceProvider
    extends $NotifierProvider<WallpaperService, void> {
  WallpaperServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wallpaperServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wallpaperServiceHash();

  @$internal
  @override
  WallpaperService create() => WallpaperService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$wallpaperServiceHash() => r'c0b22ae0328e46fcab8993da8974255435d7bf96';

abstract class _$WallpaperService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
