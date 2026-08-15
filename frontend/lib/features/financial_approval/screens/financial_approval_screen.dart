import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/financial_approval_model.dart';
import '../providers/financial_approval_provider.dart';
import '../services/financial_export_service.dart';

class FinancialApprovalScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  final int? initialImportFileId;
  const FinancialApprovalScreen({super.key, this.initialIndex = 0, this.initialImportFileId});

  @override
  ConsumerState<FinancialApprovalScreen> createState() => _FinancialApprovalScreenState();
}

class _FinancialApprovalScreenState extends ConsumerState<FinancialApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Payment Request Form State (BP-012)
  final _paymentFormKey = GlobalKey<FormState>();
  final TextEditingController _payTitleController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController(text: '50.0');
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _swiftCodeController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _payNotesController = TextEditingController();

  String _paymentType = 'Advance Payment';
  String _currencyCode = 'USD';
  DateTime _requestDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 12));
  int? _selectedSupplierId;
  int? _paySelectedImportFileId;
  BudgetPrefillModel? _payPrefillData;
  bool _isSavingPayment = false;
  bool _isLoadingPayPrefill = false;

  // Import Budget Form State (BP-013)
  final _budgetFormKey = GlobalKey<FormState>();
  final TextEditingController _bgtTitleController = TextEditingController();
  final TextEditingController _invoiceEgpController = TextEditingController(text: '0.0');
  final TextEditingController _invoiceForeignController = TextEditingController(text: '0.0');
  final TextEditingController _freightEgpController = TextEditingController(text: '0.0');
  final TextEditingController _freightForeignController = TextEditingController(text: '0.0');
  final TextEditingController _customsEgpController = TextEditingController(text: '0.0');
  final TextEditingController _clearanceEgpController = TextEditingController(text: '0.0');
  final TextEditingController _bgtExchangeRateController = TextEditingController(text: '50.0');
  final TextEditingController _bgtNotesController = TextEditingController();
  
  String _bgtInvoiceCurrency = 'USD';
  String _bgtFreightCurrency = 'USD';
  int? _bgtSelectedImportFileId;
  BudgetPrefillModel? _bgtPrefillData;
  ImportBudgetModel? _lastSavedBudget;
  bool _isSavingBudget = false;
  bool _isLoadingBgtPrefill = false;

  // Search & Filter
  String _searchQuery = '';
  String _statusFilter = 'All';

  // Edit Mode for Tab 1 (Payment Requests)
  int? _editingPaymentId;
  String? _editingPaymentCode;

  double _getExchangeRateForCurrency(String currencyCode) {
    if (currencyCode.toUpperCase() == 'EGP') return 1.0;
    final currencies = ref.read(currenciesProvider).value ?? [];
    final cur = currencies.where((c) => c.currencyCode.toUpperCase() == currencyCode.toUpperCase()).firstOrNull;
    if (cur != null) {
      if (cur.isBaseCurrency) return 1.0;
      if (cur.latestCommercialRate != null && cur.latestCommercialRate! > 0) {
        return cur.latestCommercialRate!;
      }
    }
    return 50.0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex);
    Future.microtask(() {
      ref.read(currenciesProvider.notifier).fetchCurrencies();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(suppliersProvider.notifier).fetchSuppliers();
      ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests();
      ref.read(importBudgetsProvider.notifier).fetchImportBudgets();
      
      if (widget.initialImportFileId != null) {
        _onPayImportFileSelected(widget.initialImportFileId);
        _onBgtImportFileSelected(widget.initialImportFileId);
      }
    });
  }

  @override
  void didUpdateWidget(FinancialApprovalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _tabController.animateTo(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _payTitleController.dispose();
    _supplierNameController.dispose();
    _amountController.dispose();
    _exchangeRateController.dispose();
    _bankNameController.dispose();
    _swiftCodeController.dispose();
    _ibanController.dispose();
    _payNotesController.dispose();

    _bgtTitleController.dispose();
    _invoiceEgpController.dispose();
    _invoiceForeignController.dispose();
    _freightEgpController.dispose();
    _freightForeignController.dispose();
    _customsEgpController.dispose();
    _clearanceEgpController.dispose();
    _bgtExchangeRateController.dispose();
    _bgtNotesController.dispose();
    super.dispose();
  }

  // ── Auto-Fetch & Duplicate Guard for Tab 1 (Payment Requests) ──────────────
  Future<void> _onPayImportFileSelected(int? fileId) async {
    if (fileId == null) {
      setState(() {
        _paySelectedImportFileId = null;
        _payPrefillData = null;
      });
      return;
    }

    // Check for existing Payment Request duplicate
    final existingList = ref.read(paymentRequestsProvider).value ?? [];
    final existing = existingList.where((p) => p.importFileId == fileId && p.isActive).firstOrNull;
    if (existing != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('طلب سداد مالي محفوظ مسبقاً'),
              ],
            ),
            content: Text(
              '⚠️ تم إصدار وحفظ طلب سداد مالي سابق لملف الشحنة هذا (${existing.paymentCode} - ${existing.title}).\n\nوفقاً للسياسة، لا يمكن إنشاء طلب جديد مكرر، ويجب الذهاب للتعديل على الطلب الحالي.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _paySelectedImportFileId = null;
                    _payPrefillData = null;
                  });
                },
                child: const Text('إلغاء التحديد'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                icon: const Icon(Icons.visibility, color: Colors.white, size: 16),
                label: const Text('استعراض وتعديل طلب السداد الحالي', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showPaymentDetailsDialog(existing);
                },
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _paySelectedImportFileId = fileId;
      _isLoadingPayPrefill = true;
    });

    try {
      final prefill = await ref.read(importBudgetsProvider.notifier).fetchBudgetPrefill(fileId);
      if (prefill != null && mounted) {
        final invCurr = prefill.invoiceCurrency.isNotEmpty ? prefill.invoiceCurrency : 'USD';
        final dynamicRate = _getExchangeRateForCurrency(invCurr);
        final effRate = dynamicRate > 0 ? dynamicRate : (prefill.exchangeRate > 0 ? prefill.exchangeRate : 50.0);

        setState(() {
          _payPrefillData = prefill;
          _payTitleController.text = '${prefill.incoterm} - ${prefill.importFileTitle}';
          _selectedSupplierId = prefill.supplierId;
          _supplierNameController.text = prefill.beneficiaryName ?? prefill.supplierName;
          _paymentType = prefill.paymentTermsSummary.isNotEmpty ? prefill.paymentTermsSummary : 'Advance Payment';
          _amountController.text = prefill.totalInvoiceAmount.toStringAsFixed(2);
          _currencyCode = invCurr;
          _exchangeRateController.text = effRate.toStringAsFixed(2);
          _bankNameController.text = prefill.bankName ?? '';
          _swiftCodeController.text = prefill.swiftCode ?? '';
          _ibanController.text = prefill.iban ?? prefill.accountNumber ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingPayPrefill = false);
    }
  }

  // ── Auto-Fetch & Duplicate Guard for Tab 2 (Budget Approval) ───────────────
  Future<void> _onBgtImportFileSelected(int? fileId) async {
    if (fileId == null) {
      setState(() {
        _bgtSelectedImportFileId = null;
        _bgtPrefillData = null;
      });
      return;
    }

    // Check for existing Budget Approval duplicate
    final existingList = ref.read(importBudgetsProvider).value ?? [];
    final existing = existingList.where((b) => b.importFileId == fileId && b.isActive).firstOrNull;
    if (existing != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('اعتماد ميزانية محفوظ مسبقاً'),
              ],
            ),
            content: Text(
              '⚠️ تم اعتماد ميزانية سابقة لملف الشحنة هذا (${existing.budgetCode} - ${existing.title}).\n\nوفقاً للسياسة، لا يمكن إنشاء اعتماد ميزانية مكرر، ويجب الذهاب للاستعراض والتعديل على الميزانية الحالية.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _bgtSelectedImportFileId = null;
                    _bgtPrefillData = null;
                  });
                },
                child: const Text('إلغاء التحديد'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                icon: const Icon(Icons.print, color: Colors.white, size: 16),
                label: const Text('استعراض وطباعة الميزانية الحالية', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showBudgetDetailsDialog(existing);
                },
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _bgtSelectedImportFileId = fileId;
      _isLoadingBgtPrefill = true;
    });

    try {
      final prefill = await ref.read(importBudgetsProvider.notifier).fetchBudgetPrefill(fileId);
      if (prefill != null && mounted) {
        final invCurr = prefill.invoiceCurrency.isNotEmpty ? prefill.invoiceCurrency : 'USD';
        final dynamicRate = _getExchangeRateForCurrency(invCurr);
        final effRate = dynamicRate > 0 ? dynamicRate : (prefill.exchangeRate > 0 ? prefill.exchangeRate : 50.0);

        setState(() {
          _bgtPrefillData = prefill;
          _bgtTitleController.text = 'اعتماد الميزانية الاستيرادية الكلية لشحنة ${prefill.importFileTitle}';
          
          _invoiceForeignController.text = prefill.totalInvoiceAmount.toStringAsFixed(2);
          _bgtInvoiceCurrency = invCurr;
          _invoiceEgpController.text = (prefill.totalInvoiceAmount * effRate).toStringAsFixed(2);
          
          _freightForeignController.text = prefill.estimatedFreightCost.toStringAsFixed(2);
          _bgtFreightCurrency = prefill.freightCurrency;
          _freightEgpController.text = (prefill.estimatedFreightCost * effRate).toStringAsFixed(2);
          
          _customsEgpController.text = prefill.estimatedCustomsDutiesEgp.toStringAsFixed(2);
          _clearanceEgpController.text = prefill.estimatedClearanceFeesEgp.toStringAsFixed(2);
          _bgtExchangeRateController.text = effRate.toStringAsFixed(2);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingBgtPrefill = false);
    }
  }

  Future<void> _savePaymentRequest() async {
    if (!_paymentFormKey.currentState!.validate()) return;

    setState(() => _isSavingPayment = true);
    try {
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final rate = double.tryParse(_exchangeRateController.text.trim()) ?? 50.0;

      final payload = {
        'title': _payTitleController.text.trim(),
        'import_file_id': _paySelectedImportFileId,
        'supplier_id': _selectedSupplierId,
        'supplier_name': _supplierNameController.text.trim(),
        'beneficiary_name': _supplierNameController.text.trim(),
        'payment_type': _paymentType,
        'requested_amount': amount,
        'currency_code': _currencyCode,
        'exchange_rate': rate,
        'request_date': _requestDate.toString().substring(0, 10),
        'due_date': _dueDate.toString().substring(0, 10),
        'bank_name': _bankNameController.text.trim(),
        'swift_code': _swiftCodeController.text.trim(),
        'iban_account_no': _ibanController.text.trim(),
        'notes': _payNotesController.text.trim(),
      };

      if (_editingPaymentId != null) {
        final updated = await ref.read(paymentRequestsProvider.notifier).updatePaymentRequest(_editingPaymentId!, payload);
        if (mounted && updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ تم تعديل طلب السداد بنجاح (${updated.paymentCode})'), backgroundColor: AppTheme.emerald),
          );
          setState(() {
            _editingPaymentId = null;
            _editingPaymentCode = null;
          });
          _showPaymentDetailsDialog(updated);
        }
      } else {
        final created = await ref.read(paymentRequestsProvider.notifier).createPaymentRequest(payload);
        if (mounted && created != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ تم إصدار طلب السداد بنجاح (${created.paymentCode})'), backgroundColor: AppTheme.emerald),
          );
          _showPaymentDetailsDialog(created);
        }
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: '❌ تعذر حفظ طلب السداد المالي',
          error: e,
          onRetry: () async {
            await _savePaymentRequest();
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPayment = false);
    }
  }

  void _loadPaymentRequestForEdit(PaymentRequestModel p) {
    setState(() {
      _editingPaymentId = p.paymentId;
      _editingPaymentCode = p.paymentCode;
      _paySelectedImportFileId = p.importFileId;
      _payTitleController.text = p.title;
      _selectedSupplierId = p.supplierId;
      _supplierNameController.text = p.beneficiaryName ?? p.supplierName;
      _paymentType = p.paymentType;
      _amountController.text = p.requestedAmount.toStringAsFixed(2);
      _currencyCode = p.currencyCode;
      _exchangeRateController.text = p.exchangeRate.toStringAsFixed(2);
      _bankNameController.text = p.bankName ?? '';
      _swiftCodeController.text = p.swiftCode ?? '';
      _ibanController.text = p.ibanAccountNo ?? '';
      _payNotesController.text = p.notes ?? '';
      _dueDate = DateTime.tryParse(p.dueDate) ?? DateTime.now().add(const Duration(days: 12));
      _requestDate = p.requestDate.isNotEmpty ? (DateTime.tryParse(p.requestDate) ?? DateTime.now()) : DateTime.now();
    });
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✏️ تم تحميل طلب السداد (${p.paymentCode}) للتعديل'),
        backgroundColor: AppTheme.cobalt,
      ),
    );
  }

  Future<void> _confirmDeletePaymentRequest(PaymentRequestModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('تأكيد حذف طلب السداد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('هل أنت متأكد من رغبتك في حذف طلب السداد المالي (${p.paymentCode} - ${p.title})؟\n\nسيتم أرشفة السجل وإمكانية استعادته لاحقاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            icon: const Icon(Icons.delete, color: Colors.white, size: 16),
            label: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(paymentRequestsProvider.notifier).softDeletePaymentRequest(p.paymentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🗑️ تم حذف طلب السداد (${p.paymentCode}) بنجاح'), backgroundColor: AppTheme.emerald),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ خطأ أثناء الحذف: $e'), backgroundColor: AppTheme.crimson),
          );
        }
      }
    }
  }

  Future<void> _saveImportBudget() async {
    if (!_budgetFormKey.currentState!.validate()) return;

    setState(() => _isSavingBudget = true);
    try {
      final invForeign = double.tryParse(_invoiceForeignController.text.trim()) ?? 0.0;
      final invEgp = double.tryParse(_invoiceEgpController.text.trim()) ?? 0.0;
      final frtForeign = double.tryParse(_freightForeignController.text.trim()) ?? 0.0;
      final frtEgp = double.tryParse(_freightEgpController.text.trim()) ?? 0.0;
      final custEgp = double.tryParse(_customsEgpController.text.trim()) ?? 0.0;
      final clrEgp = double.tryParse(_clearanceEgpController.text.trim()) ?? 0.0;
      final rate = double.tryParse(_bgtExchangeRateController.text.trim()) ?? 50.0;

      final payload = {
        'title': _bgtTitleController.text.trim(),
        'import_file_id': _bgtSelectedImportFileId,
        'invoice_amount_foreign': invForeign,
        'invoice_currency': _bgtInvoiceCurrency,
        'invoice_amount_egp': invEgp,
        'freight_cost_foreign': frtForeign,
        'freight_currency': _bgtFreightCurrency,
        'freight_cost_egp': frtEgp,
        'customs_duties_egp': custEgp,
        'clearance_inland_egp': clrEgp,
        'exchange_rate': rate,
        'notes': _bgtNotesController.text.trim(),
      };

      final created = await ref.read(importBudgetsProvider.notifier).createImportBudget(payload);
      if (mounted && created != null) {
        setState(() => _lastSavedBudget = created);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم اعتماد وحفظ الميزانية الاستيرادية (${created.budgetCode})'), backgroundColor: AppTheme.emerald),
        );
        _showBudgetDetailsDialog(created);
      }
    } catch (e) {
      if (mounted) {
        await showErrorDetailsDialog(
          context,
          title: '❌ تعذر اعتماد وحفظ الميزانية الاستيرادية',
          error: e,
          onRetry: () async {
            await _saveImportBudget();
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBudget = false);
    }
  }

  void _showPaymentDetailsDialog(PaymentRequestModel pay) {
    final swiftController = TextEditingController(text: pay.swiftReferenceNo ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('طلب سداد مالي: ${pay.paymentCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildStatusBadge(pay.status),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pay.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                  const SizedBox(height: 6),
                  Text('المورد المستفيد: ${pay.beneficiaryName ?? pay.supplierName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('طريقة السداد: ${pay.paymentType} | تاريخ تقديم الطلب: ${pay.requestDate.isNotEmpty ? pay.requestDate : "-"} | تاريخ الاستحقاق: ${pay.dueDate}'),
                  const Divider(),
                  Row(
                    children: [
                      _buildMetricBadge('المبلغ بالعملة الأجنبية', '${pay.requestedAmount} ${pay.currencyCode}', AppTheme.cobalt),
                      const SizedBox(width: 10),
                      _buildMetricBadge('سعر الصرف', '${pay.exchangeRate} EGP', Colors.orange),
                      const SizedBox(width: 10),
                      _buildMetricBadge('المعادل بالجنيه', '${pay.requestedAmountEgp.toStringAsFixed(2)} EGP', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('بيانات البنك المستفيد (Beneficiary Bank Details):', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                        const SizedBox(height: 4),
                        Text('اسم البنك: ${pay.bankName ?? "-"}'),
                        Text('كود السويفت (SWIFT): ${pay.swiftCode ?? "-"}'),
                        Text('رقم الحساب / IBAN: ${pay.ibanAccountNo ?? "-"}'),
                      ],
                    ),
                  ),
                  if (pay.status == 'Approved') ...[
                    const Divider(),
                    TextField(
                      controller: swiftController,
                      decoration: const InputDecoration(labelText: 'رقم إشعار التحويل البنكي (SWIFT Copy Reference) *', border: OutlineInputBorder()),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            if (pay.status == 'Draft' || pay.status == 'Pending Approval') ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await ref.read(paymentRequestsProvider.notifier).approvePaymentRequest(pay.paymentId);
                  nav.pop();
                },
                child: const Text('اعتماد الطلب (Approve)', style: TextStyle(color: Colors.white)),
              ),
            ],
            if (pay.status == 'Approved') ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await ref.read(paymentRequestsProvider.notifier).executePayment(pay.paymentId, swiftRef: swiftController.text.trim());
                  nav.pop();
                },
                child: const Text('تأكيد التحويل والسداد (Mark as Paid)', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showBudgetDetailsDialog(ImportBudgetModel bgt) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('اعتماد الميزانية: ${bgt.budgetCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildStatusBadge(bgt.budgetStatus),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bgt.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                  const SizedBox(height: 12),
                  
                  // Multi-currency details in modal
                  _buildConsolidatedBudgetSummary(bgt: bgt, prefill: _bgtPrefillData),
                  
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.table_chart, color: Colors.green),
                        label: const Text('تصدير EXCEL'),
                        onPressed: () async {
                          final path = await FinancialExportService.exportBudgetToExcel(
                            context: context,
                            budget: bgt,
                            prefill: _bgtPrefillData,
                          );
                          if (path != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('✅ تم تصدير ملف Excel بنجاح: $path'), backgroundColor: Colors.green),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                        icon: const Icon(Icons.print, color: Colors.white),
                        label: const Text('طباعة / حفظ PDF', style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          FinancialExportService.printOrSaveBudgetPdf(
                            budget: bgt,
                            prefill: _bgtPrefillData,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            if (bgt.budgetStatus == 'Pending Review' || bgt.budgetStatus == 'Draft') ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await ref.read(importBudgetsProvider.notifier).approveImportBudget(bgt.budgetId);
                  nav.pop();
                },
                child: const Text('اعتماد الميزانية رسمياً (Approve Budget)', style: TextStyle(color: Colors.white)),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliersState = ref.watch(suppliersProvider);
    final paymentsState = ref.watch(paymentRequestsProvider);

    final suppliersList = suppliersState.value ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('الموافقات المالية وإدارة الميزانية (Phase 2 – Financial & Management Approval)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: const [
          BackToDashboardButton(),
          SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cobalt,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.payment), text: 'Payment Requests (BP-012 طلبات السداد المالي)'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Import Budget Approval (BP-013 اعتماد الميزانية)'),
            Tab(icon: Icon(Icons.history), text: 'Financial History Registry (سجل العمليات المالي)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: PAYMENT REQUEST FORM (BP-012) ───────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _paymentFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_editingPaymentId != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_note, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'وضع التعديل النشط: تعديل بيانات طلب السداد المالي ($_editingPaymentCode)',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                    label: const Text('إلغاء التعديل', style: TextStyle(color: Colors.red)),
                                    onPressed: () {
                                      setState(() {
                                        _editingPaymentId = null;
                                        _editingPaymentCode = null;
                                        _payTitleController.clear();
                                        _supplierNameController.clear();
                                        _amountController.clear();
                                        _payNotesController.clear();
                                        _paySelectedImportFileId = null;
                                        _payPrefillData = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _editingPaymentId != null
                                    ? 'تعديل بيانات طلب السداد الحالي ($_editingPaymentCode)'
                                    : 'إصدار طلب سداد / تحويل مالي للمورد (Create Payment Request)',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                              ),
                              if (_isLoadingPayPrefill) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _paySelectedImportFileId,
                                  labelText: 'Import File (ملف الشحنة الاستيرادية) *',
                                  searchHintText: 'ابحث عن ملف الشحنة...',
                                  items: [
                                    const SearchableDropdownItem<int?>(
                                      value: null,
                                      label: '-- None / غير مرتبط بملف شحنة --',
                                    ),
                                    ...(ref.watch(importFilesProvider).value ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                          subtitle: f.companyName,
                                        )),
                                  ],
                                  onChanged: _onPayImportFileSelected,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _payTitleController,
                                  decoration: const InputDecoration(labelText: 'عنوان طلب السداد (INCOTERM + اسم الملف) *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال العنوان' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _selectedSupplierId,
                                  labelText: 'اختر المورد من Master Data',
                                  searchHintText: 'ابحث عن المورد...',
                                  items: suppliersList
                                      .map((s) => SearchableDropdownItem<int?>(
                                            value: s.supplierId,
                                            label: s.companyName,
                                            subtitle: s.foreignExporterCountry,
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final sup = suppliersList.firstWhere((s) => s.supplierId == val);
                                      setState(() {
                                        _selectedSupplierId = val;
                                        _supplierNameController.text = sup.companyName;
                                        if (sup.bankName != null && sup.bankName!.isNotEmpty) _bankNameController.text = sup.bankName!;
                                        if (sup.swiftCode != null && sup.swiftCode!.isNotEmpty) _swiftCodeController.text = sup.swiftCode!;
                                        if (sup.iban != null && sup.iban!.isNotEmpty) {
                                          _ibanController.text = sup.iban!;
                                        } else if (sup.accountNumber != null && sup.accountNumber!.isNotEmpty) {
                                          _ibanController.text = sup.accountNumber!;
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _supplierNameController,
                                  decoration: const InputDecoration(labelText: 'اسم المورد المستفيد *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المورد' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: _paymentType,
                                  key: ValueKey('pay_type_$_paymentType'),
                                  decoration: const InputDecoration(labelText: 'نوع طريقة السداد من شروط الدفع *', border: OutlineInputBorder()),
                                  onChanged: (v) => _paymentType = v,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'المبلغ المطلوب بالعملة *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0) ? 'أدخل مبلغاً صحيحاً' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SearchableDropdownField<String>(
                                  value: _currencyCode,
                                  labelText: 'العملة *',
                                  searchHintText: 'ابحث عن العملة...',
                                  items: const [
                                    SearchableDropdownItem(value: 'USD', label: 'USD - دولار أمريكي'),
                                    SearchableDropdownItem(value: 'EUR', label: 'EUR - يورو أوروبي'),
                                    SearchableDropdownItem(value: 'EGP', label: 'EGP - جنيه مصري'),
                                    SearchableDropdownItem(value: 'GBP', label: 'GBP - جنيه إسترليني'),
                                    SearchableDropdownItem(value: 'CNY', label: 'CNY - يوان صيني'),
                                    SearchableDropdownItem(value: 'SAR', label: 'SAR - ريال سعودي'),
                                    SearchableDropdownItem(value: 'AED', label: 'AED - درهم إماراتي'),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _currencyCode = val;
                                        final rate = _getExchangeRateForCurrency(val);
                                        _exchangeRateController.text = rate.toStringAsFixed(2);
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _exchangeRateController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'سعر الصرف المتوقع (EGP) *', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: _requestDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (d != null) setState(() => _requestDate = d);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'تاريخ تقديم الطلب *', border: OutlineInputBorder()),
                                    child: Text(_requestDate.toString().substring(0, 10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: _dueDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (d != null) setState(() => _dueDate = d);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'تاريخ الاستحقاق المطلوب *', border: OutlineInputBorder()),
                                    child: Text(_dueDate.toString().substring(0, 10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Supplier Banking Details Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('بيانات التحويل البنكي للمورد الأجنبي (Beneficiary Supplier Bank Details):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _bankNameController,
                                        decoration: const InputDecoration(labelText: 'اسم بنك المورد (Bank Name)', border: OutlineInputBorder()),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _swiftCodeController,
                                        decoration: const InputDecoration(labelText: 'كود السويفت (SWIFT Code)', border: OutlineInputBorder()),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _ibanController,
                                        decoration: const InputDecoration(labelText: 'رقم الحساب / IBAN', border: OutlineInputBorder()),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Linked Purchase Orders Table for Payment Request
                          if (_payPrefillData != null && _payPrefillData!.linkedPos.isNotEmpty) ...[
                            const Text('🛒 قائمة أوامر الشراء المرتبطة بطلب السداد (Linked Purchase Orders):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
                            const SizedBox(height: 8),
                            Table(
                              border: TableBorder.all(color: Colors.grey.shade300),
                              columnWidths: const {
                                0: FlexColumnWidth(1.5),
                                1: FlexColumnWidth(1.5),
                                2: FlexColumnWidth(2.0),
                                3: FlexColumnWidth(1.5),
                                4: FlexColumnWidth(1.2),
                                5: FlexColumnWidth(1.2),
                              },
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: AppTheme.charcoal),
                                  children: [
                                    Padding(padding: EdgeInsets.all(8), child: Text('رقم أمر الشراء (PO #)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('اسم المشروع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('طريقة وشروط السداد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('العملة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('قيمة الفاتورة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('الحالة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                ),
                                ..._payPrefillData!.linkedPos.map((po) {
                                  return TableRow(
                                    children: [
                                      Padding(padding: const EdgeInsets.all(8), child: Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(po.projectName ?? '-')),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade200)),
                                          child: Text(po.paymentTerms, style: TextStyle(fontSize: 11, color: Colors.brown.shade800, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(po.currency, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text('${po.totalAmount.toStringAsFixed(2)} ${po.currency}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                      Padding(padding: const EdgeInsets.all(8), child: Text(po.status, style: const TextStyle(fontSize: 11, color: AppTheme.cobalt))),
                                    ],
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            controller: _payNotesController,
                            decoration: const InputDecoration(labelText: 'ملاحظات طلب السداد الإدارية', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _editingPaymentId != null ? AppTheme.emerald : AppTheme.cobalt,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              onPressed: _isSavingPayment ? null : _savePaymentRequest,
                              icon: _isSavingPayment
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Icon(_editingPaymentId != null ? Icons.save : Icons.send, color: Colors.white),
                              label: Text(
                                _editingPaymentId != null ? 'حفظ تعديلات طلب السداد' : 'إصدار طلب السداد للإدارة المالية',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── TAB 2: IMPORT BUDGET APPROVAL FORM (BP-013) ────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _budgetFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('اعتماد ميزانية ملف الاستيراد الشاملة (Import Budget Approval Setup)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              if (_isLoadingBgtPrefill) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _bgtSelectedImportFileId,
                                  labelText: 'Import File (ملف الشحنة الاستيرادية) *',
                                  searchHintText: 'ابحث عن ملف الشحنة...',
                                  items: [
                                    const SearchableDropdownItem<int?>(
                                      value: null,
                                      label: '-- None / غير مرتبط بملف شحنة --',
                                    ),
                                    ...(ref.watch(importFilesProvider).value ?? []).map((f) => SearchableDropdownItem<int?>(
                                          value: f.importFileId,
                                          label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                                          subtitle: f.companyName,
                                        )),
                                  ],
                                  onChanged: _onBgtImportFileSelected,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _bgtTitleController,
                                  decoration: const InputDecoration(labelText: 'عنوان الميزانية الاستيرادية *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال العنوان' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Multi-Currency Live Consolidated Breakdown Tables
                          _buildConsolidatedBudgetSummary(prefill: _bgtPrefillData),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _invoiceForeignController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: 'قيمة الفاتورة المبدئية ($_bgtInvoiceCurrency FOB/CIF)', border: const OutlineInputBorder()),
                                  onChanged: (v) {
                                    final f = double.tryParse(v) ?? 0;
                                    final r = double.tryParse(_bgtExchangeRateController.text) ?? 50;
                                    _invoiceEgpController.text = (f * r).toStringAsFixed(2);
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _freightForeignController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: 'تكلفة النولون المقدرة ($_bgtFreightCurrency Freight)', border: const OutlineInputBorder()),
                                  onChanged: (v) {
                                    final f = double.tryParse(v) ?? 0;
                                    final r = double.tryParse(_bgtExchangeRateController.text) ?? 50;
                                    _freightEgpController.text = (f * r).toStringAsFixed(2);
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _customsEgpController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'الضرائب والجمارك والـ VAT (EGP)', border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _clearanceEgpController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'أتعاب التخليص والنقل (EGP)', border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _bgtNotesController,
                            decoration: const InputDecoration(labelText: 'ملاحظات وتوجيهات اعتماد الميزانية', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                                onPressed: _isSavingBudget ? null : _saveImportBudget,
                                icon: _isSavingBudget ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified, color: Colors.white),
                                label: const Text('التصديق واعتماد الميزانية الشاملة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.table_chart, color: Colors.green),
                                    label: const Text('تصدير EXCEL'),
                                    onPressed: () async {
                                      final bgt = _lastSavedBudget ?? _buildTempBudgetModel();
                                      final messenger = ScaffoldMessenger.of(context);
                                      final path = await FinancialExportService.exportBudgetToExcel(
                                        context: context,
                                        budget: bgt,
                                        prefill: _bgtPrefillData,
                                      );
                                      if (path != null && mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text('✅ تم تصدير ملف Excel بنجاح: $path'), backgroundColor: Colors.green),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                    icon: const Icon(Icons.print, color: Colors.white),
                                    label: const Text('طباعة / حفظ PDF', style: TextStyle(color: Colors.white)),
                                    onPressed: () {
                                      final bgt = _lastSavedBudget ?? _buildTempBudgetModel();
                                      FinancialExportService.printOrSaveBudgetPdf(
                                        budget: bgt,
                                        prefill: _bgtPrefillData,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── TAB 3: FINANCIAL HISTORY REGISTRY (سجل العمليات المالي) ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Master Data Toolbar
                paymentsState.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (payments) {
                    final filtered = payments.where((p) {
                      final matchQ = _searchQuery.isEmpty ||
                          p.paymentCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          p.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          (p.importFileCode ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                      final matchS = _statusFilter == 'All' || p.status == _statusFilter;
                      return matchQ && matchS;
                    }).toList();

                    return MasterDataToolbarWidget(
                      moduleEndpoint: 'financial-approval',
                      title: 'سجل العمليات والتحويلات المالية للموردين (${filtered.length})',
                      onExportExcel: () => FinancialExportService.exportPaymentRequestsListToExcel(context: context, list: filtered),
                      onRefreshNeeded: () => ref.read(paymentRequestsProvider.notifier).fetchPaymentRequests(),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Search & Filters Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'البحث بكود الطلب أو اسم المورد أو رقم الملف أو العنوان...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: SearchableDropdownField<String>(
                        value: _statusFilter,
                        labelText: 'تصفية حسب الحالة',
                        searchHintText: 'ابحث عن الحالة...',
                        items: const [
                          SearchableDropdownItem(value: 'All', label: 'جميع الحالات'),
                          SearchableDropdownItem(value: 'Draft', label: 'Draft - مسودة طلب'),
                          SearchableDropdownItem(value: 'Approved', label: 'Approved - معتمد'),
                          SearchableDropdownItem(value: 'Paid', label: 'Paid - تم التحويل'),
                          SearchableDropdownItem(value: 'Reconciled', label: 'Reconciled - مطابق بالسويفت'),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _statusFilter = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Standardized Saved Registry Table Container
                Expanded(
                  child: paymentsState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('❌ Error: $err')),
                    data: (payments) {
                      final filtered = payments.where((p) {
                        final matchQ = _searchQuery.isEmpty ||
                            p.paymentCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            p.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            (p.importFileCode ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                        final matchS = _statusFilter == 'All' || p.status == _statusFilter;
                        return matchQ && matchS;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: Text(
                              'لا توجد طلبات سداد مالي مطابقة لخيارات البحث والتصفية.',
                              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                                    headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    columns: const [
                                      DataColumn(
                                        label: Row(
                                          children: [
                                            Icon(Icons.bolt, color: Colors.amber, size: 18),
                                            SizedBox(width: 6),
                                            Text('العمليات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      DataColumn(label: Text('كود الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('ملف الشحنة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المورد المستفيد والعنوان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('البنك / السويفت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('طريقة السداد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المبلغ المطلوب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('المعادل (EGP)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('تاريخ الطلب / الاستحقاق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الحالة العامة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: filtered.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final p = entry.value;
                                      final isEven = index % 2 == 0;

                                      return DataRow(
                                        color: WidgetStateProperty.all(isEven ? Colors.white : Colors.grey.shade50),
                                        cells: [
                                          DataCell(
                                            RowActionsPill(
                                              onView: () => _showPaymentDetailsDialog(p),
                                              onEdit: () => _loadPaymentRequestForEdit(p),
                                              onPrint: () => FinancialExportService.printPaymentRequestPdf(payment: p),
                                              onDelete: () => _confirmDeletePaymentRequest(p),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.cobalt.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                                              ),
                                              child: Text(
                                                p.paymentCode,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.charcoal.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                p.importFileCode ?? (p.importFileId != null ? 'IMP-${p.importFileId}' : '-'),
                                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(p.beneficiaryName ?? p.supplierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text(p.title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(p.bankName ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                                if (p.swiftCode != null && p.swiftCode!.isNotEmpty)
                                                  Text('SWIFT: ${p.swiftCode}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.amber.shade200),
                                              ),
                                              child: Text(p.paymentType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown.shade800)),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${p.requestedAmount.toStringAsFixed(2)} ${p.currencyCode}',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${p.requestedAmountEgp.toStringAsFixed(2)} EGP',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('الطلب: ${p.requestDate.isNotEmpty ? p.requestDate : "-"}', style: const TextStyle(fontSize: 11)),
                                                Text('الاستحقاق: ${p.dueDate}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                              ],
                                            ),
                                          ),
                                          DataCell(_buildStatusBadge(p.status)),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImportBudgetModel _buildTempBudgetModel() {
    final invForeign = double.tryParse(_invoiceForeignController.text.trim()) ?? 0.0;
    final invEgp = double.tryParse(_invoiceEgpController.text.trim()) ?? 0.0;
    final frtForeign = double.tryParse(_freightForeignController.text.trim()) ?? 0.0;
    final frtEgp = double.tryParse(_freightEgpController.text.trim()) ?? 0.0;
    final custEgp = double.tryParse(_customsEgpController.text.trim()) ?? 0.0;
    final clrEgp = double.tryParse(_clearanceEgpController.text.trim()) ?? 0.0;
    final rate = double.tryParse(_bgtExchangeRateController.text.trim()) ?? 50.0;

    return ImportBudgetModel(
      budgetId: 0,
      budgetCode: 'BGT-PREVIEW',
      title: _bgtTitleController.text.trim(),
      importFileId: _bgtSelectedImportFileId,
      invoiceAmountForeign: invForeign,
      invoiceCurrency: _bgtInvoiceCurrency,
      invoiceAmountEgp: invEgp,
      freightCostForeign: frtForeign,
      freightCurrency: _bgtFreightCurrency,
      freightCostEgp: frtEgp,
      customsDutiesEgp: custEgp,
      clearanceInlandEgp: clrEgp,
      exchangeRate: rate,
      totalBudgetEgp: invEgp + frtEgp + custEgp + clrEgp,
      budgetStatus: 'Pending Review',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  Widget _buildConsolidatedBudgetSummary({ImportBudgetModel? bgt, BudgetPrefillModel? prefill}) {
    final invForeign = bgt != null && bgt.invoiceAmountForeign > 0
        ? bgt.invoiceAmountForeign
        : (double.tryParse(_invoiceForeignController.text) ?? (prefill?.totalInvoiceAmount ?? 0));
    final invCurr = bgt != null ? bgt.invoiceCurrency : _bgtInvoiceCurrency;
    final invEgp = bgt != null && bgt.invoiceAmountEgp > 0
        ? bgt.invoiceAmountEgp
        : (double.tryParse(_invoiceEgpController.text) ?? (prefill?.totalInvoiceAmountEgp ?? 0));

    final frtForeign = bgt != null && bgt.freightCostForeign > 0
        ? bgt.freightCostForeign
        : (double.tryParse(_freightForeignController.text) ?? (prefill?.estimatedFreightCost ?? 0));
    final frtCurr = bgt != null ? bgt.freightCurrency : _bgtFreightCurrency;
    final frtEgp = bgt != null && bgt.freightCostEgp > 0
        ? bgt.freightCostEgp
        : (double.tryParse(_freightEgpController.text) ?? (prefill?.estimatedFreightCostEgp ?? 0));

    final custEgp = bgt != null && bgt.customsDutiesEgp > 0
        ? bgt.customsDutiesEgp
        : (double.tryParse(_customsEgpController.text) ?? (prefill?.estimatedCustomsDutiesEgp ?? 0));

    final clrEgp = bgt != null && bgt.clearanceInlandEgp > 0
        ? bgt.clearanceInlandEgp
        : (double.tryParse(_clearanceEgpController.text) ?? (prefill?.estimatedClearanceFeesEgp ?? 0));

    final grandTotalEgp = invEgp + frtEgp + custEgp + clrEgp;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.currency_exchange, color: AppTheme.cobalt, size: 20),
              SizedBox(width: 8),
              Text(
                'تقرير توزيع بنود الميزانية حسب العملات (Multi-Currency Budget Allocation):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Group 1: Foreign Currency Table
          const Text('1. بنود التكلفة بالعملة الأجنبية (Foreign Currency Costs):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt)),
          const SizedBox(height: 6),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2.0),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: AppTheme.cobalt),
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('البند المالي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('المبلغ بالعملة الأجنبية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('العملة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('المعادل بالجنيه (EGP)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('قيمة الفاتورة المبدئية (FOB Invoice)', style: TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(invForeign.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(invCurr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${invEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('تكلفة النولون والشحن المقدرة (Freight)', style: TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(frtForeign.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(frtCurr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${frtEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12))),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('إجمالي بنود العملة الأجنبية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text((invForeign + frtForeign).toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(invCurr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${(invEgp + frtEgp).toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Group 2: Local EGP Table
          const Text('2. بنود التكلفة بالعملة المحلية (Local Currency Costs):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.orange)),
          const SizedBox(height: 6),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FlexColumnWidth(2.0),
              1: FlexColumnWidth(1.8),
              2: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: AppTheme.orange),
                children: [
                  Padding(padding: EdgeInsets.all(6), child: Text('البند المالي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('جهة التحصيل / المرجع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('القيمة المعتمدة (EGP)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('الضرائب والرسوم الجمركية و VAT (نافذة)', style: TextStyle(fontSize: 12))),
                  const Padding(padding: EdgeInsets.all(6), child: Text('مصلحة الجمارك المصرية', style: TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${custEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 12))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('أتعاب التخليص الجمركي والنقل الداخلي', style: TextStyle(fontSize: 12))),
                  const Padding(padding: EdgeInsets.all(6), child: Text('المستخلص الجمركي والناقل', style: TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${clrEgp.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 12))),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('إجمالي بنود العملة المحلية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  const Padding(padding: EdgeInsets.all(6), child: Text('-', style: TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('${(custEgp + clrEgp).toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Approved Budget Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.emerald.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'إجمالي الميزانية الاستيرادية الكلية المعتمدة (Total Approved Budget):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                ),
                Text(
                  '${grandTotalEgp.toStringAsFixed(2)} EGP',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.emerald),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Paid' || status == 'Budget Approved') bg = Colors.green;
    if (status == 'Approved') bg = Colors.blue;
    if (status == 'Pending Approval' || status == 'Pending Review') bg = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
