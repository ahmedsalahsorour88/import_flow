import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Bottom pagination bar for [EnterpriseDataTable].
class EnterpriseTablePaginationBar extends StatelessWidget {
  final int totalCount;
  final int currentPage; // 1-indexed
  final int pageSize; // items per page, e.g. 10, 25, 50, 100, -1 for All
  final List<int> availablePageSizes;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const EnterpriseTablePaginationBar({
    super.key,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    this.availablePageSizes = const [10, 25, 50, 100],
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    final isAll = pageSize <= 0;
    final totalPages = isAll ? 1 : (totalCount / pageSize).ceil();
    final clampedCurrentPage = currentPage.clamp(1, totalPages > 0 ? totalPages : 1);

    final startItem = isAll ? 1 : ((clampedCurrentPage - 1) * pageSize + 1);
    final endItem = isAll ? totalCount : (clampedCurrentPage * pageSize).clamp(0, totalCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Items per page selector & Range text
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'الصفوف بالصفحة:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: availablePageSizes.contains(pageSize) ? pageSize : availablePageSizes.first,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                        items: [
                          ...availablePageSizes.map((size) {
                            return DropdownMenuItem<int>(
                              value: size,
                              child: Text('$size'),
                            );
                          }),
                          const DropdownMenuItem<int>(
                            value: -1,
                            child: Text('الكل'),
                          ),
                        ],
                        onChanged: (newSize) {
                          if (newSize != null) onPageSizeChanged(newSize);
                        },
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'عرض $startItem - $endItem من إجمالي $totalCount',
                        style: const TextStyle(fontSize: 12, color: AppTheme.charcoal),
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Right: Page navigation controls
                  if (!isAll && totalPages > 1)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // First Page
                        IconButton(
                          tooltip: 'الصفحة الأولى',
                          icon: const Icon(Icons.first_page_rounded, size: 20),
                          onPressed: clampedCurrentPage > 1 ? () => onPageChanged(1) : null,
                        ),

                        // Previous Page
                        IconButton(
                          tooltip: 'الصفحة السابقة',
                          icon: const Icon(Icons.chevron_left_rounded, size: 20),
                          onPressed: clampedCurrentPage > 1 ? () => onPageChanged(clampedCurrentPage - 1) : null,
                        ),

                        // Page Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            '$clampedCurrentPage / $totalPages',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                          ),
                        ),

                        // Next Page
                        IconButton(
                          tooltip: 'الصفحة التالية',
                          icon: const Icon(Icons.chevron_right_rounded, size: 20),
                          onPressed: clampedCurrentPage < totalPages ? () => onPageChanged(clampedCurrentPage + 1) : null,
                        ),

                        // Last Page
                        IconButton(
                          tooltip: 'الصفحة الأخيرة',
                          icon: const Icon(Icons.last_page_rounded, size: 20),
                          onPressed: clampedCurrentPage < totalPages ? () => onPageChanged(totalPages) : null,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
