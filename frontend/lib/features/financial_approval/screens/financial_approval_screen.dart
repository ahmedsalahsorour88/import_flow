import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/financial_approval_model.dart';
import '../providers/financial_approval_provider.dart';

class FinancialApprovalScreen extends ConsumerStatefulWidget {
  const FinancialApprovalScreen({super.key});

  @override
  ConsumerState<FinancialApprovalScreen> createState() => _FinancialApprovalScreenState();
}

class _FinancialApprovalScreenState extends ConsumerState<FinancialApprovalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Payment Request Form State (BP-012)
  final _paymentFormKey = GlobalKey<FormState>();
  final TextEditingController _payTitleController = TextEditingController(text: 'طلب صرف دفعة مقدمة (Advance Payment 30%) للمورد الأجنبي');
  final TextEditingController _supplierNameController = TextEditingController(text: 'Shanghai Machinery & Textile Exports Ltd.');
  final TextEditingController _amountController = TextEditingController(text: '18690.0');
  final TextEditingController _exchangeRateController = TextEditingController(text: '50.0');
  final TextEditingController _bankNameController = TextEditingController(text: 'Bank of China Shanghai Branch');
  final TextEditingController _swiftCodeController = TextEditingController(text: 'BKCHCN2SXXX');
  final TextEditingController _ibanController = TextEditingController(text: 'CN980100987654321');
  final TextEditingController _payNotesController = TextEditingController();

  String _paymentType = 'Advance Payment';
  String _currencyCode = 'USD';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 12));
  int? _selectedSupplierId;
  int? _paySelectedImportFileId;
  bool _isSavingPayment = false;

  // Import Budget Form State (BP-013)
  final _budgetFormKey = GlobalKey<FormState>();
  final TextEditingController _bgtTitleController = TextEditingController(text: 'اعتماد الميزانية الاستيرادية الكلية لشحنة آلات ومعدات النسيج');
  final TextEditingController _invoiceEgpController = TextEditingController(text: '3115000.0');
  final TextEditingController _freightEgpController = TextEditingController(text: '207500.0');
  final TextEditingController _customsEgpController = TextEditingController(text: '829000.0');
  final TextEditingController _clearanceEgpController = TextEditingController(text: '75000.0');
  final TextEditingController _bgtNotesController = TextEditingController();
  int? _bgtSelectedImportFileId;
  bool _isSavingBudget = false;

  // Search & Filter
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
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
    _freightEgpController.dispose();
    _customsEgpController.dispose();
    _clearanceEgpController.dispose();
    _bgtNotesController.dispose();
    super.dispose();
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
        'payment_type': _paymentType,
        'requested_amount': amount,
        'currency_code': _currencyCode,
        'exchange_rate': rate,
        'due_date': _dueDate.toString().substring(0, 10),
        'bank_name': _bankNameController.text.trim(),
        'swift_code': _swiftCodeController.text.trim(),
        'iban_account_no': _ibanController.text.trim(),
        'notes': _payNotesController.text.trim(),
      };

      final created = await ref.read(paymentRequestsProvider.notifier).createPaymentRequest(payload);
      if (mounted && created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم إنشاء طلب السداد المالي كود: ${created.paymentCode}'), backgroundColor: AppTheme.emerald),
        );
        _tabController.animateTo(2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ حدث خطأ أثناء إضافة طلب السداد: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPayment = false);
    }
  }

  Future<void> _saveImportBudget() async {
    if (!_budgetFormKey.currentState!.validate()) return;

    setState(() => _isSavingBudget = true);
    try {
      final inv = double.tryParse(_invoiceEgpController.text.trim()) ?? 0.0;
      final frt = double.tryParse(_freightEgpController.text.trim()) ?? 0.0;
      final cust = double.tryParse(_customsEgpController.text.trim()) ?? 0.0;
      final clr = double.tryParse(_clearanceEgpController.text.trim()) ?? 0.0;

      final payload = {
        'title': _bgtTitleController.text.trim(),
        'import_file_id': _bgtSelectedImportFileId,
        'invoice_amount_egp': inv,
        'freight_cost_egp': frt,
        'customs_duties_egp': cust,
        'clearance_inland_egp': clr,
        'notes': _bgtNotesController.text.trim(),
      };

      final created = await ref.read(importBudgetsProvider.notifier).createImportBudget(payload);
      if (mounted && created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم إنشاء واعتماد الميزانية الاستيرادية كود: ${created.budgetCode}'), backgroundColor: AppTheme.emerald),
        );
        _tabController.animateTo(2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ حدث خطأ أثناء إضافة الميزانية: $e'), backgroundColor: Colors.red),
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
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.payment, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Expanded(
                child: Text('طلب سداد تحويل مالي: ${pay.paymentCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _buildStatusBadge(pay.status),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('العنوان: ${pay.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('المورد المستفيد: ${pay.supplierName}'),
                  const SizedBox(height: 4),
                  Text('نوع الدفعة: ${pay.paymentType} | تاريخ الاستحقاق: ${pay.dueDate}'),
                  const Divider(),
                  Row(
                    children: [
                      _buildMetricBadge('المبلغ بالعملة الأجنبية', '${pay.requestedAmount} ${pay.currencyCode}', AppTheme.cobalt),
                      const SizedBox(width: 12),
                      _buildMetricBadge('سعر الصرف', '${pay.exchangeRate} EGP', Colors.orange),
                      const SizedBox(width: 12),
                      _buildMetricBadge('المبلغ المعادل بالجنيه', '${pay.requestedAmountEgp} EGP', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('بيانات البنك المستفيد (Beneficiary Bank Details):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('البنك: ${pay.bankName ?? "-"} | SWIFT: ${pay.swiftCode ?? "-"}'),
                  Text('رقم الحساب / IBAN: ${pay.ibanAccountNo ?? "-"}'),
                  const Divider(),
                  if (pay.status == 'Approved') ...[
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

  @override
  Widget build(BuildContext context) {
    final suppliersState = ref.watch(suppliersProvider);
    final paymentsState = ref.watch(paymentRequestsProvider);

    final suppliersList = suppliersState.value ?? [];

    final double invVal = double.tryParse(_invoiceEgpController.text.trim()) ?? 0.0;
    final double frtVal = double.tryParse(_freightEgpController.text.trim()) ?? 0.0;
    final double custVal = double.tryParse(_customsEgpController.text.trim()) ?? 0.0;
    final double clrVal = double.tryParse(_clearanceEgpController.text.trim()) ?? 0.0;
    final double totalBgtEgp = invVal + frtVal + custVal + clrVal;

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
          // TAB 1: PAYMENT REQUEST FORM (BP-012)
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
                          const Text('إصدار طلب سداد / تحويل مالي للمورد (Create Payment Request)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _paySelectedImportFileId,
                                  labelText: 'Import File (ملف الشحنة الاستيرادية)',
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
                                  onChanged: (v) => setState(() => _paySelectedImportFileId = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _payTitleController,
                                  decoration: const InputDecoration(labelText: 'عنوان طلب السداد *', border: OutlineInputBorder()),
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
                                flex: 1,
                                child: SearchableDropdownField<String>(
                                  value: _paymentType,
                                  labelText: 'نوع طريقة السداد *',
                                  searchHintText: 'ابحث عن طريقة السداد...',
                                  items: const [
                                    SearchableDropdownItem(value: 'Advance Payment', label: 'Advance Payment (دفعة مقدمة)'),
                                    SearchableDropdownItem(value: 'Against B/L', label: 'Against B/L (مقابل بوليصة)'),
                                    SearchableDropdownItem(value: 'Letter of Credit (L/C)', label: 'L/C (اعتماد مستندي)'),
                                    SearchableDropdownItem(value: 'Documentary Collection (CAD)', label: 'CAD (تحصيل مستندي)'),
                                    SearchableDropdownItem(value: 'Final Settlement', label: 'Final Settlement (تسوية نهائية)'),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _paymentType = val);
                                  },
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
                                    if (val != null) setState(() => _currencyCode = val);
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
                                    final d = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
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
                          const Text('بيانات التحويل البنكي للمورد (Beneficiary Supplier Bank):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _payNotesController,
                            decoration: const InputDecoration(labelText: 'ملاحظات طلب السداد الإدارية', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                              onPressed: _isSavingPayment ? null : _savePaymentRequest,
                              icon: _isSavingPayment ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white),
                              label: const Text('إصدار طلب السداد للإدارة المالية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

          // TAB 2: IMPORT BUDGET APPROVAL FORM (BP-013)
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _budgetFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Consolidated Metrics Bar
                  Row(
                    children: [
                      _buildMetricBadge('قيمة الفاتورة FOB', '$invVal EGP', Colors.blue),
                      const SizedBox(width: 10),
                      _buildMetricBadge('نولون الشحن', '$frtVal EGP', Colors.orange),
                      const SizedBox(width: 10),
                      _buildMetricBadge('الجمارك والـ VAT', '$custVal EGP', Colors.purple),
                      const SizedBox(width: 10),
                      _buildMetricBadge('التخليص والنقل الداخلي', '$clrVal EGP', Colors.teal),
                      const Spacer(),
                      _buildMetricBadge('إجمالي الميزانية المعتمدة', '$totalBgtEgp EGP', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('اعتماد ميزانية ملف الاستيراد الشاملة (Import Budget Approval Setup)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SearchableDropdownField<int?>(
                                  value: _bgtSelectedImportFileId,
                                  labelText: 'Import File (ملف الشحنة الاستيرادية)',
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
                                  onChanged: (v) => setState(() => _bgtSelectedImportFileId = v),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _invoiceEgpController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'قيمة الفاتورة المبدئية (FOB/CIF EGP) *', border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _freightEgpController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'تكلفة النولون الشحن المقدرة (EGP) *', border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _customsEgpController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'الضرائب والجمارك والـ VAT المقدرة (EGP) *', border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _clearanceEgpController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'أتعاب التخليص الجمركي والنقل الداخلي (EGP) *', border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bgtNotesController,
                            decoration: const InputDecoration(labelText: 'ملاحظات وتوجيهات اعتماد الميزانية', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                              onPressed: _isSavingBudget ? null : _saveImportBudget,
                              icon: _isSavingBudget ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified, color: Colors.white),
                              label: const Text('التصديق واعتماد الميزانية الشاملة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

          // TAB 3: FINANCIAL HISTORY REGISTRY
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'البحث بالرمز أو اسم المورد أو العنوان...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 200,
                      child: SearchableDropdownField<String>(
                        value: _statusFilter,
                        labelText: 'تصفية حسب الحالة',
                        searchHintText: 'ابحث عن الحالة...',
                        items: const [
                          SearchableDropdownItem(value: 'All', label: 'جميع الحالات'),
                          SearchableDropdownItem(value: 'Draft', label: 'Draft'),
                          SearchableDropdownItem(value: 'Approved', label: 'Approved'),
                          SearchableDropdownItem(value: 'Paid', label: 'Paid'),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _statusFilter = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: paymentsState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('❌ Error: $err')),
                    data: (payments) {
                      final filtered = payments.where((p) {
                        final matchQ = _searchQuery.isEmpty ||
                            p.paymentCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            p.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            p.title.toLowerCase().contains(_searchQuery.toLowerCase());
                        final matchS = _statusFilter == 'All' || p.status == _statusFilter;
                        return matchQ && matchS;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text('لا توجد طلبات سداد مالي مطابقة.'));
                      }

                      return SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                          columns: const [
                            DataColumn(label: Text('كود الطلب', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المورد المستفيد والعنوان', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('طريقة السداد', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المبلغ المطلوب', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('المعادل (EGP)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('التفاصيل والسداد', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filtered.map((p) {
                            return DataRow(
                              cells: [
                                DataCell(Text(p.paymentCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                DataCell(Text('${p.supplierName} - ${p.title}')),
                                DataCell(Text(p.paymentType)),
                                DataCell(Text('${p.requestedAmount} ${p.currencyCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                                DataCell(Text('${p.requestedAmountEgp} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                DataCell(_buildStatusBadge(p.status)),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: AppTheme.cobalt),
                                    onPressed: () => _showPaymentDetailsDialog(p),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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
