import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../theme/density_provider.dart';

/// Reusable Single Compact Toolbar for ImportFlow ERP screens (Type B List/Index).
///
/// Implements:
/// - Single unified compact toolbar row (max 40px tall, down to 30px in Ultra-Compact).
/// - Up to 3 primary inline buttons.
/// - Overflow "More actions ⋮" dropdown with [PopupMenuPosition.under] and anti-collision offset.
/// - Inline search bar with instant clear button and density-scaled height.
/// - Inline filters and quick data actions (Export, Refresh, Copy TSV).
class ActionToolbar extends ConsumerWidget {
  final List<Widget>? primaryActions;
  final List<PopupMenuEntry<String>>? moreActionItems;
  final ValueChanged<String>? onMoreActionSelected;
  final TextEditingController? searchController;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget>? filters;
  final List<Widget>? quickDataActions;
  final Widget? trailing;

  const ActionToolbar({
    super.key,
    this.primaryActions,
    this.moreActionItems,
    this.onMoreActionSelected,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
    this.filters,
    this.quickDataActions,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(displayDensityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        if (isMobile) {
          return _buildMobileToolbar(context, isDark, density);
        }

        return Container(
          constraints: BoxConstraints(minHeight: density.toolbarHeight),
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: (density.toolbarHeight - density.buttonHeight) / 2,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : Colors.black12,
              width: 0.8,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth > 16 ? constraints.maxWidth - 16 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Side: Primary Actions, More Actions, Divider, Search, Filters
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Primary Actions (max 3)
                      if (primaryActions != null && primaryActions!.isNotEmpty) ...[
                        for (int i = 0; i < primaryActions!.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          primaryActions![i],
                        ],
                        const SizedBox(width: 8),
                      ],

                      // 2. More Actions Dropdown Menu (⋮)
                      if (moreActionItems != null && moreActionItems!.isNotEmpty) ...[
                        Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: PopupMenuThemeData(
                              position: PopupMenuPosition.under,
                              elevation: 6,
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                          child: SizedBox(
                            height: density.buttonHeight,
                            width: density.buttonHeight,
                            child: PopupMenuButton<String>(
                              tooltip: 'إجراءات إضافية',
                              icon: Icon(
                                Icons.more_vert,
                                size: density.buttonIconSize + 2,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.charcoal,
                              ),
                              padding: EdgeInsets.zero,
                              offset: const Offset(0, 4),
                              onSelected: onMoreActionSelected,
                              itemBuilder: (ctx) => moreActionItems!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Divider between actions and search/filters
                      if ((primaryActions != null && primaryActions!.isNotEmpty) ||
                          (moreActionItems != null && moreActionItems!.isNotEmpty)) ...[
                        Container(
                          height: density.buttonHeight * 0.7,
                          width: 1,
                          color: isDark ? AppTheme.darkBorder : Colors.black12,
                        ),
                        const SizedBox(width: 8),
                      ],

                      // 3. Inline Search Bar
                      if (searchController != null) ...[
                        SizedBox(
                          width: 210,
                          height: density.buttonHeight,
                          child: TextField(
                            controller: searchController,
                            onChanged: onSearchChanged,
                            style: TextStyle(fontSize: density.inputFontSize),
                            decoration: InputDecoration(
                              hintText: searchHint ?? 'بحث سريع...',
                              hintStyle: TextStyle(
                                fontSize: density.inputFontSize,
                                color: isDark ? AppTheme.darkTextSecondary : Colors.black45,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: density.buttonIconSize,
                                color: isDark ? AppTheme.darkTextSecondary : Colors.black45,
                              ),
                              prefixIconConstraints: BoxConstraints(
                                minWidth: density.buttonHeight,
                                minHeight: density.buttonHeight,
                              ),
                              suffixIcon: (searchController!.text.isNotEmpty)
                                  ? IconButton(
                                      icon: Icon(Icons.clear, size: density.buttonIconSize - 2),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(
                                        minWidth: density.buttonHeight * 0.8,
                                        minHeight: density.buttonHeight * 0.8,
                                      ),
                                      onPressed: () {
                                        searchController!.clear();
                                        onSearchChanged?.call('');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: isDark ? AppTheme.darkBorder : Colors.black26,
                                  width: 0.8,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: isDark ? AppTheme.darkBorder : Colors.black26,
                                  width: 0.8,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: AppTheme.cobalt, width: 1.2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // 4. Inline Filters
                      if (filters != null && filters!.isNotEmpty) ...[
                        for (int i = 0; i < filters!.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          filters![i],
                        ],
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),

                  // Right Side: Quick Data Actions & Trailing
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 5. Quick Data Actions (Refresh, Excel, PDF, TSV, etc.)
                      if (quickDataActions != null && quickDataActions!.isNotEmpty) ...[
                        for (int i = 0; i < quickDataActions!.length; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          quickDataActions![i],
                        ],
                      ],

                      if (trailing != null) ...[
                        const SizedBox(width: 6),
                        trailing!,
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileToolbar(BuildContext context, bool isDark, DisplayDensityMode density) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : Colors.black12,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (searchController != null) ...[
            SizedBox(
              height: density.buttonHeight,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: TextStyle(fontSize: density.inputFontSize),
                decoration: InputDecoration(
                  hintText: searchHint ?? 'بحث سريع...',
                  hintStyle: TextStyle(fontSize: density.inputFontSize),
                  prefixIcon: Icon(Icons.search, size: density.buttonIconSize),
                  suffixIcon: searchController!.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: density.buttonIconSize - 2),
                          onPressed: () {
                            searchController!.clear();
                            onSearchChanged?.call('');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (filters != null && filters!.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: filters!,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (primaryActions != null && primaryActions!.isNotEmpty)
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: primaryActions!,
                  ),
                ),
              if (moreActionItems != null && moreActionItems!.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  offset: const Offset(0, 4),
                  onSelected: onMoreActionSelected,
                  itemBuilder: (ctx) => moreActionItems!,
                ),
              if (quickDataActions != null && quickDataActions!.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: quickDataActions!),
            ],
          ),
        ],
      ),
    );
  }
}
