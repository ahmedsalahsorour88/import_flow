import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../models/financial_settlement_model.dart';
import '../providers/financial_settlement_provider.dart';

class OdooJournalEntryDialog extends ConsumerStatefulWidget {
  final int settlementId;
  final String settlementCode;

  const OdooJournalEntryDialog({
    super.key,
    required this.settlementId,
    required this.settlementCode,
  });

  @override
  ConsumerState<OdooJournalEntryDialog> createState() => _OdooJournalEntryDialogState();
}

class _OdooJournalEntryDialogState extends ConsumerState<OdooJournalEntryDialog> {
  OdooJournalEntryModel? _journalEntry;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJournal();
  }

  Future<void> _loadJournal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final entry = await ref
          .read(financialSettlementProvider.notifier)
          .fetchOdooJournalEntry(widget.settlementId);
      if (mounted) {
        setState(() {
          _journalEntry = entry;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _triggerDownload(String endpoint, String filename) {
    final downloadUrl = '${ApiConstants.baseUrl}/financial-settlement/${widget.settlementId}/$endpoint';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'جارٍ التصدير: $filename\nالرابط المباشر: $downloadUrl',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cobalt,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 1100,
        height: 750,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.cobalt),
                    SizedBox(height: 16),
                    Text('جارٍ إعداد وتوليد قيد اليومية المزدوج المتوازن لـ Odoo / ERP...',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.crimson),
                        const SizedBox(height: 12),
                        Text('خطأ أثناء جلب القيد: $_errorMessage',
                            style: const TextStyle(color: AppTheme.crimson)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadJournal,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final entry = _journalEntry!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Bar
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قيد اليومية المحاسبي المزدوج وتصدير Odoo ERP (${entry.settlementCode})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 2),
                Text(
                  'ملف الاستيراد: ${entry.importFileCode} | المرجع: ${entry.reference}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const Spacer(),
            // Balance Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: entry.isBalanced
                    ? AppTheme.emerald.withOpacity(0.12)
                    : AppTheme.crimson.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: entry.isBalanced ? AppTheme.emerald : AppTheme.crimson,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    entry.isBalanced ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: entry.isBalanced ? AppTheme.emerald : AppTheme.crimson,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.isBalanced
                        ? '🟢 قيد متوازن 100% (Debit = Credit)'
                        : '🔴 غير متوازن (فارق: ${entry.difference.toStringAsFixed(2)} ج.م)',
                    style: TextStyle(
                      color: entry.isBalanced ? AppTheme.emerald : AppTheme.crimson,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Metadata Header Cards
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _buildMetaItem('الشركة المستوردة', entry.companyName, Icons.business),
              _buildMetaDivider(),
              _buildMetaItem('المورد الأجنبي', entry.supplierName, Icons.flight_takeoff),
              _buildMetaDivider(),
              _buildMetaItem('المشروع / الحساب التحليلي', entry.projectName ?? 'N/A', Icons.account_tree),
              _buildMetaDivider(),
              _buildMetaItem('تاريخ القيد', entry.entryDate, Icons.calendar_today),
              _buildMetaDivider(),
              _buildMetaItem('إجمالي المدين / الدائن', '${entry.totalDebit.toStringAsFixed(2)} ج.م', Icons.account_balance_wallet, isHighlight: true),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Table Header Label
        const Text(
          'تفاصيل بنود القيد المحاسبي المزدوج (Double-Entry General Ledger Lines):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
        ),
        const SizedBox(height: 8),

        // Table of Journal Lines
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowMinHeight: 38,
                    dataRowMaxHeight: 46,
                    headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.08)),
                    columns: const [
                      DataColumn(label: Text('رقم الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('اسم الحساب الدفتري', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الطرف / الشريك (Partner)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('بيان وشرح القيد (Label)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('مدين Debit (ج.م)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('دائن Credit (ج.م)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('العملة الأجنبية', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('تصنيف التكلفة', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: entry.lines.map((l) {
                      final isDebit = l.debit > 0;
                      return DataRow(
                        color: WidgetStateProperty.all(
                          isDebit ? AppTheme.emerald.withOpacity(0.04) : Colors.transparent,
                        ),
                        cells: [
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDebit ? AppTheme.emerald.withOpacity(0.1) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(l.accountCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                          DataCell(Text(l.accountName, style: const TextStyle(fontSize: 12))),
                          DataCell(Text(l.partnerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: Text(l.label, style: const TextStyle(fontSize: 11.5), overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          DataCell(
                            Text(
                              l.debit > 0 ? '${l.debit.toStringAsFixed(2)} ج.م' : '-',
                              style: TextStyle(
                                fontWeight: isDebit ? FontWeight.bold : FontWeight.normal,
                                color: isDebit ? AppTheme.emerald : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              l.credit > 0 ? '${l.credit.toStringAsFixed(2)} ج.م' : '-',
                              style: TextStyle(
                                fontWeight: !isDebit ? FontWeight.bold : FontWeight.normal,
                                color: !isDebit ? AppTheme.charcoal : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              l.amountCurrency != null ? '${l.amountCurrency!.toStringAsFixed(2)} ${l.currency}' : '-',
                              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                            ),
                          ),
                          DataCell(_buildCategoryBadge(l.costCategory)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action Toolbar
        Row(
          children: [
            // Export Odoo CSV Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cobalt,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.file_download, color: Colors.white),
              label: const Text(
                '📥 تحميل شيت Odoo CSV الجاهز للاستيراد المباشر',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              onPressed: () => _triggerDownload('export-odoo-csv', 'odoo_landed_cost_${entry.settlementId}.csv'),
            ),

            const SizedBox(width: 12),

            // Export Excel Workbook Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.table_view, color: Colors.white),
              label: const Text(
                '📊 تحميل كشف Excel المحاسبي التفصيلي (Bilingual)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              onPressed: () => _triggerDownload('export-odoo-excel', 'accounting_landed_cost_voucher_${entry.settlementId}.xlsx'),
            ),

            const Spacer(),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              child: const Text('إغلاق', style: TextStyle(color: AppTheme.charcoal)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaItem(String title, String value, IconData icon, {bool isHighlight = false}) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: isHighlight ? AppTheme.emerald : Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isHighlight ? 12.5 : 11.5,
                    color: isHighlight ? AppTheme.emerald : AppTheme.charcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color color;
    switch (category) {
      case 'Goods':
        color = AppTheme.emerald;
        break;
      case 'Freight':
        color = AppTheme.cobalt;
        break;
      case 'Customs':
        color = Colors.indigo;
        break;
      case 'Clearance':
        color = Colors.teal;
        break;
      case 'Transport':
        color = AppTheme.orange;
        break;
      case 'Demurrage':
        color = AppTheme.crimson;
        break;
      case 'Price_Adjustment':
        color = Colors.purple;
        break;
      default:
        color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
