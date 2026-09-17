import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/financial_settlement_model.dart';

/// Modal dialog that allows searching and selecting a previous Landed Cost Financial Settlement
/// to clone into a new draft following the 5-Task Enterprise Protocol.
class SearchAndCloneFinancialSettlementDialog extends ConsumerStatefulWidget {
  final List<LandedCostSettlementModel> records;
  final ValueChanged<LandedCostSettlementModel> onSelectRecord;

  const SearchAndCloneFinancialSettlementDialog({
    super.key,
    required this.records,
    required this.onSelectRecord,
  });

  @override
  ConsumerState<SearchAndCloneFinancialSettlementDialog> createState() =>
      _SearchAndCloneFinancialSettlementDialogState();
}

class _SearchAndCloneFinancialSettlementDialogState
    extends ConsumerState<SearchAndCloneFinancialSettlementDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';

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
    final importFilesMap = {for (final f in allFiles) f.importFileId: f};

    final query = _searchController.text.trim().toLowerCase();
    final filteredRecords = widget.records.where((rec) {
      if (_statusFilter != 'All' && rec.status != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;

      final codeMatch = rec.settlementCode.toLowerCase().contains(query);
      final accountantMatch = rec.accountantName.toLowerCase().contains(query);
      final matchingFile = importFilesMap[rec.importFileId];
      final fileCodeMatch = (matchingFile?.primaryNameWithCode ?? 'imp-${rec.importFileId}')
          .toLowerCase()
          .contains(query);
      final compMatch = (matchingFile?.companyName ?? '').toLowerCase().contains(query);

      return codeMatch || accountantMatch || fileCodeMatch || compMatch;
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
                  child: const Icon(Icons.calculate_outlined, color: AppTheme.cobalt, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.cloneFinancialSettlementDialogTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.cloneFinancialSettlementDialogSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: l.cancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar & Filter Chips
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l.financialSettlementSearchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, val, _) => val.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filter Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildFilterChip('All', l.isArabic ? 'الكل' : 'All', isDark),
                _buildFilterChip('Draft', l.financialSettlementStatusDraft, isDark),
                _buildFilterChip('Calculated', l.financialSettlementStatusCalculated, isDark),
                _buildFilterChip('Approved', l.financialSettlementStatusApproved, isDark),
              ],
            ),
            const SizedBox(height: 14),

            // Records List
            Expanded(
              child: filteredRecords.isEmpty
                  ? Center(
                      child: Text(
                        l.financialSettlementEmptyRecords,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredRecords.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final rec = filteredRecords[index];
                        final matchingFile = importFilesMap[rec.importFileId];
                        final fileCode = matchingFile?.primaryNameWithCode ?? 'IMP-${rec.importFileId}';
                        final compName = matchingFile?.companyName ?? '';
                        final fileTitle = compName.isNotEmpty ? '$fileCode - $compName' : fileCode;
                        final currencyStr = l.financialSettlementCurrencyEgp;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
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
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.cobalt.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: CopyableText(
                                            rec.settlementCode,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.cobalt,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        _buildStatusBadge(context, rec.status),
                                        Text(
                                          l.financialSettlementAccountantLabel(rec.accountantName),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      fileTitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : AppTheme.charcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          '${l.financialSettlementMetricFobTotal}: ${rec.totalFobEgp.toStringAsFixed(2)} $currencyStr',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          '${l.financialSettlementMetricExpensesTotal}: ${rec.totalExpensesEgp.toStringAsFixed(2)} $currencyStr',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.orange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${l.financialSettlementMetricLandedCostTotal}: ${rec.totalLandedCostEgp.toStringAsFixed(2)} $currencyStr',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.emerald,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${l.financialSettlementMetricMarkupFactor}: ${rec.averageMarkupFactor.toStringAsFixed(3)}x',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.cobalt,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                key: Key('selectSettlementToCloneBtn_${rec.settlementCode}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.cobalt,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.copy_all, size: 16),
                                label: Text(
                                  l.cloneFinancialSettlementTooltip,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onSelectRecord(rec);
                                },
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

  Widget _buildFilterChip(String filterValue, String label, bool isDark) {
    final isSelected = _statusFilter == filterValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade800),
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.cobalt,
      backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
      onSelected: (val) {
        if (val) setState(() => _statusFilter = filterValue);
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color = AppTheme.cobalt;
    String label = status;
    if (status == 'Calculated') {
      color = AppTheme.emerald;
      label = context.l10n.financialSettlementStatusCalculated;
    } else if (status == 'Approved') {
      color = AppTheme.cobalt;
      label = context.l10n.financialSettlementStatusApproved;
    } else if (status == 'Draft') {
      color = AppTheme.orange;
      label = context.l10n.financialSettlementStatusDraft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 11),
      ),
    );
  }
}
