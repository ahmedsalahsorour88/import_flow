import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../models/cargo_shipping_model.dart';

/// Search and Clone Previous Cargo Shipping Record Dialog (Screen 26 / UX-CLONE-026)
///
/// Allows operators to quickly search past cargo shipping allocations by code, import file,
/// container number, seal number, or importer, and select one to clone into a new editable draft.
class SearchAndCloneCargoShippingDialog extends StatefulWidget {
  final List<CargoShippingModel> records;
  final ValueChanged<CargoShippingModel> onSelectRecord;

  const SearchAndCloneCargoShippingDialog({
    super.key,
    required this.records,
    required this.onSelectRecord,
  });

  @override
  State<SearchAndCloneCargoShippingDialog> createState() =>
      _SearchAndCloneCargoShippingDialogState();
}

class _SearchAndCloneCargoShippingDialogState
    extends State<SearchAndCloneCargoShippingDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  late List<CargoShippingModel> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.records.where((r) => r.isActive).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = widget.records.where((r) {
        if (!r.isActive) return false;

        final matchesType = _selectedType == 'All' || r.shipmentType == _selectedType;
        if (!matchesType) return false;

        final matchesStatus = _selectedStatus == 'All' || r.status == _selectedStatus;
        if (!matchesStatus) return false;

        if (q.isEmpty) return true;

        final code = r.cargoShippingCode.toLowerCase();
        final file = (r.importFileCode ?? '').toLowerCase();
        final comp = (r.companyName ?? '').toLowerCase();
        final containers = r.containersLoadingData.any(
          (c) => c.containerNo.toLowerCase().contains(q) || c.sealNo.toLowerCase().contains(q),
        );

        return code.contains(q) || file.contains(q) || comp.contains(q) || containers;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth - 32).clamp(360.0, 920.0);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : AppTheme.cobalt.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy_all_rounded,
                      color: AppTheme.cobalt,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.cloneCargoShippingDialogTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF1F5F9) : AppTheme.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.cloneCargoShippingDialogSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: l.close,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Search Field
              TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilter(),
                decoration: InputDecoration(
                  hintText: 'ابحث برقم الشحنة، الحاوية، القفل، أو ملف الاستيراد...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilter();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Filters Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'نوع الشحن: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                      ),
                    ),
                    ...['All', 'FCL', 'LCL'].map((t) {
                      final isSelected = _selectedType == t;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(t == 'All' ? 'الكل' : t),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedType = t;
                              _applyFilter();
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(width: 12),
                    Text(
                      'الحالة: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                      ),
                    ),
                    ...['All', 'Completed', 'Cargo Ready'].map((s) {
                      final isSelected = _selectedStatus == s;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(s == 'All' ? 'الكل' : s),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedStatus = s;
                              _applyFilter();
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Records List
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'لا توجد شحنات سابقة مطابقة لمعايير البحث',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final rec = _filtered[index];
                          final containerSummary = rec.containersLoadingData
                              .map((c) => '${c.containerNo} (${c.containerType})')
                              .join(', ');

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onSelectRecord(rec);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isDark
                                        ? const Color(0xFF0F172A)
                                        : AppTheme.cobalt.withOpacity(0.12),
                                    child: const Icon(
                                      Icons.local_shipping_outlined,
                                      color: AppTheme.cobalt,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              rec.cargoShippingCode,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isDark ? const Color(0xFFF1F5F9) : AppTheme.charcoal,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: rec.shipmentType == 'FCL'
                                                    ? Colors.blue.withOpacity(0.12)
                                                    : Colors.purple.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                rec.shipmentType,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: rec.shipmentType == 'FCL' ? Colors.blue : Colors.purple,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: rec.status == 'Completed'
                                                    ? AppTheme.emerald.withOpacity(0.12)
                                                    : AppTheme.cobalt.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                rec.status,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: rec.status == 'Completed'
                                                      ? AppTheme.emerald
                                                      : AppTheme.cobalt,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ملف: ${rec.importFileCode ?? "IMP-${rec.importFileId}"} | ${rec.companyName ?? ""}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                                          ),
                                        ),
                                        if (containerSummary.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'الحاويات: $containerSummary',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? const Color(0xFF64748B) : Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    key: Key('selectRecordToCloneBtn_${rec.cargoShippingCode}'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.cobalt,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      widget.onSelectRecord(rec);
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    label: const Text('استنساخ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
