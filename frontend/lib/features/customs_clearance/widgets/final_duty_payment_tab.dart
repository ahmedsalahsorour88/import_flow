import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';
import '../models/customs_clearance_model.dart';
import '../services/final_duty_payment_export_service.dart';

/// Screen 62: Customs Clearance - Final Duty Payment & Release SubTab.
class FinalDutyPaymentTab extends ConsumerStatefulWidget {
  final List<CustomsClearanceModel> records;
  final VoidCallback? onRefresh;
  final void Function(CustomsClearanceModel record)? onPay;
  final void Function(CustomsClearanceModel record)? onRelease;

  const FinalDutyPaymentTab({
    super.key,
    required this.records,
    this.onRefresh,
    this.onPay,
    this.onRelease,
  });

  @override
  ConsumerState<FinalDutyPaymentTab> createState() => _FinalDutyPaymentTabState();
}

class _FinalDutyPaymentTabState extends ConsumerState<FinalDutyPaymentTab> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'ALL'; // ALL, PAID, PENDING, RELEASED
  bool _isExporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomsClearanceModel> get _filteredRecords {
    return widget.records.where((r) {
      if (_statusFilter == 'PAID' && r.paymentStatus != 'Paid & Verified') {
        return false;
      }
      if (_statusFilter == 'PENDING' && r.paymentStatus == 'Paid & Verified') {
        return false;
      }
      if (_statusFilter == 'RELEASED' &&
          r.status != 'Final Release Granted' &&
          (r.releasePermitNo == null || r.releasePermitNo!.isEmpty)) {
        return false;
      }

      final q = _searchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      final clr = r.clearanceCode.toLowerCase();
      final decl = (r.declaration46No ?? '').toLowerCase();
      final office = r.customsOfficeName.toLowerCase();
      final channel = r.channelType.toLowerCase();
      final receipt = (r.bankReceiptNo ?? '').toLowerCase();
      final permit = (r.releasePermitNo ?? '').toLowerCase();
      final status = r.status.toLowerCase();

      return clr.contains(q) ||
          decl.contains(q) ||
          office.contains(q) ||
          channel.contains(q) ||
          receipt.contains(q) ||
          permit.contains(q) ||
          status.contains(q);
    }).toList();
  }

  void _copyRowSummary(CustomsClearanceModel r, AppLocalizations l) {
    final isPaid = r.paymentStatus == 'Paid & Verified';
    final actual = (r.actualDutyTotal > 0 ? r.actualDutyTotal : r.totalDutyPayable).toStringAsFixed(2);
    final est = r.estimatedDutyTotal.toStringAsFixed(2);
    final variance = '${r.dutyVarianceAmount >= 0 ? "+" : ""}${r.dutyVarianceAmount.toStringAsFixed(2)} (${r.dutyVariancePercentage}%)';
    final paymentStatusStr = isPaid ? l.finalDutyStatusPaidVerified : l.finalDutyStatusPendingPayment;
    final rowSummary =
        "${r.clearanceCode}\t${r.declaration46No ?? '-'}\t${r.customsOfficeName}\t${r.channelType}\t$actual ${l.finalDutyCurrencyEgp}\t$est ${l.finalDutyCurrencyEgp}\t$variance\t$paymentStatusStr\t${r.bankReceiptNo ?? '-'}\t${r.releasePermitNo ?? '-'}\t${r.status}";

    CopyHelper.copy(context, rowSummary, customMessage: l.finalDutyCopyRowSummarySuccess);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final records = widget.records;
    final filtered = _filteredRecords;

    final totalPayable = records.fold<double>(
      0.0,
      (sum, r) => sum + (r.actualDutyTotal > 0 ? r.actualDutyTotal : r.totalDutyPayable),
    );
    final totalPaid = records.where((r) => r.paymentStatus == 'Paid & Verified').fold<double>(
      0.0,
      (sum, r) => sum + (r.actualDutyTotal > 0 ? r.actualDutyTotal : r.totalDutyPayable),
    );
    final pendingCount = records.where((r) => r.paymentStatus != 'Paid & Verified').length;
    final netVariance = records.fold<double>(
      0.0,
      (sum, r) => sum + r.dutyVarianceAmount,
    );

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Header Card with 4-Action Linked Output Toolbar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: AppTheme.emerald, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.finalDutyScreenTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.finalDutyScreenSubtitle,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.table_view, size: 15),
                        label: Text(l.finalDutyExportTsvBtn, style: const TextStyle(fontSize: 12)),
                        onPressed: _isExporting
                            ? null
                            : () async {
                                setState(() => _isExporting = true);
                                try {
                                  await FinalDutyPaymentExportService.saveFinalDutyTsvToFile(context, filtered);
                                } finally {
                                  if (mounted) setState(() => _isExporting = false);
                                }
                              },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.grid_on, size: 15),
                        label: Text(l.finalDutyExportExcelBtn, style: const TextStyle(fontSize: 12)),
                        onPressed: _isExporting
                            ? null
                            : () async {
                                setState(() => _isExporting = true);
                                try {
                                  await FinalDutyPaymentExportService.saveFinalDutyCsvToFile(context, filtered);
                                } finally {
                                  if (mounted) setState(() => _isExporting = false);
                                }
                              },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cobalt,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.picture_as_pdf, size: 15),
                        label: Text(l.finalDutyPrintPdfBtn, style: const TextStyle(fontSize: 12)),
                        onPressed: _isExporting
                            ? null
                            : () async {
                                setState(() => _isExporting = true);
                                try {
                                  await FinalDutyPaymentExportService.printOrSaveFinalDutyPdf(context, filtered);
                                } finally {
                                  if (mounted) setState(() => _isExporting = false);
                                }
                              },
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.charcoal,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.copy_all, size: 15),
                        label: Text(l.finalDutyCopyDossierBtn, style: const TextStyle(fontSize: 12)),
                        onPressed: () => FinalDutyPaymentExportService.copyDossierToClipboard(context, filtered),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4 KPI Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final cardWidth = isWide ? (constraints.maxWidth - 24) / 4 : (constraints.maxWidth - 8) / 2;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildKpiCard(
                      width: cardWidth,
                      title: l.finalDutyKpiTotalPayable,
                      value: '${totalPayable.toStringAsFixed(2)} ${l.finalDutyCurrencyEgp}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppTheme.cobalt,
                    ),
                    _buildKpiCard(
                      width: cardWidth,
                      title: l.finalDutyKpiTotalPaid,
                      value: '${totalPaid.toStringAsFixed(2)} ${l.finalDutyCurrencyEgp}',
                      icon: Icons.check_circle_outline,
                      color: AppTheme.emerald,
                    ),
                    _buildKpiCard(
                      width: cardWidth,
                      title: l.finalDutyKpiPendingPayment,
                      value: pendingCount.toString(),
                      icon: Icons.pending_actions_outlined,
                      color: AppTheme.orange,
                    ),
                    _buildKpiCard(
                      width: cardWidth,
                      title: l.finalDutyKpiNetVariance,
                      value: '${netVariance >= 0 ? "+" : ""}${netVariance.toStringAsFixed(2)} ${l.finalDutyCurrencyEgp}',
                      icon: Icons.compare_arrows_outlined,
                      color: netVariance.abs() > 500 ? AppTheme.crimson : Colors.teal.shade800,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Duty Ledger & Release Status Table Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, color: AppTheme.emerald, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.customsClearanceDutyLedgerTableTitle,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${filtered.length} / ${records.length}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Search & Filter Toolbar
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: l.finalDutySearchHint,
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    tooltip: l.finalDutyCopyFieldTooltip,
                                    onPressed: () => CopyHelper.copy(context, _searchController.text),
                                  ),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Wrap(
                          spacing: 6,
                          children: [
                            _buildFilterChip('ALL', l.finalDutyFilterAll),
                            _buildFilterChip('PAID', l.finalDutyFilterPaid),
                            _buildFilterChip('PENDING', l.finalDutyFilterPending),
                            _buildFilterChip('RELEASED', l.finalDutyFilterReleased),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                l.finalDutyEmptyRecords,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          columns: [
                            DataColumn(label: Text(l.customsClearanceColClearanceCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.customsClearanceColDecl46, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.customsClearanceColCustomsOffice, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.customsClearanceChannelLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.customsClearanceColActualDuty, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.customsClearanceColEstimatedDuty, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.customsClearanceColDutyVariance, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.customsClearanceColPaymentStatus, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.finalDutyColBankReceipt, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.finalDutyColReleasePermit, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(l.customsClearanceColActions, style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filtered.map((r) {
                            final isPaid = r.paymentStatus == 'Paid & Verified';
                            final actualDutyStr = '${(r.actualDutyTotal > 0 ? r.actualDutyTotal : r.totalDutyPayable).toStringAsFixed(2)} ${l.finalDutyCurrencyEgp}';
                            final estDutyStr = '${r.estimatedDutyTotal.toStringAsFixed(2)} ${l.finalDutyCurrencyEgp}';
                            final varianceStr = '${r.dutyVarianceAmount >= 0 ? "+" : ""}${r.dutyVarianceAmount.toStringAsFixed(2)} (${r.dutyVariancePercentage}%)';
                            final paymentStatusStr = isPaid ? l.finalDutyStatusPaidVerified : l.finalDutyStatusPendingPayment;
                            final bankReceiptStr = r.bankReceiptNo ?? '-';
                            final releasePermitStr = r.releasePermitNo ?? '-';
                            final rowSummary =
                                "${r.clearanceCode}\t${r.declaration46No ?? '-'}\t${r.customsOfficeName}\t${r.channelType}\t$actualDutyStr\t$estDutyStr\t$varianceStr\t$paymentStatusStr\t$bankReceiptStr\t$releasePermitStr\t${r.status}";

                            return DataRow(
                              cells: [
                                // Clearance Code badge
                                DataCell(
                                  CopyableTableCell(
                                    value: r.clearanceCode,
                                    rowSummary: rowSummary,
                                    child: InkWell(
                                      onTap: () => CopyHelper.copy(context, r.clearanceCode),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cobalt.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              r.clearanceCode,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.copy, size: 11, color: AppTheme.cobalt),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Declaration 46
                                DataCell(
                                  CopyableTableCell(
                                    value: r.declaration46No ?? '-',
                                    rowSummary: rowSummary,
                                    child: r.declaration46No != null && r.declaration46No!.isNotEmpty
                                        ? InkWell(
                                            onTap: () => CopyHelper.copy(context, r.declaration46No!),
                                            borderRadius: BorderRadius.circular(4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(r.declaration46No!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.copy, size: 11, color: Colors.grey),
                                              ],
                                            ),
                                          )
                                        : const Text('-'),
                                  ),
                                ),

                                // Office
                                DataCell(
                                  CopyableTableCell(
                                    value: r.customsOfficeName,
                                    rowSummary: rowSummary,
                                    child: Text(r.customsOfficeName, style: const TextStyle(fontSize: 12)),
                                  ),
                                ),

                                // Channel
                                DataCell(
                                  CopyableTableCell(
                                    value: r.channelType,
                                    rowSummary: rowSummary,
                                    child: Text(r.channelType, style: const TextStyle(fontSize: 12)),
                                  ),
                                ),

                                // Actual Duty
                                DataCell(
                                  CopyableTableCell(
                                    value: actualDutyStr,
                                    rowSummary: rowSummary,
                                    child: Text(
                                      actualDutyStr,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 12),
                                    ),
                                  ),
                                ),

                                // Estimated Duty
                                DataCell(
                                  CopyableTableCell(
                                    value: estDutyStr,
                                    rowSummary: rowSummary,
                                    child: Text(estDutyStr, style: const TextStyle(fontSize: 12)),
                                  ),
                                ),

                                // Duty Variance
                                DataCell(
                                  CopyableTableCell(
                                    value: varianceStr,
                                    rowSummary: rowSummary,
                                    child: Text(
                                      varianceStr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: r.dutyVarianceAmount.abs() > 500 ? AppTheme.orange : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),

                                // Payment Status Badge
                                DataCell(
                                  CopyableTableCell(
                                    value: paymentStatusStr,
                                    rowSummary: rowSummary,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isPaid ? Colors.green : Colors.orange).shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: (isPaid ? Colors.green : Colors.orange).shade300),
                                      ),
                                      child: Text(
                                        isPaid ? '✅ $paymentStatusStr' : '⚠️ $paymentStatusStr',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isPaid ? Colors.green.shade900 : Colors.orange.shade900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Bank Receipt No
                                DataCell(
                                  CopyableTableCell(
                                    value: bankReceiptStr,
                                    rowSummary: rowSummary,
                                    child: r.bankReceiptNo != null && r.bankReceiptNo!.isNotEmpty
                                        ? InkWell(
                                            onTap: () => CopyHelper.copy(context, r.bankReceiptNo!),
                                            borderRadius: BorderRadius.circular(4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  r.bankReceiptNo!,
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.indigo),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.copy, size: 11, color: Colors.indigo),
                                              ],
                                            ),
                                          )
                                        : const Text('-', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),

                                // Release Permit No
                                DataCell(
                                  CopyableTableCell(
                                    value: releasePermitStr,
                                    rowSummary: rowSummary,
                                    child: r.releasePermitNo != null && r.releasePermitNo!.isNotEmpty
                                        ? InkWell(
                                            onTap: () => CopyHelper.copy(context, r.releasePermitNo!),
                                            borderRadius: BorderRadius.circular(4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  r.releasePermitNo!,
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.copy, size: 11, color: AppTheme.emerald),
                                              ],
                                            ),
                                          )
                                        : const Text('-', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),

                                // Actions
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.charcoal),
                                        tooltip: l.finalDutyCopyRowSummaryBtn,
                                        onPressed: () => _copyRowSummary(r, l),
                                      ),
                                      const SizedBox(width: 4),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isPaid ? Colors.indigo : AppTheme.emerald,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        icon: Icon(isPaid ? Icons.verified : Icons.payment, size: 13),
                                        label: Text(
                                          isPaid ? l.customsClearanceBtnPaymentDetails : l.customsClearanceBtnPayReconcile,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        onPressed: widget.onPay != null ? () => widget.onPay!(r) : null,
                                      ),
                                      const SizedBox(width: 6),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.cobalt,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        icon: const Icon(Icons.assignment_turned_in, size: 13),
                                        label: Text(l.customsClearanceBtnFinalRelease, style: const TextStyle(fontSize: 11)),
                                        onPressed: widget.onRelease != null ? () => widget.onRelease!(r) : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, size: 16, color: color),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppTheme.charcoal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.cobalt,
      backgroundColor: Colors.grey.shade100,
      onSelected: (selected) {
        if (selected) setState(() => _statusFilter = value);
      },
    );
  }
}
