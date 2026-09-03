import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';

class SmartInvoiceBLExtractorDialog extends ConsumerStatefulWidget {
  final int? initialImportFileId;
  final int initialTabIndex;

  const SmartInvoiceBLExtractorDialog({
    super.key,
    this.initialImportFileId,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<SmartInvoiceBLExtractorDialog> createState() =>
      _SmartInvoiceBLExtractorDialogState();
}

class _SmartInvoiceBLExtractorDialogState
    extends ConsumerState<SmartInvoiceBLExtractorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // Tab 1: Invoice state
  final TextEditingController _invoiceTextCtrl = TextEditingController();
  PlatformFile? _pickedInvoiceFile;
  bool _isExtractingInvoice = false;
  bool _isApplyingInvoice = false;
  Map<String, dynamic>? _extractedInvoice;
  List<dynamic> _invoiceItems = [];
  int? _selectedImportFileId;

  // Tab 2: B/L state
  final TextEditingController _blTextCtrl = TextEditingController();
  PlatformFile? _pickedBLFile;
  bool _isExtractingBL = false;
  bool _isApplyingBL = false;
  Map<String, dynamic>? _extractedBL;
  List<dynamic> _blContainers = [];

  // Tab 3: Cross-Check state
  bool _isAuditing = false;
  Map<String, dynamic>? _auditResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _selectedImportFileId = widget.initialImportFileId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invoiceTextCtrl.dispose();
    _blTextCtrl.dispose();
    super.dispose();
  }

  // ─── Pick Files ────────────────────────────────────────────────────────────

  Future<void> _pickInvoiceFile() async {
    try {
      final res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'xlsx', 'xls', 'docx', 'doc', 'txt'],
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        setState(() {
          _pickedInvoiceFile = res.files.first;
        });
      }
    } catch (e) {
      _showSnackBar('فشل اختيار الملف: $e', isError: true);
    }
  }

  Future<void> _pickBLFile() async {
    try {
      final res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'xlsx', 'xls', 'docx', 'doc', 'txt'],
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        setState(() {
          _pickedBLFile = res.files.first;
        });
      }
    } catch (e) {
      _showSnackBar('فشل اختيار الملف: $e', isError: true);
    }
  }

  // ─── Extract Actions ───────────────────────────────────────────────────────

  Future<void> _extractInvoice() async {
    final text = _invoiceTextCtrl.text.trim();
    if (text.isEmpty && _pickedInvoiceFile == null) {
      _showSnackBar('يرجى اختيار ملف الفاتورة أو لصق نصها أولاً', isError: true);
      return;
    }

    setState(() => _isExtractingInvoice = true);
    try {
      final url = '${ApiConstants.smartDocumentUpload}/extract/commercial-invoice';
      Response resp;
      if (_pickedInvoiceFile != null && _pickedInvoiceFile!.bytes != null) {
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            _pickedInvoiceFile!.bytes!,
            filename: _pickedInvoiceFile!.name,
          ),
          if (text.isNotEmpty) 'raw_text': text,
        });
        resp = await _dio.post(url, data: formData);
      } else {
        final formData = FormData.fromMap({'raw_text': text});
        resp = await _dio.post(url, data: formData);
      }

      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data as Map<String, dynamic>;
        setState(() {
          _extractedInvoice = data['extracted_fields'] as Map<String, dynamic>?;
          _invoiceItems = (data['items'] as List<dynamic>?) ?? [];
        });
        _showSnackBar('تم استخلاص بيانات الفاتورة بنجاح بنسبة دقة عالية ✅');
      }
    } catch (e) {
      _showSnackBar('خطأ أثناء استخلاص الفاتورة: $e', isError: true);
    } finally {
      setState(() => _isExtractingInvoice = false);
    }
  }

  Future<void> _extractBL() async {
    final text = _blTextCtrl.text.trim();
    if (text.isEmpty && _pickedBLFile == null) {
      _showSnackBar('يرجى اختيار ملف البوليصة أو لصق نصها أولاً', isError: true);
      return;
    }

    setState(() => _isExtractingBL = true);
    try {
      final url = '${ApiConstants.smartDocumentUpload}/extract/bill-of-lading';
      Response resp;
      if (_pickedBLFile != null && _pickedBLFile!.bytes != null) {
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            _pickedBLFile!.bytes!,
            filename: _pickedBLFile!.name,
          ),
          if (text.isNotEmpty) 'raw_text': text,
        });
        resp = await _dio.post(url, data: formData);
      } else {
        final formData = FormData.fromMap({'raw_text': text});
        resp = await _dio.post(url, data: formData);
      }

      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data as Map<String, dynamic>;
        setState(() {
          _extractedBL = data['extracted_fields'] as Map<String, dynamic>?;
          _blContainers = (data['containers'] as List<dynamic>?) ?? [];
        });
        _showSnackBar('تم استخلاص بوليصة الشحن والحاويات بنجاح ✅');
      }
    } catch (e) {
      _showSnackBar('خطأ أثناء استخلاص البوليصة: $e', isError: true);
    } finally {
      setState(() => _isExtractingBL = false);
    }
  }

  // ─── Cross-Audit ───────────────────────────────────────────────────────────

  Future<void> _runCrossAudit() async {
    if (_extractedInvoice == null || _extractedBL == null) {
      _showSnackBar('يرجى استخلاص الفاتورة والبوليصة أولاً لإجراء المطابقة', isError: true);
      return;
    }

    setState(() => _isAuditing = true);
    try {
      final url = '${ApiConstants.smartDocumentUpload}/cross-check/invoice-vs-bl';
      final payload = {
        'invoice_data': _extractedInvoice,
        'bl_data': _extractedBL,
        'weight_tolerance_pct': 3.0,
      };
      final resp = await _dio.post(url, data: payload);
      if (resp.statusCode == 200 && resp.data != null) {
        setState(() {
          _auditResult = resp.data as Map<String, dynamic>;
        });
        _showSnackBar('تم اكتمال تدقيق المطابقة الجمركية بنجاح ✅');
      }
    } catch (e) {
      _showSnackBar('خطأ أثناء تدقيق المطابقة: $e', isError: true);
    } finally {
      setState(() => _isAuditing = false);
    }
  }

  // ─── Apply Services ────────────────────────────────────────────────────────

  Future<void> _applyInvoiceToImportFile() async {
    if (_extractedInvoice == null) return;
    if (_selectedImportFileId == null) {
      _showSnackBar('يرجى تحديد الملف الاستيرادي المستهدف أولاً', isError: true);
      return;
    }

    setState(() => _isApplyingInvoice = true);
    try {
      final url = '${ApiConstants.smartDocumentUpload}/apply/commercial-invoice';
      final resp = await _dio.post(url, data: {
        'import_file_id': _selectedImportFileId,
        'invoice_data': _extractedInvoice,
      });
      if (resp.statusCode == 200) {
        ref.invalidate(importFilesProvider);
        _showSnackBar(resp.data['message_ar'] ?? 'تم ربط بيانات الفاتورة بالملف بنجاح');
      }
    } catch (e) {
      _showSnackBar('فشل تطبيق بيانات الفاتورة: $e', isError: true);
    } finally {
      setState(() => _isApplyingInvoice = false);
    }
  }

  Future<void> _applyBLToShipping() async {
    if (_extractedBL == null) return;
    if (_selectedImportFileId == null) {
      _showSnackBar('يرجى تحديد الملف الاستيرادي المستهدف أولاً', isError: true);
      return;
    }

    setState(() => _isApplyingBL = true);
    try {
      final url = '${ApiConstants.smartDocumentUpload}/apply/bill-of-lading';
      final resp = await _dio.post(url, data: {
        'import_file_id': _selectedImportFileId,
        'bl_data': _extractedBL,
      });
      if (resp.statusCode == 200) {
        ref.invalidate(importFilesProvider);
        _showSnackBar(resp.data['message_ar'] ?? 'تم تطبيق بيانات البوليصة بنجاح');
      }
    } catch (e) {
      _showSnackBar('فشل تطبيق بيانات البوليصة: $e', isError: true);
    } finally {
      setState(() => _isApplyingBL = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? AppTheme.crimson : AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1120,
        height: 760,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTabsBar(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInvoiceTab(),
                  _buildBLTab(),
                  _buildCrossCheckTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.cobaltLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'استخلاص الفواتير وبوالص الشحن بالذكاء الاصطناعي (AI-INV-010)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'استخراج ذكي لبيانات الفواتير والبوالص البحرية والجوية مع التدقيق والمطابقة الجمركية المسبقة',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'إغلاق',
        ),
      ],
    );
  }

  Widget _buildTabsBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.charcoal,
        indicator: BoxDecoration(
          color: AppTheme.cobalt,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(
            icon: Icon(Icons.receipt_long_outlined),
            text: 'الفاتورة التجارية (Invoice)',
          ),
          Tab(
            icon: Icon(Icons.directions_boat_outlined),
            text: 'بوليصة الشحن (B/L & AWB)',
          ),
          Tab(
            icon: Icon(Icons.rule_folder_outlined),
            text: 'رادار المطابقة (10-Point Audit)',
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: Invoice Extractor ──────────────────────────────────────────────

  Widget _buildInvoiceTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputCard(
            title: '1. إدخال أو رفع الفاتورة التجارية (Commercial Invoice)',
            hint: 'الصق نص الفاتورة هنا، أو اختر ملف الفاتورة (PDF / Excel / Word)...',
            textController: _invoiceTextCtrl,
            pickedFile: _pickedInvoiceFile,
            onPickFile: _pickInvoiceFile,
            onExtract: _extractInvoice,
            isLoading: _isExtractingInvoice,
            extractButtonLabel: 'استخلاص الفاتورة بالذكاء الاصطناعي',
          ),
          const SizedBox(height: 16),
          if (_extractedInvoice != null) ...[
            _buildInvoiceSummaryCards(),
            const SizedBox(height: 16),
            _buildInvoiceItemsTable(),
            const SizedBox(height: 16),
            _buildInvoiceApplySection(),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceSummaryCards() {
    final inv = _extractedInvoice!;
    return Card(
      elevation: 0,
      color: AppTheme.cobaltLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.cobaltBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: AppTheme.cobalt, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'البيانات المستخلصة من الفاتورة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'العملة: ${inv['currency'] ?? 'USD'}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildFieldChip('رقم الفاتورة', inv['invoice_number'] ?? '-'),
                _buildFieldChip('تاريخ الفاتورة', inv['invoice_date'] ?? '-'),
                _buildFieldChip('رقم الـ ACID (19 رقماً)', inv['acid_number'] ?? '-', isHighlight: true),
                _buildFieldChip('البطاقة الضريبية للمستورد', inv['importer_tax_id'] ?? '-'),
                _buildFieldChip('المورد / الشاحن', inv['supplier_name'] ?? '-'),
                _buildFieldChip('المستورد المصري', inv['importer_name'] ?? '-'),
                _buildFieldChip('شرط التعاقد', inv['incoterms'] ?? '-'),
                _buildFieldChip('إجمالي القيمة', '${inv['invoice_value'] ?? 0} ${inv['currency'] ?? 'USD'}', isHighlight: true),
                _buildFieldChip('الوزن القائم الإجمالي', '${inv['total_gross_weight_kg'] ?? '-'} KG'),
                _buildFieldChip('ميناء الشحن والتفريغ', 'POL: ${inv['loading_port'] ?? '-'} | POD: ${inv['discharge_port'] ?? '-'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItemsTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart_outlined, color: AppTheme.charcoal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'جدول الأصناف والبنود المستخلصة (${_invoiceItems.length} صنف):',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_invoiceItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('لم يتم العثور على جدول تفصيلي للأصناف في المستند')),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                    columnSpacing: 18,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('بيان الصنف')),
                      DataColumn(label: Text('الكمية')),
                      DataColumn(label: Text('الوحدة')),
                      DataColumn(label: Text('سعر الوحدة')),
                      DataColumn(label: Text('إجمالي السعر')),
                    ],
                    rows: List.generate(_invoiceItems.length, (idx) {
                      final itm = _invoiceItems[idx] as Map<String, dynamic>;
                      return DataRow(cells: [
                        DataCell(Text('${idx + 1}')),
                        DataCell(SizedBox(
                          width: 250,
                          child: Text(itm['description'] ?? '-', overflow: TextOverflow.ellipsis),
                        )),
                        DataCell(Text('${itm['quantity'] ?? 0}')),
                        DataCell(Text(itm['unit_of_measure'] ?? 'PCS')),
                        DataCell(Text('${itm['unit_price'] ?? 0}')),
                        DataCell(Text('${itm['total_price'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ]);
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceApplySection() {
    final importFilesAsync = ref.watch(importFilesProvider);
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.link, color: AppTheme.cobalt),
            const SizedBox(width: 8),
            const Text('ربط وتطبيق في ملف استيرادي:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Expanded(
              child: importFilesAsync.when(
                data: (files) {
                  return SearchableDropdownField<int>(
                    labelText: 'اختر الملف الاستيرادي',
                    hintText: 'ابحث برقم الملف أو الشركة...',
                    items: files
                        .map((f) => SearchableDropdownItem<int>(
                              value: f.importFileId,
                              label: '${f.importFileCode} - ${f.companyName}',
                            ))
                        .toList(),
                    value: _selectedImportFileId,
                    onChanged: (val) => setState(() => _selectedImportFileId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('خطأ في جلب الملفات: $e'),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _isApplyingInvoice ? null : _applyInvoiceToImportFile,
              icon: _isApplyingInvoice
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: const Text('تطبيق في ملف الاستيراد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: B/L & AWB Extractor ───────────────────────────────────────────

  Widget _buildBLTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputCard(
            title: '2. إدخال أو رفع بوليصة الشحن (Bill of Lading / Air Waybill)',
            hint: 'الصق نص البوليصة هنا، أو اختر ملف البوليصة (PDF / Word / Text)...',
            textController: _blTextCtrl,
            pickedFile: _pickedBLFile,
            onPickFile: _pickBLFile,
            onExtract: _extractBL,
            isLoading: _isExtractingBL,
            extractButtonLabel: 'استخلاص بوليصة الشحن والحاويات',
          ),
          const SizedBox(height: 16),
          if (_extractedBL != null) ...[
            _buildBLSummaryCards(),
            const SizedBox(height: 16),
            _buildBLContainersTable(),
            const SizedBox(height: 16),
            _buildBLApplySection(),
          ],
        ],
      ),
    );
  }

  Widget _buildBLSummaryCards() {
    final bl = _extractedBL!;
    final isAir = bl['bl_type'] == 'AIR_WAYBILL';
    return Card(
      elevation: 0,
      color: isAir ? AppTheme.orangeLight : AppTheme.emeraldLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isAir ? AppTheme.orange : AppTheme.emeraldBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isAir ? Icons.airplanemode_active : Icons.directions_boat,
                    color: isAir ? AppTheme.orange : AppTheme.emerald, size: 22),
                const SizedBox(width: 8),
                Text(
                  isAir ? 'بوليصة شحن جوي (Air Waybill - AWB)' : 'بوليصة شحن بحري (Ocean Bill of Lading)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bl['freight_payment_term'] == 'FREIGHT_PREPAID' ? AppTheme.cobalt : AppTheme.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bl['freight_payment_term'] ?? 'FREIGHT_COLLECT',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildFieldChip('رقم البوليصة', bl['bl_number'] ?? '-', isHighlight: true),
                _buildFieldChip('رقم الـ ACID الجمركي', bl['acid_number'] ?? '-', isHighlight: true),
                _buildFieldChip('الخط الملاحي / الناقل', bl['carrier_name'] ?? '-'),
                _buildFieldChip(isAir ? 'رقم الرحلة الجوية' : 'السفينة والرحلة',
                    isAir ? (bl['flight_number'] ?? '-') : '${bl['vessel_name'] ?? '-'} / ${bl['voyage_number'] ?? '-'}'),
                _buildFieldChip('ميناء الشحن (POL)', bl['loading_port'] ?? '-'),
                _buildFieldChip('ميناء التفريغ (POD)', bl['discharge_port'] ?? '-'),
                _buildFieldChip('إجمالي الوزن القائم', '${bl['total_gross_weight_kg'] ?? '-'} KG', isHighlight: true),
                _buildFieldChip('الحجم الكلي (CBM)', '${bl['total_cbm'] ?? '-'} CBM'),
                _buildFieldChip('عدد الطرود', '${bl['total_packages_count'] ?? '-'} (${bl['package_type'] ?? 'Pkgs'})'),
                _buildFieldChip('الشاحن (Shipper)', bl['shipper'] ?? '-'),
                _buildFieldChip('المرسل إليه (Consignee)', bl['consignee'] ?? '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBLContainersTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.view_in_ar_outlined, color: AppTheme.charcoal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'قائمة الحاويات والأختام المستخلصة (${_blContainers.length} حاوية):',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_blContainers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('لا توجد حاويات محددة أو أن الشحنة شحن جوي / طرود LCL')),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('رقم الحاوية (Container No)')),
                      DataColumn(label: Text('رقم السيل (Seal No)')),
                      DataColumn(label: Text('النوع والمقاس')),
                      DataColumn(label: Text('الوزن القائم (KG)')),
                    ],
                    rows: List.generate(_blContainers.length, (idx) {
                      final c = _blContainers[idx] as Map<String, dynamic>;
                      return DataRow(cells: [
                        DataCell(Text('${idx + 1}')),
                        DataCell(Text(c['container_no'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(c['seal_no'] ?? '-')),
                        DataCell(Text(c['container_type'] ?? '40HC')),
                        DataCell(Text('${c['gross_weight_kg'] ?? '-'}')),
                      ]);
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBLApplySection() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.directions_boat, color: AppTheme.emerald),
            const SizedBox(width: 8),
            const Text('تطبيق البوليصة في تتبع الشحن والحاويات:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isApplyingBL ? null : _applyBLToShipping,
              icon: _isApplyingBL
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_alt),
              label: const Text('تطبيق في حركة الشحن الحالية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cobalt,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3: Cross-Check Audit Radar ────────────────────────────────────────

  Widget _buildCrossCheckTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            color: AppTheme.orangeLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.orange),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.security, color: AppTheme.orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'رادار التدقيق الجمركي المتقاطع (10-Point Pre-Clearance Audit)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                        ),
                        Text(
                          'يقوم بمقارنة الفاتورة مع البوليصة للتحقق من تطابق رقم الـ ACID وانحراف الأوزان وشروط النولون والموانئ تفادياً لغرامات نافذة.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isAuditing ? null : _runCrossAudit,
                    icon: _isAuditing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.play_arrow),
                    label: const Text('تشغيل الفحص الآن'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_auditResult != null) ...[
            _buildAuditScorecard(),
            const SizedBox(height: 16),
            _buildAuditMatrixTable(),
            const SizedBox(height: 16),
            _buildCorrectionNoticeCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditScorecard() {
    final res = _auditResult!;
    final score = (res['compliance_score'] as num?)?.toDouble() ?? 0.0;
    final verdict = res['verdict'] as String? ?? 'COMPLIANT';
    final verdictAr = res['verdict_ar'] as String? ?? '';
    final criticals = (res['critical_errors'] as List<dynamic>?) ?? [];
    final warnings = (res['warnings'] as List<dynamic>?) ?? [];

    Color badgeColor = AppTheme.emerald;
    if (verdict == 'CRITICAL_MISMATCH') {
      badgeColor = AppTheme.crimson;
    } else if (verdict == 'WARNINGS_DETECTED') {
      badgeColor = AppTheme.orange;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: badgeColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'نسبة التطابق: $score%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    verdictAr,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: badgeColor),
                  ),
                ),
              ],
            ),
            if (criticals.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.crimsonLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: criticals
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.cancel, color: AppTheme.crimson, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(c.toString(), style: const TextStyle(fontSize: 12, color: AppTheme.crimson))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.orangeLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: warnings
                      .map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(w.toString(), style: const TextStyle(fontSize: 12, color: AppTheme.charcoal))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuditMatrixTable() {
    final matrix = (_auditResult!['audit_matrix'] as List<dynamic>?) ?? [];
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مصفوفة الفحص والتدقيق المتقاطع (10 نقاط):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columnSpacing: 14,
                  columns: const [
                    DataColumn(label: Text('بند الفحص')),
                    DataColumn(label: Text('القيمة بالفاتورة')),
                    DataColumn(label: Text('القيمة بالبوليصة')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('التفاصيل والتوجيه')),
                  ],
                  rows: matrix.map((m) {
                    final item = m as Map<String, dynamic>;
                    final status = item['status'] ?? 'PASS';
                    Color statusColor = AppTheme.emerald;
                    IconData statusIcon = Icons.check_circle;
                    if (status == 'CRITICAL') {
                      statusColor = AppTheme.crimson;
                      statusIcon = Icons.cancel;
                    } else if (status == 'WARNING') {
                      statusColor = AppTheme.orange;
                      statusIcon = Icons.warning;
                    }

                    return DataRow(cells: [
                      DataCell(Text(item['title_ar'] ?? item['check_code'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(item['invoice_value'] ?? '-')),
                      DataCell(Text(item['bl_value'] ?? '-')),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 16),
                          const SizedBox(width: 4),
                          Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      )),
                      DataCell(SizedBox(
                        width: 280,
                        child: Text(item['details_ar'] ?? '-', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionNoticeCard() {
    final noticeEn = _auditResult!['correction_notice_en'] as String? ?? '';
    final noticeAr = _auditResult!['correction_notice_ar'] as String? ?? '';

    return Card(
      elevation: 0,
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueGrey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.mark_email_read_outlined, color: AppTheme.charcoal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'خطاب التعديل الرسمي للخط الملاحي والمورد (B/L Amendment Notice)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'صيغة جاهزة بالإنجليزية والعربية لمطالبة الخط الملاحي بتعديل مسودة البوليصة فوراً.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: noticeEn));
                _showSnackBar('تم نسخ صيغة الخطاب بالإنجليزية إلى الحافظة ✅');
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('نسخ بالإنجليزية (EN)'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: noticeAr));
                _showSnackBar('تم نسخ صيغة الخطاب بالعربية إلى الحافظة ✅');
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('نسخ بالعربية (AR)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.charcoal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared Components ─────────────────────────────────────────────────────

  Widget _buildInputCard({
    required String title,
    required String hint,
    required TextEditingController textController,
    required PlatformFile? pickedFile,
    required VoidCallback onPickFile,
    required VoidCallback onExtract,
    required bool isLoading,
    required String extractButtonLabel,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onPickFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(pickedFile != null ? pickedFile.name : 'اختيار ملف (PDF / Excel / Word)'),
                ),
                if (pickedFile != null) ...[
                  IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.crimson, size: 20),
                    onPressed: () => setState(() => pickedFile = null),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onExtract,
                  icon: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(extractButtonLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldChip(String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.amber.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isHighlight ? Colors.amber.shade400 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: AppTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}
