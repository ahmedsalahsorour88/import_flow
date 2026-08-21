import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/partner_model.dart';
import '../providers/partners_provider.dart';

class PartnerStatementOfAccountDialog extends ConsumerWidget {
  final PartnerModel partner;

  const PartnerStatementOfAccountDialog({super.key, required this.partner});

  static void show(BuildContext context, PartnerModel partner) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PartnerStatementOfAccountDialog(partner: partner),
    );
  }

  String _formatNumber(double val) {
    final parts = val.toStringAsFixed(2).split('.');
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final intPart = parts[0].replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$intPart.${parts[1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soaAsync = ref.watch(partnerStatementOfAccountProvider(partner.providerId ?? 0));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 1000,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.cobalt, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'كشف حساب مقدم الخدمة — ${partner.partnerName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                partner.partnerCode,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تصنيف الشريك: ${partner.partnerType} | الرقم الضريبي: ${partner.taxId ?? "—"} | العملات والحركات المالية',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: 'تحديث البيانات',
                    onPressed: () {
                      ref.invalidate(partnerStatementOfAccountProvider(partner.providerId ?? 0));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: soaAsync.when(
                loading: () => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.cobalt),
                      SizedBox(height: 16),
                      Text('جاري احتساب كشف الحساب وتجميع الأرصدة...', style: TextStyle(color: AppTheme.charcoal)),
                    ],
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.crimson, size: 48),
                        const SizedBox(height: 12),
                        Text('حدث خطأ أثناء جلب كشف الحساب: $err', style: const TextStyle(color: AppTheme.crimson)),
                      ],
                    ),
                  ),
                ),
                data: (soa) {
                  if (soa == null) {
                    return const Center(child: Text('لا توجد بيانات متاحة لهذا الشريك'));
                  }

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Currency Balances Cards
                        const Text(
                          'ملخص الأرصدة والمستحقات بكل عملة (Multi-Currency Balances):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: soa.currencyBalances.map((cb) {
                            final isPositive = cb.balanceDue > 0;
                            return Container(
                              width: 220,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPositive ? AppTheme.orange.withOpacity(0.4) : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cb.currency,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.cobalt,
                                        ),
                                      ),
                                      Icon(
                                        Icons.monetization_on_outlined,
                                        size: 18,
                                        color: isPositive ? AppTheme.orange : AppTheme.emerald,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('إجمالي الفواتير:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                      Text(_formatNumber(cb.totalInvoiced), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('المبالغ المسددة:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                      Text(_formatNumber(cb.totalPaid), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('الرصيد المستحق:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                                      Text(
                                        _formatNumber(cb.balanceDue),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isPositive ? AppTheme.crimson : AppTheme.emerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Ledger Table
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'سجل العمليات والفواتير والمدفوعات (${soa.ledgerEntries.length} حركة مسجلة):',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                            ),
                            Row(
                              children: [
                                Text(
                                  'فواتير: ${soa.totalInvoicesCount} | دفعات: ${soa.totalPaymentsCount}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: soa.ledgerEntries.isEmpty
                              ? Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('لا توجد حركات فواتير أو مدفوعات مسجلة لهذا الشريك حتى الآن'),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SingleChildScrollView(
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                                        columnSpacing: 18,
                                        horizontalMargin: 12,
                                        columns: const [
                                          DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('النوع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('المرجع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('البيان / الوصف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('العملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('مدين (فاتورة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('دائن (سداد)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        ],
                                        rows: soa.ledgerEntries.map((entry) {
                                          final isInvoice = entry.entryType.contains('Invoice');
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(entry.entryDate, style: const TextStyle(fontSize: 11))),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isInvoice
                                                        ? AppTheme.orange.withOpacity(0.15)
                                                        : AppTheme.emerald.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    isInvoice ? 'فاتورة' : 'سداد',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isInvoice ? AppTheme.orange : AppTheme.emerald,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(Text(entry.referenceNo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                                              DataCell(Text(entry.importFileCode ?? '—', style: const TextStyle(fontSize: 11, color: AppTheme.cobalt))),
                                              DataCell(Text(entry.description, style: const TextStyle(fontSize: 11))),
                                              DataCell(
                                                Text(
                                                  entry.currency,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  entry.debitAmount > 0 ? _formatNumber(entry.debitAmount) : '—',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: entry.debitAmount > 0 ? AppTheme.charcoal : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  entry.creditAmount > 0 ? _formatNumber(entry.creditAmount) : '—',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: entry.creditAmount > 0 ? AppTheme.emerald : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    entry.status,
                                                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sorour Logistics ERP — وحدة محاسبة الموردين ومقدمي الخدمات متعددة العملات',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.charcoal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
