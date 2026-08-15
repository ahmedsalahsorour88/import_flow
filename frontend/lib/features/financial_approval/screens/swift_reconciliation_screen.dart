import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/financial_approval_model.dart';
import '../providers/financial_approval_provider.dart';
import '../../import_files/providers/import_files_provider.dart';

class SwiftReconciliationScreen extends ConsumerStatefulWidget {
  const SwiftReconciliationScreen({super.key});

  @override
  ConsumerState<SwiftReconciliationScreen> createState() => _SwiftReconciliationScreenState();
}

class _SwiftReconciliationScreenState extends ConsumerState<SwiftReconciliationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'ALL'; // ALL, PENDING, MATCHED, DEFICIT, SURPLUS
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSwiftReconciliationDialog(PaymentRequestModel pay) {
    final formKey = GlobalKey<FormState>();
    final swiftRefController = TextEditingController(text: pay.swiftReferenceNo ?? '');
    final transferredAmountController = TextEditingController(
      text: pay.swiftTransferredAmount != null
          ? pay.swiftTransferredAmount!.toStringAsFixed(2)
          : pay.requestedAmount.toStringAsFixed(2),
    );
    final currencyController = TextEditingController(
      text: pay.swiftTransferredCurrency ?? pay.currencyCode,
    );
    final notesController = TextEditingController(text: pay.swiftReconciliationNotes ?? '');

    DateTime receiptDate;
    if (pay.swiftReceiptDate != null && pay.swiftReceiptDate!.isNotEmpty) {
      receiptDate = DateTime.tryParse(pay.swiftReceiptDate!) ?? DateTime.now();
    } else {
      receiptDate = DateTime.now();
    }

    DateTime requestDate;
    if (pay.requestDate.isNotEmpty) {
      requestDate = DateTime.tryParse(pay.requestDate) ?? DateTime.now();
    } else {
      requestDate = DateTime.now();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final transferredAmt = double.tryParse(transferredAmountController.text.trim()) ?? 0.0;
            final variance = transferredAmt - pay.requestedAmount;
            final processingDays = receiptDate.difference(requestDate).inDays;
            final safeDays = processingDays < 0 ? 0 : processingDays;

            Color varianceColor;
            IconData varianceIcon;
            String varianceText;

            if (transferredAmt <= 0) {
              varianceColor = Colors.grey;
              varianceIcon = Icons.hourglass_empty;
              varianceText = 'بانتظار إدخال المبلغ';
            } else if (variance.abs() < 0.001) {
              varianceColor = AppTheme.emerald;
              varianceIcon = Icons.check_circle;
              varianceText = 'مطابق تماماً (100% Matched - بدون فروقات)';
            } else if (variance < 0) {
              varianceColor = AppTheme.crimson;
              varianceIcon = Icons.arrow_downward;
              varianceText = 'عجز / نقص في قيمة السويفت بمقدار ${variance.abs().toStringAsFixed(2)} ${pay.currencyCode}';
            } else {
              varianceColor = AppTheme.orange;
              varianceIcon = Icons.arrow_upward;
              varianceText = 'زيادة في قيمة السويفت بمقدار ${variance.toStringAsFixed(2)} ${pay.currencyCode}';
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.account_balance, color: AppTheme.cobalt),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تسجيل ومطابقة السويفت البنكي: ${pay.paymentCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 680,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary of Payment Request
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('عنوان الطلب: ${pay.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (pay.importFileCode != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppTheme.cobalt, borderRadius: BorderRadius.circular(4)),
                                      child: Text(pay.importFileCode!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(child: Text('المورد المستفيد: ${pay.beneficiaryName ?? pay.supplierName}', style: const TextStyle(fontSize: 12))),
                                  Expanded(child: Text('البنك: ${pay.bankName ?? "-"} (${pay.swiftCode ?? "-"})', style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(child: Text('تاريخ تقديم الطلب: ${pay.requestDate.isNotEmpty ? pay.requestDate : "-"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoal))),
                                  Expanded(child: Text('المبلغ المطلوب: ${pay.requestedAmount.toStringAsFixed(2)} ${pay.currencyCode}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Input Fields
                        Row(
                          children: [
                            // SWIFT Receipt Date
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: receiptDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => receiptDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'تاريخ استلام السويفت من البنك *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today, color: AppTheme.cobalt),
                                  ),
                                  child: Text(receiptDate.toString().substring(0, 10), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // SWIFT Reference No
                            Expanded(
                              child: TextFormField(
                                controller: swiftRefController,
                                decoration: const InputDecoration(
                                  labelText: 'رقم السويفت البنكي (SWIFT / MT103 Ref) *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.tag, color: AppTheme.cobalt),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رقم السويفت' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            // Transferred Amount
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: transferredAmountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'القيمة المصدرة من السويفت *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money, color: AppTheme.emerald),
                                ),
                                onChanged: (v) => setDialogState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'يرجى إدخال المبلغ';
                                  final num = double.tryParse(v.trim());
                                  if (num == null || num <= 0) return 'المبلغ يجب أن يكون أكبر من 0';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Currency
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: currencyController,
                                decoration: const InputDecoration(
                                  labelText: 'العملة *',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Reconciliation Live Comparison Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: varianceColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: varianceColor.withOpacity(0.4), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(varianceIcon, color: varianceColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text('نتيجة المقارنة والمطابقة الفورية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: varianceColor)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('مدة التنفيذ: $safeDays يوم ما بين تاريخ الطلب وتاريخ السويفت', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: safeDays <= 3 ? Colors.green.shade100 : (safeDays <= 7 ? Colors.orange.shade100 : Colors.red.shade100),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      safeDays <= 3 ? '⚡ تنفيذ فوري ($safeDays أيام)' : (safeDays <= 7 ? '⏱️ مدة معقولة ($safeDays أيام)' : '⚠️ تأخير ($safeDays أيام)'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: safeDays <= 3 ? Colors.green.shade800 : (safeDays <= 7 ? Colors.orange.shade900 : Colors.red.shade900),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('المبلغ المطلوب: ${pay.requestedAmount.toStringAsFixed(2)} ${pay.currencyCode}', style: const TextStyle(fontSize: 12)),
                                  Text('المبلغ المنفذ: ${transferredAmt.toStringAsFixed(2)} ${pay.currencyCode}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: varianceColor)),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(varianceText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: varianceColor)),
                                  if (variance != 0)
                                    Text(
                                      'الفارق: ${variance >= 0 ? "+" : ""}${variance.toStringAsFixed(2)} ${pay.currencyCode}',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: varianceColor, fontSize: 13),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Auto-Sync Info Banner
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⚡ سيتم تلقائياً تحديث رقم السويفت (swift no) في ملف الاستيراد المربوط بمجرد الحفظ والاعتماد.',
                                  style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Notes Field
                        TextFormField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'ملاحظات المطابقة والفروقات البنكية (إن وجدت)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text('حفظ واعتماد السويفت وتحديث ملف الشحنة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogCtx);

                    setState(() => _isProcessing = true);
                    try {
                      final updated = await ref.read(paymentRequestsProvider.notifier).reconcileSwift(
                        paymentId: pay.paymentId,
                        swiftReferenceNo: swiftRefController.text.trim(),
                        swiftReceiptDate: receiptDate.toString().substring(0, 10),
                        swiftTransferredAmount: transferredAmt,
                        swiftTransferredCurrency: currencyController.text.trim().isNotEmpty ? currencyController.text.trim() : 'USD',
                        swiftReconciliationNotes: notesController.text.trim(),
                      );

                      // Also refresh Import Files provider so swift_no is live immediately
                      ref.read(importFilesProvider.notifier).fetchImportFiles();

                      if (mounted && updated != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ تم مطابقة السويفت بنجاح (${updated.swiftReferenceNo}) وتحديث ملف الاستيراد آلياً ⚡'),
                            backgroundColor: AppTheme.emerald,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ خطأ أثناء المطابقة: $e'), backgroundColor: AppTheme.crimson),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSwiftDetailsDialog(PaymentRequestModel pay) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('تفاصيل السويفت البنكي: ${pay.paymentCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _buildVarianceBadge(pay.swiftVarianceStatus, pay.swiftVarianceAmount, pay.currencyCode),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pay.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                const SizedBox(height: 6),
                Text('المورد المستفيد: ${pay.beneficiaryName ?? pay.supplierName}'),
                Text('البنك: ${pay.bankName ?? "-"} | SWIFT: ${pay.swiftCode ?? "-"} | الحساب: ${pay.ibanAccountNo ?? "-"}'),
                const Divider(),
                Row(
                  children: [
                    _buildStatPill('تاريخ تقديم الطلب', pay.requestDate.isNotEmpty ? pay.requestDate : '-', AppTheme.charcoal),
                    const SizedBox(width: 8),
                    _buildStatPill('تاريخ استلام السويفت', pay.swiftReceiptDate ?? 'بانتظار السويفت', AppTheme.cobalt),
                    const SizedBox(width: 8),
                    _buildStatPill('مدة التنفيذ', pay.swiftProcessingDays != null ? '${pay.swiftProcessingDays} يوم' : '-', Colors.teal),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatPill('المبلغ المطلوب', '${pay.requestedAmount.toStringAsFixed(2)} ${pay.currencyCode}', AppTheme.cobalt),
                    const SizedBox(width: 8),
                    _buildStatPill('المبلغ المنفذ بالسويفت', pay.swiftTransferredAmount != null ? '${pay.swiftTransferredAmount!.toStringAsFixed(2)} ${pay.swiftTransferredCurrency ?? pay.currencyCode}' : '-', AppTheme.emerald),
                    const SizedBox(width: 8),
                    _buildStatPill('الفارق', pay.swiftVarianceAmount != null ? '${pay.swiftVarianceAmount!.toStringAsFixed(2)} ${pay.currencyCode}' : '-', Colors.orange),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tag, color: AppTheme.cobalt, size: 18),
                          const SizedBox(width: 6),
                          const Text('رقم السويفت (SWIFT Reference No):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Text(pay.swiftReferenceNo ?? 'غير مسجل', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 14)),
                        ],
                      ),
                      if (pay.swiftReconciliationNotes != null && pay.swiftReconciliationNotes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('ملاحظات المطابقة: ${pay.swiftReconciliationNotes}'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
            icon: const Icon(Icons.edit, color: Colors.white, size: 16),
            label: const Text('تعديل المطابقة', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              _showSwiftReconciliationDialog(pay);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildVarianceBadge(String? status, double? variance, String currency) {
    if (status == 'Matched' || (variance != null && variance.abs() < 0.001)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 14),
            SizedBox(width: 4),
            Text('مطابق تماماً', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      );
    } else if (status == 'Deficit' || (variance != null && variance < 0)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_downward, color: Colors.red, size: 14),
            const SizedBox(width: 4),
            Text('عجز (${variance?.toStringAsFixed(2)} $currency)', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      );
    } else if (status == 'Surplus' || (variance != null && variance > 0)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward, color: Colors.orange, size: 14),
            const SizedBox(width: 4),
            Text('زيادة (+${variance?.toStringAsFixed(2)} $currency)', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
        child: const Text('بانتظار السويفت', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(paymentRequestsProvider);
    final paymentsList = paymentsState.value ?? [];

    // Filter payments
    final filtered = paymentsList.where((pay) {
      if (!pay.isActive) return false;
      final q = _searchController.text.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          pay.paymentCode.toLowerCase().contains(q) ||
          pay.title.toLowerCase().contains(q) ||
          pay.supplierName.toLowerCase().contains(q) ||
          (pay.importFileCode != null && pay.importFileCode!.toLowerCase().contains(q)) ||
          (pay.swiftReferenceNo != null && pay.swiftReferenceNo!.toLowerCase().contains(q));

      if (!matchQuery) return false;

      if (_selectedStatusFilter == 'PENDING') {
        return pay.swiftReferenceNo == null || pay.swiftReferenceNo!.isEmpty;
      } else if (_selectedStatusFilter == 'MATCHED') {
        return pay.swiftVarianceStatus == 'Matched';
      } else if (_selectedStatusFilter == 'DEFICIT') {
        return pay.swiftVarianceStatus == 'Deficit';
      } else if (_selectedStatusFilter == 'SURPLUS') {
        return pay.swiftVarianceStatus == 'Surplus';
      }
      return true;
    }).toList();

    // Calculate metrics
    final totalRequests = paymentsList.where((p) => p.isActive).length;
    final pendingSwift = paymentsList.where((p) => p.isActive && (p.swiftReferenceNo == null || p.swiftReferenceNo!.isEmpty)).length;
    final matchedSwift = paymentsList.where((p) => p.isActive && p.swiftVarianceStatus == 'Matched').length;
    final discrepancySwift = paymentsList.where((p) => p.isActive && (p.swiftVarianceStatus == 'Deficit' || p.swiftVarianceStatus == 'Surplus')).length;

    final reconciledItems = paymentsList.where((p) => p.isActive && p.swiftProcessingDays != null).toList();
    final avgDays = reconciledItems.isNotEmpty
        ? (reconciledItems.map((p) => p.swiftProcessingDays!).reduce((a, b) => a + b) / reconciledItems.length).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('مركز مطابقة وتأكيد السويفت البنكي (Bank SWIFT Tracking & Reconciliation Engine)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
            onPressed: () {
              ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests();
              ref.read(importFilesProvider.notifier).fetchImportFiles();
            },
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Metric Cards
                  Row(
                    children: [
                      _buildKPICard('إجمالي طلبات السداد', totalRequests.toString(), Icons.receipt_long, AppTheme.cobalt),
                      const SizedBox(width: 12),
                      _buildKPICard('بانتظار السويفت', pendingSwift.toString(), Icons.hourglass_top, Colors.orange),
                      const SizedBox(width: 12),
                      _buildKPICard('سويفت مطابق 100%', matchedSwift.toString(), Icons.check_circle_outline, AppTheme.emerald),
                      const SizedBox(width: 12),
                      _buildKPICard('فروقات (عجز / زيادة)', discrepancySwift.toString(), Icons.compare_arrows, AppTheme.crimson),
                      const SizedBox(width: 12),
                      _buildKPICard('متوسط مدة التنفيذ', '$avgDays يوم', Icons.speed, Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter & Search Toolbar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'بحث بكود الطلب، ملف الشحنة، المورد، رقم السويفت...',
                              prefixIcon: Icon(Icons.search, color: AppTheme.cobalt),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Filter Chips
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildFilterChip('الكل ($totalRequests)', 'ALL'),
                            _buildFilterChip('بانتظار السويفت ($pendingSwift)', 'PENDING'),
                            _buildFilterChip('مطابق ($matchedSwift)', 'MATCHED'),
                            _buildFilterChip('فروقات ($discrepancySwift)', 'DEFICIT'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table of Payment Requests & SWIFTs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.table_chart, color: AppTheme.charcoal, size: 20),
                                  const SizedBox(width: 8),
                                  Text('سجل طلبات السداد ومطابقة السويفت (${filtered.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                              const Row(
                                children: [
                                  Icon(Icons.bolt, color: Colors.orange, size: 16),
                                  SizedBox(width: 4),
                                  Text('التحديث التلقائي لملفات الشحنة مفعل ⚡', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('لا توجد طلبات سداد تطابق معايير البحث الحالية.', style: TextStyle(color: Colors.grey))),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                              columns: const [
                                DataColumn(label: Text('كود الطلب / الملف', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المورد المستفيد والبنك', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('تاريخ تقديم الطلب', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('تاريخ استلام السويفت', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('مدة التنفيذ', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المبلغ المطلوب', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('المبلغ المنفذ بالسويفت', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('حالة المطابقة والفارق', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('رقم السويفت (MT103)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('⚡ العمليات', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filtered.map((pay) {
                                final isReconciled = pay.swiftReferenceNo != null && pay.swiftReferenceNo!.isNotEmpty;
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(pay.paymentCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                          if (pay.importFileCode != null)
                                            Text(pay.importFileCode!, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(pay.beneficiaryName ?? pay.supplierName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                          Text(pay.bankName ?? 'بنك غير محدد', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(pay.requestDate.isNotEmpty ? pay.requestDate : '-')),
                                    DataCell(
                                      Text(
                                        pay.swiftReceiptDate ?? 'بانتظار السويفت',
                                        style: TextStyle(
                                          fontWeight: isReconciled ? FontWeight.bold : FontWeight.normal,
                                          color: isReconciled ? AppTheme.charcoal : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      pay.swiftProcessingDays != null
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: pay.swiftProcessingDays! <= 3 ? Colors.green.shade50 : (pay.swiftProcessingDays! <= 7 ? Colors.orange.shade50 : Colors.red.shade50),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: pay.swiftProcessingDays! <= 3 ? Colors.green.shade300 : (pay.swiftProcessingDays! <= 7 ? Colors.orange.shade300 : Colors.red.shade300),
                                                ),
                                              ),
                                              child: Text(
                                                '⚡ ${pay.swiftProcessingDays} يوم',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: pay.swiftProcessingDays! <= 3 ? Colors.green.shade800 : (pay.swiftProcessingDays! <= 7 ? Colors.orange.shade900 : Colors.red.shade900),
                                                ),
                                              ),
                                            )
                                          : const Text('⏳ معلق', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ),
                                    DataCell(Text('${pay.requestedAmount.toStringAsFixed(2)} ${pay.currencyCode}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(
                                      pay.swiftTransferredAmount != null
                                          ? Text(
                                              '${pay.swiftTransferredAmount!.toStringAsFixed(2)} ${pay.swiftTransferredCurrency ?? pay.currencyCode}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald),
                                            )
                                          : const Text('-', style: TextStyle(color: Colors.grey)),
                                    ),
                                    DataCell(_buildVarianceBadge(pay.swiftVarianceStatus, pay.swiftVarianceAmount, pay.currencyCode)),
                                    DataCell(
                                      pay.swiftReferenceNo != null && pay.swiftReferenceNo!.isNotEmpty
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade200)),
                                              child: Text(pay.swiftReferenceNo!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 11)),
                                            )
                                          : const Text('غير مسجل', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isReconciled ? AppTheme.cobalt : AppTheme.emerald,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            ),
                                            icon: Icon(isReconciled ? Icons.edit : Icons.account_balance, color: Colors.white, size: 14),
                                            label: Text(
                                              isReconciled ? 'تعديل السويفت' : 'تسجيل السويفت',
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            onPressed: () => _showSwiftReconciliationDialog(pay),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(Icons.visibility, color: AppTheme.charcoal, size: 18),
                                            tooltip: 'عرض التفاصيل',
                                            onPressed: () => _showSwiftDetailsDialog(pay),
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
                ],
              ),
            ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppTheme.charcoal)),
      selected: isSelected,
      selectedColor: AppTheme.cobalt,
      backgroundColor: Colors.grey.shade100,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStatusFilter = value);
      },
    );
  }
}
