import "package:flutter/widgets.dart";

AnimationStatus? consolidateAnimationStatus(List<AnimationStatus?> initStates) {
  final states = initStates.nonNulls;
  if (states.isEmpty) return null;
  if (states.length == 1) return states.first;
  final status = AnimationStatusPriorities.highestPriority(states);
  if (states.any((e) => e != status)) {
    return AnimationPriorities.subdue(status);
  }
  return status;
}

extension AnimationPriorities on AnimationStatus {
  static AnimationStatus subdue(AnimationStatus status) {
    return switch (status) {
      AnimationStatus.forward => AnimationStatus.forward,
      AnimationStatus.reverse => AnimationStatus.reverse,
      AnimationStatus.completed => AnimationStatus.completed,
      AnimationStatus.dismissed => AnimationStatus.dismissed,
    };
  }
}

extension AnimationStatusPriorities on AnimationStatus {
  static AnimationStatus highestPriority(Iterable<AnimationStatus?> statuses) {
    return statuses.nonNulls.fold(AnimationStatus.dismissed, (a, b) {
      if (a.index > b.index) {
        return a;
      }
      return b;
    });
  }
}

extension Pipe on Object {
  T pipe<T>(T Function(T) f) {
    return f(this as T);
  }
}