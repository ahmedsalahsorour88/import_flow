import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Top header toolbar for [EnterpriseDataTable].
class EnterpriseTableHeaderToolbar extends StatelessWidget {
  final String? title;
  final Widget? titleLeading;
  final int totalCount;
  final int filteredCount;
  final int selectedCount;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onClearSearch;
  final VoidCallback onOpenColumnPicker;
  final VoidCallback? onExportCSV;
  final VoidCallback? onCopyToClipboard;
  final List<Widget>? extraActions;
  final Widget? bulkActions;

  const EnterpriseTableHeaderToolbar({
    super.key,
    this.title,
    this.titleLeading,
    required this.totalCount,
    required this.filteredCount,
    required this.selectedCount,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onClearSearch,
    required this.onOpenColumnPicker,
    this.onExportCSV,
    this.onCopyToClipboard,
    this.extraActions,
    this.bulkActions,
  });

  @override
  Widget build(BuildContext context) {
    final hasSearchFilter = searchQuery.isNotEmpty && filteredCount != totalCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title, counts, actions (Scroll-safe for any window width)
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left group: Title + Count + Selected Badges
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (titleLeading != null) ...[
                            titleLeading!,
                            const SizedBox(width: 8),
                          ],
                          if (title != null) ...[
                            Text(
                              title!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.charcoal,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],

                          // Record Count Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.cobalt.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                            ),
                            child: Text(
                              hasSearchFilter
                                  ? '$filteredCount من $totalCount سجل'
                                  : '$totalCount سجل',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.cobalt,
                              ),
                            ),
                          ),

                          if (selectedCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.emerald.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 13, color: AppTheme.emerald),
                                  const SizedBox(width: 4),
                                  Text(
                                    'تم تحديد $selectedCount',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.emerald,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(width: 16),

                      // Right group: Buttons & Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bulk Actions if items selected
                          if (selectedCount > 0 && bulkActions != null) ...[
                            bulkActions!,
                            const SizedBox(width: 8),
                          ],

                          // Extra Custom Actions
                          if (extraActions != null) ...[
                            ...extraActions!,
                            const SizedBox(width: 8),
                          ],

                          // Column Layout Button
                          Tooltip(
                            message: 'تخصيص وترتيب أعمدة الجدول',
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              onPressed: onOpenColumnPicker,
                              icon: const Icon(Icons.view_column_outlined, size: 16, color: AppTheme.charcoal),
                              label: const Text(
                                'الأعمدة',
                                style: TextStyle(fontSize: 12, color: AppTheme.charcoal),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Export Excel/CSV Button
                          if (onExportCSV != null) ...[
                            Tooltip(
                              message: 'تصدير الجدول إلى Excel / CSV',
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  side: const BorderSide(color: AppTheme.emerald),
                                  foregroundColor: AppTheme.emerald,
                                ),
                                onPressed: onExportCSV,
                                icon: const Icon(Icons.table_chart_outlined, size: 16, color: AppTheme.emerald),
                                label: const Text(
                                  'تصدير Excel',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Copy to Clipboard
                          if (onCopyToClipboard != null) ...[
                            Tooltip(
                              message: 'نسخ محتويات الجدول للحافظة بتنسيق Excel',
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  side: BorderSide(color: Colors.grey.shade400),
                                  foregroundColor: AppTheme.charcoal,
                                ),
                                onPressed: onCopyToClipboard,
                                icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.charcoal),
                                label: const Text(
                                  'نسخ للحافظة',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // Row 2: Instant Search Box
          SizedBox(
            height: 38,
            child: TextField(
              controller: TextEditingController(text: searchQuery)
                ..selection = TextSelection.collapsed(offset: searchQuery.length),
              decoration: InputDecoration(
                hintText: 'بحث فوري في كافة أعمدة وبيانات الجدول...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: onClearSearch ?? () => onSearchChanged(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.cobalt, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }
}
