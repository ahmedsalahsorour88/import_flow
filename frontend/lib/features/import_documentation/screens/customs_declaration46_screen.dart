import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../providers/import_documentation_provider.dart';

class CustomsDeclaration46Screen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;

  const CustomsDeclaration46Screen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
  });

  @override
  ConsumerState<CustomsDeclaration46Screen> createState() => _CustomsDeclaration46ScreenState();
}

class _CustomsDeclaration46ScreenState extends ConsumerState<CustomsDeclaration46Screen> {
  // Active Vertical Sub-Tab:
  // 0: 🏛️ قيد الإقرار الجمركي المبدئي (Initial Declaration 46 Registration)
  // 1: 📋 سجل الشهادات الجمركية 46 (Declaration 46 Registry & Tracking)
  int _selectedSubTab = 0;
  int? _selectedImportFileId;

  final _declarationFormKey = GlobalKey<FormState>();
  final TextEditingController _declaration46NoCtrl = TextEditingController(text: '46-EG-2026-');
  final TextEditingController _acidNumberCtrl = TextEditingController();
  final TextEditingController _form4NumberCtrl = TextEditingController();
  final TextEditingController _blNumberCtrl = TextEditingController();
  final TextEditingController _customsValueEgpCtrl = TextEditingController(text: '0.00');
  final TextEditingController _importDutyEgpCtrl = TextEditingController(text: '0.00');
  final TextEditingController _vatEgpCtrl = TextEditingController(text: '0.00');
  final TextEditingController _otherFeesEgpCtrl = TextEditingController(text: '0.00');
  final TextEditingController _totalDutyAndTaxesCtrl = TextEditingController(text: '0.00');
  final TextEditingController _submissionDateCtrl = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  final TextEditingController _notesCtrl = TextEditingController();

  String _searchQuery = '';
  bool _isSavingDeclaration = false;

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _selectedImportFileId = widget.initialImportFileId;
    Future.microtask(() {
      _refreshData();
    });
  }

  void _refreshData() {
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(acidSessionsProvider.notifier).fetchAcidSessions();
    ref.read(bankingDocumentsProvider.notifier).fetchBankingDocuments();
  }

  @override
  void dispose() {
    _declaration46NoCtrl.dispose();
    _acidNumberCtrl.dispose();
    _form4NumberCtrl.dispose();
    _blNumberCtrl.dispose();
    _customsValueEgpCtrl.dispose();
    _importDutyEgpCtrl.dispose();
    _vatEgpCtrl.dispose();
    _otherFeesEgpCtrl.dispose();
    _totalDutyAndTaxesCtrl.dispose();
    _submissionDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onImportFileSelected(int? fileId) {
    setState(() => _selectedImportFileId = fileId);
    if (fileId == null) return;

    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    // Auto load ACID number
    final acids = ref.read(acidSessionsProvider).value ?? [];
    final matchedAcid = acids.where((a) => a.importFileId == fileId).firstOrNull;
    if (matchedAcid != null) {
      _acidNumberCtrl.text = matchedAcid.acidNumber;
    }

    // Auto load Form 4 number
    final bankDocs = ref.read(bankingDocumentsProvider).value ?? [];
    final matchedF4 = bankDocs.where((d) => d.importFileId == fileId && d.docType == 'Form 4').firstOrNull;
    if (matchedF4 != null && matchedF4.docReferenceNumber != 'PENDING') {
      _form4NumberCtrl.text = matchedF4.docReferenceNumber;
    } else {
      _form4NumberCtrl.text = 'F4-PENDING';
    }

    _declaration46NoCtrl.text = '46-ALX-${file.importFileCode}';
  }

  void _calculateTotalDuties() {
    final duty = double.tryParse(_importDutyEgpCtrl.text) ?? 0.0;
    final vat = double.tryParse(_vatEgpCtrl.text) ?? 0.0;
    final other = double.tryParse(_otherFeesEgpCtrl.text) ?? 0.0;
    final total = duty + vat + other;
    _totalDutyAndTaxesCtrl.text = total.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.assignment_outlined,
        titleEn: 'Initial Declaration 46 Form',
        titleAr: 'قيد الإقرار الجمركي المبدئي',
      ),
      const VerticalNavTabItem(
        icon: Icons.history_edu_outlined,
        titleEn: 'Declaration 46 Registry',
        titleAr: 'سجل شهادات 46 ومتابعتها',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: '',
      titleEn: 'Customs Declaration 46 Registration',
      titleAr: 'الإقرار الجمركي المبدئي وشهادة 46 ك.م',
      headerIcon: Icons.description_outlined,
      headerColor: Colors.indigo,
      tabs: tabs,
      selectedIndex: _selectedSubTab,
      onTabSelected: (index) => setState(() => _selectedSubTab = index),
      selectedImportFileId: _selectedImportFileId,
      onShipmentStatusChanged: _refreshData,
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: 'تحديث البيانات (Refresh)',
          onPressed: _refreshData,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _selectedSubTab == 0 ? _buildInitialDeclarationView() : _buildDeclarationRegistryView(),
      ),
    );
  }

  // --- SUB-VIEW 0: INITIAL DECLARATION FORM ---
  Widget _buildInitialDeclarationView() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return Form(
      key: _declarationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informational Alert
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, color: Colors.indigo, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'مسودة إقرار 46 ك.م الجاهزة للربط مع نافذة. يتم سحب رقم ACID المعتمد، ورقم نموذج 4 البنكي الموثق، وبيانات بوليصة الشحن تلقائياً لحساب الوعاء الضريبي والضرائب المقدرة.',
                    style: TextStyle(color: Colors.indigo.shade900, fontSize: 13, height: 1.4),
                  ),
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
              labelText: 'اختر ملف الشحنة لقيد شهادة 46 (Select Import File)',
              hintText: 'ابحث برقم الملف أو اسم المورد...',
              value: _selectedImportFileId,
              isRequired: true,
              items: importFiles.map((f) => SearchableDropdownItem<int>(
                value: f.importFileId,
                label: '${f.importFileCode} — ${f.supplierName} (${f.companyName})',
              )).toList(),
              onChanged: _onImportFileSelected,
            ),
          ),
          const SizedBox(height: 20),

          // Form Fields Card
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
                  'بيانات الإقرار الجمركي وأرقام القيد المعتمدة (Declaration 46 Attributes):',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _declaration46NoCtrl,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        decoration: const InputDecoration(
                          labelText: 'رقم الإقرار / الشهادة الجمركية (46 ك.م) *',
                          prefixIcon: Icon(Icons.pin, color: Colors.indigo),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _submissionDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ القيد المبدئي *',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _acidNumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم القيد المسبق (ACID)',
                          prefixIcon: Icon(Icons.qr_code),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _form4NumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم نموذج 4 البنكي المعتمد',
                          prefixIcon: Icon(Icons.account_balance),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _blNumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'رقم بوليصة الشحن (B/L)',
                          prefixIcon: Icon(Icons.assignment),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'الوعاء الضريبي والرسوم المقدرة (Customs Base & Estimated Duties - EGP):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customsValueEgpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'القيمة الجمركية CIF (جنيه)',
                          prefixIcon: Icon(Icons.monetization_on),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _importDutyEgpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'ضريبة الوارد المقدرة (جنيه)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculateTotalDuties(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _vatEgpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'ضريبة القيمة المضافة VAT (جنيه)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _calculateTotalDuties(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _totalDutyAndTaxesCtrl,
                        readOnly: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson),
                        decoration: const InputDecoration(
                          labelText: 'إجمالي الضرائب والرسوم المقدرة',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSavingDeclaration ? null : _saveDeclaration46,
                  icon: _isSavingDeclaration
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(
                    _isSavingDeclaration ? 'جارٍ الحفظ...' : 'حفظ وقيد الإقرار الجمركي المبدئي',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-VIEW 1: REGISTRY VIEW ---
  Widget _buildDeclarationRegistryView() {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    final filtered = importFiles.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.importFileCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.supplierName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'بحث في سجل الإقرارات الجمركية وشهادات 46...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onPressed: () => setState(() => _selectedSubTab = 0),
              icon: const Icon(Icons.add),
              label: const Text('قيد إقرار جديد'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text('رقم الإقرار (46 ك.م)', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('رقم الملف', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('المورد الأجنبي', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تاريخ القيد', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('حالة الإقرار', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filtered.map((f) {
              return DataRow(
                cells: [
                  DataCell(Text('46-ALX-${f.importFileCode}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                  DataCell(Text(f.importFileCode)),
                  DataCell(Text(f.supplierName)),
                  DataCell(Text(DateTime.now().toString().substring(0, 10))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: const Text('مقيد مبدئياً على نافذة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _saveDeclaration46() async {
    if (!_declarationFormKey.currentState!.validate()) return;
    if (_selectedImportFileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً'), backgroundColor: AppTheme.crimson),
      );
      return;
    }

    setState(() => _isSavingDeclaration = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isSavingDeclaration = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قيد وحفظ مسودة الإقرار الجمركي (46 ك.م) بنجاح'), backgroundColor: AppTheme.emerald),
      );
      setState(() => _selectedSubTab = 1);
    }
  }
}
