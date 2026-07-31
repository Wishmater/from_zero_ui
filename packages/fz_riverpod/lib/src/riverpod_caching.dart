// References:
// https://github.com/rrousselGit/riverpod/issues/1664
// https://codeberg.org/lucavenir/riverpod_suite/src/commit/b7c64202f71e301962c517998c41c789a4938f18/packages/riverpod_swiss_knife/lib/src/ref/add_dispose_delay.dart

import "dart:async";

import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:fz_riverpod/src/fz_notifier.dart";

/// Extension on [Ref] to add a dispose delay.
extension AddDisposeDelayRef on Ref {
  /// Adds a delay before disposing the provider when all listeners are removed.
  ///
  /// This results in the provider being kept alive for at least the specified
  /// [delay] duration after the last listener is removed.
  void addDisposeDelay(Duration delay) {
    final link = keepAlive();

    Timer? timer;

    onCancel(() {
      timer = Timer(delay, link.close);
    });
    onResume(() {
      timer?.cancel();
    });
    onDispose(() {
      timer?.cancel();
    });
  }
}

/// Extension on [Ref] to add a max time to live.
extension AddMaxTimeToLiveRef on Ref {
  /// Adds a max ttl for the data in the provider.
  ///
  /// When a listener is added after the max ttl has been has been exceeded, the
  /// provider will be refreshed. The provider won't be refreshed until a new
  /// listener is added, even if ttl has been exceeded.
  void addMaxTimeToLive(Duration ttl) {
    final timestamp = DateTime.timestamp();
    var scheduled = false;
    final scheduleInvalidation = () {
      if (scheduled || DateTime.timestamp().difference(timestamp) < ttl) return;
      scheduled = true;
      // TODO: 1 calling invalidateSelf sync causes an error, find a clever way to do this on the same frame, instead of wasting a frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        invalidateSelfWhenUnpaused();
      });
    };
    onAddListener(scheduleInvalidation);
    onResume(scheduleInvalidation);
  }
}

/// Extension on [Ref] to safely invalidate a provider, deferring invalidation
/// if the provider is paused.
extension InvalidateWhenUnpausedRef on Ref {
  /// Invalidates the provider immediately if it is mounted and not paused.
  ///
  /// If the provider is paused, the invalidation is deferred until the next
  /// listener is added or the provider is resumed.
  void invalidateSelfWhenUnpaused() {
    if (mounted && !isPaused) {
      invalidateSelf();
      return;
    }
    var scheduled = false;
    final scheduleInvalidation = () {
      if (scheduled || !mounted || isPaused) return;
      scheduled = true;
      // TODO: 1 calling invalidateSelf sync causes an error, find a clever way to do this on the same frame, instead of wasting a frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scheduled = false;
        if (!mounted || isPaused) return;
        invalidateSelf();
      });
    };
    onAddListener(scheduleInvalidation);
    onResume(scheduleInvalidation);
  }
}

/// Extension on [Ref] to read the future from an [FzProviderInstance].
extension ReadFutureRef on Ref {
  /// Reads the future from the given [provider], ensuring the provider is
  /// listened to while the future is awaited, so it is not disposed prematurely.
  Future<T> readFuture<T>(NotifierProvider<FzAsyncNotifier<T>, T?> provider) async {
    final subscription = listen(provider.notifier, (_, _) {});
    try {
      return switch (provider) {
        NotifierProvider<FzFutureNotifier<T>, T?>() => read(provider.notifier).future,
        NotifierProvider<FzStreamNotifier<T>, T?>() => read(provider.notifier).stream.last,
        _ => throw Exception('Subtype of FzAsyncNotifier not handled: $runtimeType'),
      };
    } finally {
      subscription.close();
    }
  }
}

/// Extension on [WidgetRef] to read the future from an [FzProviderInstance].
extension ReadFutureWidgetRef on WidgetRef {
  /// Reads the future from the given [provider], ensuring the provider is
  /// listened to while the future is awaited, so it is not disposed prematurely.
  Future<T> readFuture<T>(NotifierProvider<FzAsyncNotifier<T>, T?> provider) async {
    final subscription = listenManual(provider.notifier, (_, _) {});
    try {
      return switch (provider) {
        NotifierProvider<FzFutureNotifier<T>, T?>() => read(provider.notifier).future,
        NotifierProvider<FzStreamNotifier<T>, T?>() => read(provider.notifier).stream.last,
        _ => throw Exception('Subtype of FzAsyncNotifier not handled: $runtimeType'),
      };
    } finally {
      subscription.close();
    }
  }
}

/// Extension on [ProviderContainer] to read the future from an [FzProviderInstance].
extension ReadFutureWidgetProviderContainer on ProviderContainer {
  /// Reads the future from the given [provider], ensuring the provider is
  /// listened to while the future is awaited, so it is not disposed prematurely.
  Future<T> readFuture<T>(NotifierProvider<FzAsyncNotifier<T>, T?> provider) async {
    final subscription = listen(provider.notifier, (_, _) {});
    try {
      return switch (provider) {
        NotifierProvider<FzFutureNotifier<T>, T?>() => read(provider.notifier).future,
        NotifierProvider<FzStreamNotifier<T>, T?>() => read(provider.notifier).stream.last,
        _ => throw Exception('Subtype of FzAsyncNotifier not handled: $runtimeType'),
      };
    } finally {
      subscription.close();
    }
  }
}

/// Unified wrapper around [Ref]/[WidgetRef]/[ProviderContainer] providing
/// a common interface for provider operations without coupling to a specific
/// Riverpod type.
///
/// Use [RefWrapperRefExtension] or [RefWrapperProviderContainerExtension]
/// to obtain a [RefWrapper] from a [Ref], [WidgetRef], or [ProviderContainer].
abstract class RefWrapper {
  T read<T>(ProviderListenable<T> provider);
  void invalidate(ProviderOrFamily provider);
  T refresh<T>(Refreshable<T> provider);
  Future<T> readFuture<T extends Object>(ApiProviderInstance<T> provider);
}

final class _RefRefWrapper implements RefWrapper {
  final Ref _ref;
  _RefRefWrapper(this._ref);

  @override
  T read<T>(ProviderListenable<T> provider) => _ref.read(provider);
  @override
  void invalidate(ProviderOrFamily provider) => _ref.invalidate(provider);
  @override
  T refresh<T>(Refreshable<T> provider) => _ref.refresh(provider);
  @override
  Future<T> readFuture<T extends Object>(ApiProviderInstance<T> provider) => _ref.readFuture(provider);
}

final class _WidgetRefRefWrapper implements RefWrapper {
  final WidgetRef _ref;
  _WidgetRefRefWrapper(this._ref);

  @override
  T read<T>(ProviderListenable<T> provider) => _ref.read(provider);
  @override
  void invalidate(ProviderOrFamily provider) => _ref.invalidate(provider);
  @override
  T refresh<T>(Refreshable<T> provider) => _ref.refresh(provider);
  @override
  Future<T> readFuture<T extends Object>(ApiProviderInstance<T> provider) => _ref.readFuture(provider);
}

final class _ProviderContainerRefWrapper implements RefWrapper {
  final ProviderContainer _container;
  _ProviderContainerRefWrapper(this._container);

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);
  @override
  void invalidate(ProviderOrFamily provider) => _container.invalidate(provider);
  @override
  T refresh<T>(Refreshable<T> provider) => _container.refresh(provider);
  @override
  Future<T> readFuture<T extends Object>(ApiProviderInstance<T> provider) => _container.readFuture(provider);
}

extension RefWrapperRefExtension on Ref {
  RefWrapper get wrap => _RefRefWrapper(this);
}

extension RefWrapperWidgetRefExtension on WidgetRef {
  RefWrapper get wrap => _WidgetRefRefWrapper(this);
}

extension RefWrapperProviderContainerExtension on ProviderContainer {
  RefWrapper get wrap => _ProviderContainerRefWrapper(this);
}
