import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Single record of a performance measurement run for a screen or modal.
class ScreenPerfRecord {
  final String screenName;
  final int runNumber;
  final String buildMode; // 'debug' | 'profile' | 'release'
  final double navInMs;
  final double firstFrameMs;
  final double interactiveMs;
  final double disposeMs;
  final double backendCallMsEntry;
  final double backendCallMsExit;
  final DateTime timestamp;
  final String? note;

  const ScreenPerfRecord({
    required this.screenName,
    required this.runNumber,
    required this.buildMode,
    required this.navInMs,
    required this.firstFrameMs,
    required this.interactiveMs,
    required this.disposeMs,
    required this.backendCallMsEntry,
    required this.backendCallMsExit,
    required this.timestamp,
    this.note,
  });

  String toCsvLine() {
    return '$screenName, $runNumber, $buildMode, '
        '${navInMs.toStringAsFixed(1)}, ${firstFrameMs.toStringAsFixed(1)}, '
        '${interactiveMs.toStringAsFixed(1)}, ${disposeMs.toStringAsFixed(1)}, '
        '${backendCallMsEntry.toStringAsFixed(1)}, ${backendCallMsExit.toStringAsFixed(1)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'screen_name': screenName,
      'run_number': runNumber,
      'mode': buildMode,
      'nav_in_ms': navInMs,
      'first_frame_ms': firstFrameMs,
      'interactive_ms': interactiveMs,
      'dispose_ms': disposeMs,
      'backend_call_ms_entry': backendCallMsEntry,
      'backend_call_ms_exit': backendCallMsExit,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }
}

/// Central registry storing performance records for all screens.
class PerformanceMetricsRegistry {
  PerformanceMetricsRegistry._();
  static final PerformanceMetricsRegistry instance = PerformanceMetricsRegistry._();

  final List<ScreenPerfRecord> _records = [];

  List<ScreenPerfRecord> get records => List.unmodifiable(_records);

  void record(ScreenPerfRecord record) {
    _records.add(record);
    if (kDebugMode) {
      debugPrint('[PERF] ${record.toCsvLine()}');
    }
  }

  List<ScreenPerfRecord> getRecordsForScreen(String screenName) {
    return _records.where((r) => r.screenName == screenName).toList();
  }

  void clear() {
    _records.clear();
  }

  static String get currentBuildMode {
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }
}

/// NavigatorObserver subclass to automatically capture route transitions,
/// dialog opens, and dialog closes with precise timing hooks.
class NavigationPerfTracker extends NavigatorObserver {
  static final NavigationPerfTracker instance = NavigationPerfTracker._();
  NavigationPerfTracker._();

  final Map<Route<dynamic>, Stopwatch> _inflightPushes = {};
  final Map<Route<dynamic>, Stopwatch> _inflightPops = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = _getRouteName(route);
    if (routeName == null) return;

    final sw = Stopwatch()..start();
    _inflightPushes[route] = sw;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_inflightPushes.containsKey(route)) return;
      final elapsedFirstFrame = sw.elapsedMicroseconds / 1000.0;

      // Check for interactive ready after secondary frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final totalNavIn = sw.elapsedMicroseconds / 1000.0;
        _inflightPushes.remove(route);

        final runCount = PerformanceMetricsRegistry.instance
                .getRecordsForScreen(routeName)
                .length +
            1;

        PerformanceMetricsRegistry.instance.record(
          ScreenPerfRecord(
            screenName: routeName,
            runNumber: runCount,
            buildMode: PerformanceMetricsRegistry.currentBuildMode,
            navInMs: totalNavIn,
            firstFrameMs: elapsedFirstFrame,
            interactiveMs: totalNavIn,
            disposeMs: 0.0,
            backendCallMsEntry: 0.0,
            backendCallMsExit: 0.0,
            timestamp: DateTime.now(),
            note: 'Modal/Route Push',
          ),
        );
      });
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final routeName = _getRouteName(route);
    if (routeName == null) return;

    final sw = Stopwatch()..start();
    _inflightPops[route] = sw;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final elapsedPop = sw.elapsedMicroseconds / 1000.0;
      _inflightPops.remove(route);

      if (kDebugMode) {
        debugPrint('[PERF-POP] $routeName popped in ${elapsedPop.toStringAsFixed(1)}ms');
      }
    });
  }

  String? _getRouteName(Route<dynamic> route) {
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      return route.settings.name;
    }
    return route.runtimeType.toString();
  }
}

/// Workspace Tab performance tracker for the Desktop MultiTabWorkspaceBar
/// and IndexedStack inside HomeScreen.
class WorkspaceTabPerfTracker {
  WorkspaceTabPerfTracker._();
  static final WorkspaceTabPerfTracker instance = WorkspaceTabPerfTracker._();

  Stopwatch? _tabSwitchStopwatch;
  String? _pendingTabName;
  double _lastEntryBackendMs = 0.0;
  double _lastExitBackendMs = 0.0;

  void notifyBackendCallEntry(double durationMs) {
    _lastEntryBackendMs = durationMs;
  }

  void notifyBackendCallExit(double durationMs) {
    _lastExitBackendMs = durationMs;
  }

  /// Triggered when the user clicks a tab or sidebar navigation item
  void onTabSwitchStart(String tabName) {
    _pendingTabName = tabName;
    _tabSwitchStopwatch = Stopwatch()..start();
  }

  /// Triggered when the IndexedStack renders the frame for the active tab
  void onTabRendered(String tabName) {
    if (_pendingTabName != tabName || _tabSwitchStopwatch == null) return;

    final sw = _tabSwitchStopwatch!;
    final firstFrameMs = sw.elapsedMicroseconds / 1000.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final interactiveMs = sw.elapsedMicroseconds / 1000.0;
      sw.stop();
      _tabSwitchStopwatch = null;
      _pendingTabName = null;

      final runCount = PerformanceMetricsRegistry.instance
              .getRecordsForScreen(tabName)
              .length +
          1;

      PerformanceMetricsRegistry.instance.record(
        ScreenPerfRecord(
          screenName: tabName,
          runNumber: runCount,
          buildMode: PerformanceMetricsRegistry.currentBuildMode,
          navInMs: interactiveMs,
          firstFrameMs: firstFrameMs,
          interactiveMs: interactiveMs,
          disposeMs: 0.0,
          backendCallMsEntry: _lastEntryBackendMs,
          backendCallMsExit: 0.0,
          timestamp: DateTime.now(),
          note: 'Workspace Tab Switch IN',
        ),
      );
      _lastEntryBackendMs = 0.0;
    });
  }

  /// Triggered when a workspace tab is closed by the user
  void onTabClose(String tabName, double disposeMs) {
    final runCount = PerformanceMetricsRegistry.instance
            .getRecordsForScreen(tabName)
            .length +
        1;

    PerformanceMetricsRegistry.instance.record(
      ScreenPerfRecord(
        screenName: tabName,
        runNumber: runCount,
        buildMode: PerformanceMetricsRegistry.currentBuildMode,
        navInMs: 0.0,
        firstFrameMs: 0.0,
        interactiveMs: 0.0,
        disposeMs: disposeMs,
        backendCallMsEntry: 0.0,
        backendCallMsExit: _lastExitBackendMs,
        timestamp: DateTime.now(),
        note: 'Workspace Tab Close OUT',
      ),
    );
    _lastExitBackendMs = 0.0;
  }
}
