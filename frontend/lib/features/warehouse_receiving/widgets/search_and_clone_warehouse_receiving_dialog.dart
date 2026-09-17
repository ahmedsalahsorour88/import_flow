import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/warehouse_receiving_model.dart';

/// Modal dialog that allows searching and selecting a previous Goods Receiving Note (GRN)
/// to clone into a new draft following the 5-Task Enterprise Protocol.
class SearchAndCloneWarehouseReceivingDialog extends ConsumerStatefulWidget {
  final List<WarehouseReceivingModel> records;
  final ValueChanged<WarehouseReceivingModel> onSelectRecord;

  const SearchAndCloneWarehouseReceivingDialog({
    super.key,
    required this.records,
    required this.onSelectRecord,
  });

  @override
  ConsumerState<SearchAndCloneWarehouseReceivingDialog> createState() =>
      _SearchAndCloneWarehouseReceivingDialogState();
}

class _SearchAndCloneWarehouseReceivingDialogState
    extends ConsumerState<SearchAndCloneWarehouseReceivingDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';
  String _quarantineFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = (screenWidth - 32).clamp(360.0, 920.0);
    final dialogHeight = (screenHeight * 0.82).clamp(420.0, 780.0);
    final allFiles = ref.watch(importFilesProvider).valueOrNull ?? [];

    final query = _searchController.text.trim().toLowerCase();
    final filteredRecords = widget.records.where((rec) {
      if (_statusFilter != 'All' && rec.status != _statusFilter) {
        return false;
      }
      if (_quarantineFilter == 'Quarantine Only' && !rec.quarantineZoneAssigned) {
        return false;
      }
      if (_quarantineFilter == 'Standard Only' && rec.quarantineZoneAssigned) {
        return false;
      }
      if (query.isEmpty) return true;

      final grnCodeMatch = rec.grnCode.toLowerCase().contains(query);
      final whMatch = rec.warehouseName.toLowerCase().contains(query);
      final driverMatch = (rec.driverName ?? '').toLowerCase().contains(query);
      final plateMatch = (rec.truckPlateNumber ?? '').toLowerCase().contains(query);
      final sealMatch = (rec.sealNumber ?? '').toLowerCase().contains(query);
      final inspectorMatch = rec.inspectorName.toLowerCase().contains(query);
      final fileCodeMatch = 'imp-${rec.importFileId}'.contains(query);

      return grnCodeMatch ||
          whMatch ||
          driverMatch ||
          plateMatch ||
          sealMatch ||
          inspectorMatch ||
          fileCodeMatch;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cobalt.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_outlined, color: AppTheme.cobalt, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.cloneWarehouseReceivingDialogTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF1F5F9) : AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.cloneWarehouseReceivingDialogSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.warehouseReceivingSearchHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, val, _) {
                    return val.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : const SizedBox.shrink();
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),

            // Filter Chips (Status & Quarantine)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildFilterChip('All', l.warehouseReceivingStatusAll, _statusFilter, (v) {
                  setState(() => _statusFilter = v);
                }, isDark),
                _buildFilterChip('Draft / Pending Warehouse Count', l.warehouseReceivingStatusDraft, _statusFilter, (v) {
                  setState(() => _statusFilter = v);
                }, isDark),
                _buildFilterChip('Goods Received', l.warehouseReceivingStatusGoodsReceived, _statusFilter, (v) {
                  setState(() => _statusFilter = v);
                }, isDark),
                _buildFilterChip('Discrepancy Reported', l.warehouseReceivingStatusDiscrepancy, _statusFilter, (v) {
                  setState(() => _statusFilter = v);
                }, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('All', 'الكل', _quarantineFilter, (v) {
                  setState(() => _quarantineFilter = v);
                }, isDark, isSecondary: true),
                _buildFilterChip('Quarantine Only', 'حجر مخزني فقط', _quarantineFilter, (v) {
                  setState(() => _quarantineFilter = v);
                }, isDark, isSecondary: true),
              ],
            ),
            const Divider(height: 20),

            // Results List
            Expanded(
              child: filteredRecords.isEmpty
                  ? Center(
                      child: Text(
                        l.warehouseReceivingEmptyRecords,
                        style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredRecords.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final rec = filteredRecords[idx];
                        final rawFileCode = 'IMP-${rec.importFileId}';
                        final matchedFile = allFiles.where((f) => f.importFileId == rec.importFileId).firstOrNull;
                        final displayFileName = matchedFile?.primaryNameWithCode ?? rawFileCode;

                        Color statusColor = AppTheme.cobalt;
                        String statusLabel = rec.status;
                        if (rec.status.contains('Draft') || rec.status.contains('Pending')) {
                          statusColor = AppTheme.orange;
                          statusLabel = l.warehouseReceivingStatusDraft;
                        } else if (rec.status == 'Goods Received') {
                          statusColor = AppTheme.emerald;
                          statusLabel = l.warehouseReceivingStatusGoodsReceived;
                        } else if (rec.status == 'Discrepancy Reported') {
                          statusColor = AppTheme.crimson;
                          statusLabel = l.warehouseReceivingStatusDiscrepancy;
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.cobalt.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: CopyableText(
                                            rec.grnCode,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusColor),
                                          ),
                                        ),
                                        if (rec.quarantineZoneAssigned)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.crimson.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '⚠️ منطقة حجر',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.crimson),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          '🏢 ${rec.warehouseName}',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFF1F5F9) : AppTheme.charcoal),
                                        ),
                                        Text(
                                          '📦 $displayFileName',
                                          style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.black87),
                                        ),
                                        if (rec.driverName != null && rec.driverName!.isNotEmpty)
                                          Text(
                                            '🚚 ${rec.driverName} (${rec.truckPlateNumber ?? "-"})',
                                            style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                                          ),
                                        Text(
                                          '📊 أصناف: ${rec.totalAcceptedQty} مقبول / ${rec.totalShortageQty} عجز / ${rec.totalDamagedQty} تلف',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: (rec.totalShortageQty > 0 || rec.totalDamagedQty > 0)
                                                ? AppTheme.crimson
                                                : AppTheme.emerald,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                key: Key('selectRecordToCloneBtn_${rec.grnCode}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cobalt,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                icon: const Icon(Icons.difference_outlined, size: 15),
                                label: Text(l.cloneWarehouseReceivingTooltip, style: const TextStyle(fontSize: 11)),
                                onPressed: () => widget.onSelectRecord(rec),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    String selectedValue,
    ValueChanged<String> onSelected,
    bool isDark, {
    bool isSecondary = false,
  }) {
    final isSelected = selectedValue == value;
    final activeColor = isSecondary ? AppTheme.orange : AppTheme.cobalt;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: activeColor.withOpacity(0.2),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? activeColor : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade800),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}
