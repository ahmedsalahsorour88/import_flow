import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workspace_tabs_provider.dart';
import 'unsaved_changes_dialog.dart';

/// Reusable navigation guard that protects unsaved form changes.
/// Synchronizes dirty state with the active workspace tab and intercepts
/// route pop events with [UnsavedChangesDialog].
class UnsavedChangesGuard extends ConsumerStatefulWidget {
  final Widget child;
  final bool isDirty;
  final String? tabId;
  final String? customMessage;
  final VoidCallback? onSave;

  const UnsavedChangesGuard({
    super.key,
    required this.child,
    required this.isDirty,
    this.tabId,
    this.customMessage,
    this.onSave,
  });

  @override
  ConsumerState<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends ConsumerState<UnsavedChangesGuard> {
  @override
  void initState() {
    super.initState();
    _syncDirtyState(widget.isDirty);
  }

  @override
  void didUpdateWidget(covariant UnsavedChangesGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDirty != widget.isDirty) {
      _syncDirtyState(widget.isDirty);
    }
  }

  @override
  void dispose() {
    _syncDirtyState(false);
    super.dispose();
  }

  void _syncDirtyState(bool dirty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetTabId = widget.tabId;
      final notifier = ref.read(workspaceTabsProvider.notifier);
      if (targetTabId != null) {
        notifier.setTabDirty(targetTabId, dirty);
      } else {
        notifier.setActiveTabDirty(dirty);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await UnsavedChangesDialog.show(
          context,
          customMessage: widget.customMessage,
          onSave: widget.onSave,
        );
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: widget.child,
    );
  }
}
