import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/workspace_tabs_provider.dart';
import '../../../core/theme/app_theme.dart';

class MultiTabWorkspaceBar extends ConsumerWidget {
  const MultiTabWorkspaceBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabsState = ref.watch(workspaceTabsProvider);
    final tabsNotifier = ref.read(workspaceTabsProvider.notifier);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabsState.tabs.length,
              itemBuilder: (context, index) {
                final tab = tabsState.tabs[index];
                final isActive = tab.id == tabsState.activeTabId;

                return GestureDetector(
                  onTap: () => tabsNotifier.selectTab(tab.id),
                  child: Container(
                    margin: const EdgeInsets.only(top: 4, right: 4, left: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(maxWidth: 220, minWidth: 100),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      border: isActive
                          ? Border.all(color: Colors.grey.shade300, width: 1.0)
                          : null,
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 15,
                          color: isActive ? AppTheme.cobalt : AppTheme.charcoal.withOpacity(0.7),

                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            tab.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              color: isActive ? AppTheme.charcoal : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (tab.isClosable) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => tabsNotifier.closeTab(tab.id),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                Icons.close,
                                size: 13,
                                color: isActive ? Colors.grey.shade600 : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Tab bar actions menu
          PopupMenuButton<String>(
            tooltip: 'خيارات النوافذ والتبويبات',
            icon: Icon(Icons.more_horiz, size: 18, color: Colors.grey.shade700),
            onSelected: (value) {
              if (value == 'close_others') {
                tabsNotifier.closeOtherTabs(tabsState.activeTabId);
              } else if (value == 'close_all') {
                tabsNotifier.closeAllTabs();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'close_others',
                child: Row(
                  children: [
                    Icon(Icons.tab_unselected_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('إغلاق التبويبات الأخرى', style: TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'close_all',
                child: Row(
                  children: [
                    Icon(Icons.close_fullscreen_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('إغلاق كل التبويبات الإضافية', style: TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
