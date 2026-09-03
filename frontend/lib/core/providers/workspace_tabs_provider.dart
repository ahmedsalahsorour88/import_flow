import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkspaceTab {
  final String id;
  final String title;
  final IconData icon;
  final int routeIndex;
  final bool isClosable;

  const WorkspaceTab({
    required this.id,
    required this.title,
    required this.icon,
    required this.routeIndex,
    this.isClosable = true,
  });

  WorkspaceTab copyWith({
    String? id,
    String? title,
    IconData? icon,
    int? routeIndex,
    bool? isClosable,
  }) {
    return WorkspaceTab(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      routeIndex: routeIndex ?? this.routeIndex,
      isClosable: isClosable ?? this.isClosable,
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
      state = state.copyWith(activeTabId: state.tabs[existingIndex].id);
    } else {
      final newTab = WorkspaceTab(
        id: id,
        title: title,
        icon: icon,
        routeIndex: routeIndex,
        isClosable: isClosable,
      );
      state = state.copyWith(
        tabs: [...state.tabs, newTab],
        activeTabId: id,
      );
    }
  }

  void selectTab(String tabId) {
    if (state.tabs.any((t) => t.id == tabId)) {
      state = state.copyWith(activeTabId: tabId);
    }
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
}

final workspaceTabsProvider = StateNotifierProvider<WorkspaceTabsNotifier, WorkspaceTabsState>(
  (ref) => WorkspaceTabsNotifier(),
);
