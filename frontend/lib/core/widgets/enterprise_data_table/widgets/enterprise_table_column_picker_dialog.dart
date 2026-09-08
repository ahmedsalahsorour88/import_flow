import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/enterprise_column.dart';

/// Interactive modal dialog allowing users to customize column visibility for [EnterpriseDataTable].
class EnterpriseTableColumnPickerDialog<T> extends StatefulWidget {
  final List<EnterpriseColumn<T>> allColumns;
  final Set<String> visibleColumnIds;
  final ValueChanged<Set<String>> onColumnsChanged;
  final VoidCallback onResetToDefaults;

  const EnterpriseTableColumnPickerDialog({
    super.key,
    required this.allColumns,
    required this.visibleColumnIds,
    required this.onColumnsChanged,
    required this.onResetToDefaults,
  });

  static Future<void> show<T>({
    required BuildContext context,
    required List<EnterpriseColumn<T>> allColumns,
    required Set<String> visibleColumnIds,
    required ValueChanged<Set<String>> onColumnsChanged,
    required VoidCallback onResetToDefaults,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => EnterpriseTableColumnPickerDialog<T>(
        allColumns: allColumns,
        visibleColumnIds: visibleColumnIds,
        onColumnsChanged: onColumnsChanged,
        onResetToDefaults: onResetToDefaults,
      ),
    );
  }

  @override
  State<EnterpriseTableColumnPickerDialog<T>> createState() =>
      _EnterpriseTableColumnPickerDialogState<T>();
}

class _EnterpriseTableColumnPickerDialogState<T>
    extends State<EnterpriseTableColumnPickerDialog<T>> {
  late Set<String> _selectedIds;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.visibleColumnIds);
  }

  @override
  Widget build(BuildContext context) {
    final filteredColumns = widget.allColumns.where((col) {
      if (_filter.isEmpty) return true;
      return col.title.toLowerCase().contains(_filter.toLowerCase()) ||
          col.id.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.view_column_rounded, color: AppTheme.cobalt),
          const SizedBox(width: 8),
          const Text('تخصيص أعمدة الجدول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            '${_selectedIds.length} من ${widget.allColumns.length} عمود معروض',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'بحث في الأعمدة...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) => setState(() => _filter = val.trim()),
            ),
            const SizedBox(height: 12),

            // Quick Selection buttons
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.select_all, size: 16),
                  label: const Text('تحديد الكل', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _selectedIds = widget.allColumns.map((c) => c.id).toSet();
                    });
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.deselect, size: 16),
                  label: const Text('إلغاء غير المقفل', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _selectedIds = widget.allColumns
                          .where((c) => c.isLocked)
                          .map((c) => c.id)
                          .toSet();
                    });
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16, color: AppTheme.orange),
                  label: const Text('إعادة ضبط افتراضي', style: TextStyle(fontSize: 12, color: AppTheme.orange)),
                  onPressed: () {
                    widget.onResetToDefaults();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Columns list
            Expanded(
              child: ListView.builder(
                itemCount: filteredColumns.length,
                itemBuilder: (context, index) {
                  final col = filteredColumns[index];
                  final isChecked = _selectedIds.contains(col.id);

                  return CheckboxListTile(
                    dense: true,
                    title: Row(
                      children: [
                        Text(
                          col.title,
                          style: TextStyle(
                            fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                            color: col.isLocked ? Colors.grey.shade600 : Colors.black87,
                          ),
                        ),
                        if (col.isLocked) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('مثبت', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      'المعرف: ${col.id}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                    value: isChecked,
                    onChanged: col.isLocked
                        ? null
                        : (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIds.add(col.id);
                              } else {
                                // Don't allow unchecking if it's the last column
                                if (_selectedIds.length > 1) {
                                  _selectedIds.remove(col.id);
                                }
                              }
                            });
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cobalt,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.onColumnsChanged(_selectedIds);
            Navigator.pop(context);
          },
          child: const Text('تطبيق التعديلات'),
        ),
      ],
    );
  }
}
