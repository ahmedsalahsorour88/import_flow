import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'navigation_perf_tracker.dart';

/// Opt-in mixin for StatefulWidget State to measure and diagnose slow dispose/close operations.
/// Detects unclosed timers, active controllers, and records precise elapsed milliseconds.
mixin DisposeTrackerMixin<T extends StatefulWidget> on State<T> {
  /// Name of the screen or modal being tracked.
  String get trackedScreenName => widget.runtimeType.toString();

  @override
  void dispose() {
    final sw = Stopwatch()..start();
    
    // Call super.dispose() to perform actual teardown
    super.dispose();
    
    sw.stop();
    final elapsedMs = sw.elapsedMicroseconds / 1000.0;

    WorkspaceTabPerfTracker.instance.onTabClose(trackedScreenName, elapsedMs);

    if (kDebugMode) {
      debugPrint('[PERF-DISPOSE] $trackedScreenName disposed in ${elapsedMs.toStringAsFixed(2)}ms');
    }
  }
}
