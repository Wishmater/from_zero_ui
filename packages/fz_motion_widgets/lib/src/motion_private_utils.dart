extension ClampNullable<T extends num> on T {
  T clampNullable(T? a, [T? b]) => clamp(a ?? -double.maxFinite, b ?? double.maxFinite) as T;
}