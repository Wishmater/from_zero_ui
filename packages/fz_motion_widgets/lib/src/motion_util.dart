import "package:flutter/physics.dart";
import "package:motor/motor.dart";
// ignore: implementation_imports
import "package:motor/src/simulations/no_motion_simulation.dart";

class InstantMotion extends NoMotion {
  const InstantMotion([super.duration = Duration.zero]);

  @override
  String toString() => "InstantMotion($duration)";

  @override
  Simulation createSimulation({
    double start = 0,
    double end = 1,
    double velocity = 0,
  }) {
    return NoMotionSimulation(
      duration: duration,
      value: end,
      tolerance: tolerance,
    );
  }
}