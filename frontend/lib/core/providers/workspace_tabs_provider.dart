import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkspaceTab {
  final String id;
  final String title;
  final IconData icon;
  final int routeIndex;
  final bool isClosable;
  final bool isDirty;

  const WorkspaceTab({
    required this.id,
    required this.title,
    required this.icon,
    required this.routeIndex,
    this.isClosable = true,
    this.isDirty = false,
  });

  WorkspaceTab copyWith({
    String? id,
    String? title,
    IconData? icon,
    int? routeIndex,
    bool? isClosable,
    bool? isDirty,
  }) {
    return WorkspaceTab(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      routeIndex: routeIndex ?? this.routeIndex,
      isClosable: isClosable ?? this.isClosable,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceTab && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class WorkspaceTabsState {
  final List<WorkspaceTab> tabs;
  final String activeTabId;

  const WorkspaceTabsState({
    required this.tabs,
    required this.activeTabId,
  });

  WorkspaceTab? get activeTab {
    final idx = tabs.indexWhere((t) => t.id == activeTabId);
    return idx != -1 ? tabs[idx] : (tabs.isNotEmpty ? tabs.first : null);
  }

  WorkspaceTabsState copyWith({
    List<WorkspaceTab>? tabs,
    String? activeTabId,
  }) {
    return WorkspaceTabsState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId ?? this.activeTabId,
    );
  }
}

class WorkspaceTabsNotifier extends StateNotifier<WorkspaceTabsState> {
  static const int maxTabs = 10;

  WorkspaceTabsNotifier()
      : super(
          const WorkspaceTabsState(
            tabs: [
              WorkspaceTab(
                id: 'dashboard',
                title: 'لوحة التحكم',
                icon: Icons.dashboard_customize_outlined,
                routeIndex: 0,
                isClosable: false,
              ),
            ],
            activeTabId: 'dashboard',
          ),
        );

  void openTab({
    required String id,
    required String title,
    required IconData icon,
    required int routeIndex,
    bool isClosable = true,
  }) {
    final existingIndex = state.tabs.indexWhere(
      (t) => t.id == id || (t.routeIndex == routeIndex && t.title == title),
    );

    if (existingIndex != -1) {
      // Tab already open — just switch to it
      state = state.copyWith(activeTabId: state.tabs[existingIndex].id);
      return;
    }

    // Enforce max tabs: close the oldest closable tab if at limit
    List<WorkspaceTab> tabs = [...state.tabs];
    if (tabs.length >= maxTabs) {
      final oldestClosable = tabs.indexWhere((t) => t.isClosable);
      if (oldestClosable != -1) {
        tabs.removeAt(oldestClosable);
      }
    }

    final newTab = WorkspaceTab(
      id: id,
      title: title,
      icon: icon,
      routeIndex: routeIndex,
      isClosable: isClosable,
    );
    state = state.copyWith(
      tabs: [...tabs, newTab],
      activeTabId: id,
    );
  }

  void selectTab(String tabId) {
    if (state.tabs.any((t) => t.id == tabId)) {
      state = state.copyWith(activeTabId: tabId);
    }
  }

  void setTabDirty(String tabId, bool isDirty) {
    final updatedTabs = state.tabs.map((tab) {
      if (tab.id == tabId) {
        return tab.copyWith(isDirty: isDirty);
      }
      return tab;
    }).toList();
    state = state.copyWith(tabs: updatedTabs);
  }

  void setActiveTabDirty(bool isDirty) {
    setTabDirty(state.activeTabId, isDirty);
  }

  void closeTab(String tabId) {
    final target = state.tabs.firstWhere(
      (t) => t.id == tabId,
      orElse: () => state.tabs.first,
    );
    if (!target.isClosable) return;

    final newTabs = state.tabs.where((t) => t.id != tabId).toList();
    if (newTabs.isEmpty) return;

    String newActiveId = state.activeTabId;
    if (state.activeTabId == tabId) {
      final oldIndex = state.tabs.indexWhere((t) => t.id == tabId);
      final newIndex = (oldIndex - 1).clamp(0, newTabs.length - 1);
      newActiveId = newTabs[newIndex].id;
    }

    state = state.copyWith(
      tabs: newTabs,
      activeTabId: newActiveId,
    );
  }

  void closeOtherTabs(String keepTabId) {
    final keepTab = state.tabs.firstWhere(
      (t) => t.id == keepTabId,
      orElse: () => state.tabs.first,
    );
    final unclosable = state.tabs.where((t) => !t.isClosable && t.id != keepTabId).toList();
    state = state.copyWith(
      tabs: [...unclosable, keepTab],
      activeTabId: keepTab.id,
    );
  }

  void closeAllTabs() {
    final unclosable = state.tabs.where((t) => !t.isClosable).toList();
    if (unclosable.isNotEmpty) {
      state = state.copyWith(
        tabs: unclosable,
        activeTabId: unclosable.first.id,
      );
    }
  }

  WorkspaceTab? selectNextTab() {
    if (state.tabs.length <= 1) return state.activeTab;
    final currentIdx = state.tabs.indexWhere((t) => t.id == state.activeTabId);
    final nextIdx = (currentIdx + 1) % state.tabs.length;
    final nextTab = state.tabs[nextIdx];
    state = state.copyWith(activeTabId: nextTab.id);
    return nextTab;
  }

  WorkspaceTab? selectPreviousTab() {
    if (state.tabs.length <= 1) return state.activeTab;
    final currentIdx = state.tabs.indexWhere((t) => t.id == state.activeTabId);
    final prevIdx = (currentIdx - 1 + state.tabs.length) % state.tabs.length;
    final prevTab = state.tabs[prevIdx];
    state = state.copyWith(activeTabId: prevTab.id);
    return prevTab;
  }

  WorkspaceTab? closeActiveTab() {
    final active = state.activeTab;
    if (active != null && active.isClosable) {
      closeTab(active.id);
      return state.activeTab;
    }
    return active;
  }
}

final workspaceTabsProvider = StateNotifierProvider<WorkspaceTabsNotifier, WorkspaceTabsState>(
  (ref) => WorkspaceTabsNotifier(),
);
