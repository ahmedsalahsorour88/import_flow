import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing Focus Mode (وضع التركيز).
/// When Focus Mode is active, all peripheral headers, bars, and sidebars are
/// collapsed, giving 100% of the screen height to the active workspace.
final focusModeProvider = StateNotifierProvider<FocusModeNotifier, bool>((ref) {
  return FocusModeNotifier();
});

class FocusModeNotifier extends StateNotifier<bool> {
  FocusModeNotifier() : super(false);

  void toggle() => state = !state;
  void enable() => state = true;
  void disable() => state = false;
}
