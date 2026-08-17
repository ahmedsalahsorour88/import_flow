import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_details_dialog.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/import_documentation_model.dart';
import '../providers/import_documentation_provider.dart';

class BankForm4Screen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;

  const BankForm4Screen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
  });

  @override
  ConsumerState<BankForm4Screen> createState() => _BankForm4ScreenState();
}

class _BankForm4ScreenState extends ConsumerState<BankForm4Screen> {
  // Active Vertical Sub-Tab:
  // 0: 📝 طلب وتوثيق نموذج 4 (Form 4 Request & Checklist)
  // 1: 📋 سجل النماذج البنكية والتوثيق (Bank Form 4 Registry)
  int _selectedSubTab = 0;

  // Form 4 State (BP-015)
  final _bankFormKey = GlobalKey<FormState>();
  int? _editingBankDocId;
  String? _editingBankDocCode;
  int? _form4ImportFileId;
  final TextEditingController _bankAmountController = TextEditingController(text: '62300.0');
  String _bankDocType = 'Form 4';
  String _form4Currency = 'USD';
  int? _selectedBankId;
  String _bankName = 'National Bank of Egypt (NBE)';
  final TextEditingController _form4RequestDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final TextEditingController _form4NotesCtrl = TextEditingController();

  String _form4SearchQuery = '';
  bool _isSavingForm4 = false;

  final Map<String, bool> _form4DocsChecklist = {
    'proforma_invoice': true,
    'packing_list': true,
    'certificate_of_origin': true,
    'bill_of_lading': true,
    'acid_notice': true,
    'marine_insurance': false,
    'bank_application': true,
    'admin_fee_receipt': false,
  };

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _form4ImportFileId = widget.initialImportFileId;
    Future.microtask(() {
      _refreshData();
    });
  }

  void _refreshData() {
    ref.read(partnersProvider.notifier).fetchPartners();
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(bankingDocumentsProvider.notifier).fetchBankingDocuments();
    ref.read(currenciesProvider.notifier).fetchCurrencies();
  }

  @override
  void dispose() {
    _bankAmountController.dispose();
    _form4RequestDateCtrl.dispose();
    _form4NotesCtrl.dispose();
    super.dispose();
  }

  void _loadForm4ForEdit(BankingDocumentModel doc) {
    setState(() {
      _editingBankDocId = doc.bankDocId;
      _editingBankDocCode = doc.bankDocCode;
      _form4ImportFileId = doc.importFileId;
      _bankDocType = doc.docType;
      _selectedBankId = doc.bankId;
      _bankName = doc.bankName;
      _bankAmountController.text = doc.amount.toStringAsFixed(2);
      _form4Currency = doc.currencyCode.toUpperCase();
      _form4RequestDateCtrl.text = doc.requestDate ?? doc.issueDate;
      _form4NotesCtrl.text = doc.notes ?? '';
      _selectedSubTab = 0; // Switch to Request Tab
    });
  }

  void _resetForm4Form() {
    setState(() {
      _editingBankDocId = null;
      _editingBankDocCode = null;
      _form4ImportFileId = null;
      _bankDocType = 'Form 4';
      _selectedBankId = null;
      _bankName = 'National Bank of Egypt (NBE)';
      _bankAmountController.clear();
      _form4Currency = 'USD';
      _form4RequestDateCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
      _form4NotesCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bankingDocs = ref.watch(bankingDocumentsProvider).value ?? [];

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.note_add_outlined,
        titleEn: 'Form 4 Request & Checklist',
        titleAr: 'طلب وتوثيق نموذج 4',
      ),
      VerticalNavTabItem(
        icon: Icons.history_edu_outlined,
        titleEn: 'Bank Form 4 Registry',
        titleAr: 'سجل النماذج البنكية',
        badge: bankingDocs.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${bankingDocs.length}',
                  style: const TextStyle(color: AppTheme.cobalt, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: 'Bank Form 4 & Financial Endorsement',
      titleAr: 'المستندات والتوثيق البنكي ونموذج 4',
      headerIcon: Icons.account_balance_outlined,
      headerColor: AppTheme.cobalt,
      tabs: tabs,
      selectedIndex: _selectedSubTab,
      onTabSelected: (index) {
        setState(() => _selectedSubTab = index);
        if (index == 1) {
          ref.read(bankingDocumentsProvider.notifier).fetchBankingDocuments();
        }
      },
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'تحديث البيانات (Refresh)',
          onPressed: _refreshData,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _selectedSubTab == 0 ? _buildForm4RequestTab() : _buildForm4HistoryRegistryTab(),
      ),
    );
  }

  // --- SUB-VIEW 0: REQUEST TAB ---
  Widget _buildForm4RequestTab() {
    final partnersState = ref.watch(partnersProvider);
    final banksList = (partnersState.value ?? []).where((p) => p.partnerType.contains('Bank') || p.partnerType.contains('بنك')).toList();
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final currencies = ref.watch(currenciesProvider).value ?? [];

    return Form(
      key: _bankFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edit Banner
          if (_editingBankDocId != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.amber, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أنت الآن في وضع تعديل النموذج البنكي المرجعي: $_editingBankDocCode',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetForm4Form,
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('إلغاء التعديل والعودة لطلب جديد'),
                  ),
                ],
              ),
            ),

          // File Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SearchableDropdownField<int>(
              labelText: 'اختر ملف الشحنة المرتبط بإصدار نموذج 4 (Select Import File)',
              hintText: 'ابحث برقم الملف أو اسم المورد أو الشركة...',
              value: _form4ImportFileId,
              isRequired: true,
              items: importFiles.map((f) => SearchableDropdownItem<int>(
                value: f.importFileId,
                label: '${f.importFileCode} — ${f.supplierName} (${f.companyName})',
              )).toList(),
              onChanged: (val) {
                setState(() => _form4ImportFileId = val);
                if (val != null) {
                  final file = importFiles.where((f) => f.importFileId == val).firstOrNull;
                  if (file != null && file.estimatedCost > 0) {
                    _bankAmountController.text = file.estimatedCost.toStringAsFixed(2);
                    _form4Currency = file.estimatedCostCurrency.isNotEmpty ? file.estimatedCostCurrency : 'USD';
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 20),

          // Main Form Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تفاصيل طلب التوثيق والتحويل البنكي (Bank Application & Endorsement Details):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SearchableDropdownField<int>(
                        labelText: 'البنك المصدر / المعتمد (Issuing Bank)',
                        hintText: 'اختر البنك...',
                        value: _selectedBankId,
                        isRequired: true,
                        items: banksList.map((b) => SearchableDropdownItem<int>(
                          value: b.providerId ?? 0,
                          label: '${b.partnerName} (${b.partnerCode})',
                        )).toList(),
                        onChanged: (val) {
                          setState(() => _selectedBankId = val);
                          final b = banksList.where((p) => p.providerId == val).firstOrNull;
                          if (b != null) _bankName = b.partnerName;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _bankAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'المبلغ المطلوب توثيقه (Amount) *',
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: _form4Currency,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SearchableDropdownField<String>(
                        labelText: 'عملة التحويل (Currency)',
                        hintText: 'اختر العملة...',
                        value: _form4Currency,
                        isRequired: true,
                        items: (currencies.isNotEmpty ? currencies.map((c) => c.currencyCode).toSet() : ['USD', 'EUR', 'GBP', 'CNY', 'SAR', 'AED', 'EGP'])
                            .map((code) => SearchableDropdownItem<String>(
                                  value: code,
                                  label: code,
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _form4Currency = val ?? 'USD'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _form4RequestDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ تقديم الطلب للبنك (Request Date) *',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _form4NotesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات وتوجيهات خاصة لفرع البنك',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Documents Checklist
                const Text(
                  'قائمة المستندات المرفقة بملف نموذج 4 للبنك (Required Attachments Checklist):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildChecklistItem('proforma_invoice', 'الفاتورة المبدئية المعتمدة (PI)', true),
                    _buildChecklistItem('packing_list', 'قائمة التعبئة والتغليف (P/L)', true),
                    _buildChecklistItem('certificate_of_origin', 'شهادة المنشأ الموثقة (COO)', true),
                    _buildChecklistItem('bill_of_lading', 'بوليصة الشحن (B/L Draft)', true),
                    _buildChecklistItem('acid_notice', 'إشعار تسجيل نافذة (ACID Notice)', true),
                    _buildChecklistItem('marine_insurance', 'وثيقة التأمين البحري (Insurance)', false),
                    _buildChecklistItem('bank_application', 'طلب تحويل البنك موقع ومختوم', true),
                    _buildChecklistItem('admin_fee_receipt', 'إيصال سداد المصاريف الإدارية', false),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSavingForm4 ? null : _saveBankingDoc,
                      icon: _isSavingForm4
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(
                        _isSavingForm4 ? 'جارٍ الحفظ...' : _editingBankDocId != null ? 'تحديث نموذج 4' : 'حفظ وتسجيل طلب نموذج 4',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                      onPressed: () => setState(() => _selectedSubTab = 1),
                      icon: const Icon(Icons.history_edu),
                      label: const Text('الانتقال لسجل النماذج البنكية'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String key, String title, bool isRequired) {
    final isChecked = _form4DocsChecklist[key] ?? false;
    return InkWell(
      onTap: () => setState(() => _form4DocsChecklist[key] = !isChecked),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isChecked ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isChecked ? AppTheme.cobalt : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: isChecked ? AppTheme.cobalt : Colors.grey),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 12.5, fontWeight: isChecked ? FontWeight.bold : FontWeight.normal)),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  // --- SUB-VIEW 1: REGISTRY TAB ---
  Widget _buildForm4HistoryRegistryTab() {
    final bankingDocs = ref.watch(bankingDocumentsProvider).value ?? [];
    final filtered = bankingDocs.where((d) {
      final matchesSearch = _form4SearchQuery.isEmpty ||
          d.bankDocCode.toLowerCase().contains(_form4SearchQuery.toLowerCase()) ||
          d.bankName.toLowerCase().contains(_form4SearchQuery.toLowerCase()) ||
          (d.importFileCode != null && d.importFileCode!.toLowerCase().contains(_form4SearchQuery.toLowerCase()));
      return matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'بحث في سجل النماذج البنكية بالرمز، البنك، رقم الملف...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) => setState(() => _form4SearchQuery = val),
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cobalt,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onPressed: () {
                _resetForm4Form();
                setState(() => _selectedSubTab = 0);
              },
              icon: const Icon(Icons.add),
              label: const Text('طلب نموذج 4 جديد'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Registry Table
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text('كود المستند', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('رقم الملف', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('البنك المعتمد', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('المبلغ والعملة', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('تاريخ التقديم', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('حالة التوثيق', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
              ],

            rows: filtered.map((d) {
              return DataRow(
                cells: [
                  DataCell(Text(d.bankDocCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                  DataCell(Text(d.importFileCode ?? '-')),
                  DataCell(Text(d.bankName)),
                  DataCell(Text('${d.amount.toStringAsFixed(2)} ${d.currencyCode}')),
                  DataCell(Text(d.requestDate ?? d.issueDate.substring(0, min(10, d.issueDate.length)))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: d.status == 'Received' ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: d.status == 'Received' ? Colors.green.shade300 : Colors.amber.shade300),
                      ),
                      child: Text(
                        d.status == 'Received' ? 'معتمد وموثق' : 'قيد المعالجة البنكية',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: d.status == 'Received' ? Colors.green.shade800 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 18),
                      tooltip: 'تعديل أو استعراض',
                      onPressed: () => _loadForm4ForEdit(d),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ],
  );

  }

  Future<void> _saveBankingDoc() async {
    if (!_bankFormKey.currentState!.validate()) return;
    if (_form4ImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isSavingForm4 = true);
    try {
      final payload = {
        'import_file_id': _form4ImportFileId,
        'doc_type': _bankDocType,
        'bank_id': _selectedBankId,
        'bank_name': _bankName,
        'amount': double.tryParse(_bankAmountController.text) ?? 0.0,
        'currency_code': _form4Currency,
        'request_date': _form4RequestDateCtrl.text.trim(),
        'notes': _form4NotesCtrl.text.trim(),
      };

      if (_editingBankDocId != null) {
        await ref.read(bankingDocumentsProvider.notifier).updateBankingDocument(_editingBankDocId!, payload);
      } else {
        await ref.read(bankingDocumentsProvider.notifier).createBankingDocument(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ نموذج 4 البنكي بنجاح'), backgroundColor: AppTheme.emerald),
        );
        _resetForm4Form();
        setState(() => _selectedSubTab = 1);
      }
    } catch (e) {
      if (mounted) {
        showErrorDetailsDialog(context, title: 'خطأ في حفظ نموذج 4', error: e);
      }
    } finally {
      if (mounted) setState(() => _isSavingForm4 = false);
    }
  }
}
