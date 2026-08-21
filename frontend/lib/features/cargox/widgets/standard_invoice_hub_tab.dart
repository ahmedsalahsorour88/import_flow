import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/cargox_model.dart';
import '../providers/cargox_provider.dart';

String _formatDateTime(DateTime dt) {
  final str = dt.toIso8601String();
  if (str.length >= 16) {
    return str.substring(0, 16).replaceAll('T', ' ');
  }
  return str;
}

class StandardInvoiceHubTab extends ConsumerStatefulWidget {
  final int? initialImportFileId;

  const StandardInvoiceHubTab({super.key, this.initialImportFileId});

  @override
  ConsumerState<StandardInvoiceHubTab> createState() => _StandardInvoiceHubTabState();
}

class _StandardInvoiceHubTabState extends ConsumerState<StandardInvoiceHubTab> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _subTabController;

  ImportFileModel? _selectedImportFile;
  StandardInvoiceSessionModel? _existingSession;
  StandardInvoicePayloadModel? _supplierData;
  StandardInvoiceComparisonResponseModel? _comparisonResult;

  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isParsing = false;
  bool _isSaving = false;

  String _selectedStatus = 'UNDER_REVIEW';
  final TextEditingController _overrideReasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(standardInvoiceSessionsProvider.notifier).fetchSessions();
      if (widget.initialImportFileId != null) {
        _loadInitialFile(widget.initialImportFileId!);
      }
    });
  }

  @override
  void dispose() {
    _subTabController.dispose();
    _overrideReasonController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialFile(int fileId) async {
    final filesAsync = ref.read(importFilesProvider);
    filesAsync.whenData((files) {
      final match = files.where((f) => f.importFileId == fileId).firstOrNull;
      if (match != null) {
        _onSelectImportFile(match);
      }
    });
  }

  Future<void> _onSelectImportFile(ImportFileModel file) async {
    setState(() {
      _selectedImportFile = file;
      _existingSession = null;
      _supplierData = null;
      _comparisonResult = null;
      _overrideReasonController.clear();
      _notesController.clear();
      _isLoading = true;
    });

    try {
      final notifier = ref.read(standardInvoiceSessionsProvider.notifier);
      final session = await notifier.fetchSessionByFile(file.importFileId);
      if (mounted) {
        setState(() {
          _existingSession = session;
          if (session != null) {
            _selectedStatus = session.status;
            _overrideReasonController.text = session.discrepancyOverrideReason ?? '';
            _notesController.text = session.notes ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDownloadTemplate() async {
    if (_selectedImportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final notifier = ref.read(standardInvoiceSessionsProvider.notifier);
      final bytes = await notifier.downloadExcelTemplate(_selectedImportFile!.importFileId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم توليد الفاتورة بنجاح: ${_selectedImportFile!.importFileCode} (${bytes.length} bytes)'),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في توليد النموذج: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handlePickAndParseExcel() async {
    if (_selectedImportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً.'), backgroundColor: Colors.red),
      );
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes == null) return;

      setState(() => _isParsing = true);
      try {
        final notifier = ref.read(standardInvoiceSessionsProvider.notifier);
        final parsed = await notifier.parseExcelFile(file.bytes!, file.name);

        if (!mounted) return;
        setState(() {
          _supplierData = parsed;
          _isParsing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم استخراج الفاتورة بنجاح: ${parsed.invoiceNumber ?? parsed.invoiceType} (${parsed.items.length} بنود)'),
            backgroundColor: const Color(0xFF27AE60),
          ),
        );

        // Auto trigger comparison
        await _handleRunComparison();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isParsing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء قراءة الفاتورة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRunComparison() async {
    if (_selectedImportFile == null || _supplierData == null) return;

    try {
      final notifier = ref.read(standardInvoiceSessionsProvider.notifier);
      final comp = await notifier.compareInvoice(_selectedImportFile!.importFileId, _supplierData!);

      if (!mounted) return;
      setState(() {
        _comparisonResult = comp;
      });

      _subTabController.animateTo(1); // Switch to comparison tab
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء المطابقة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleSaveSession() async {
    if (_selectedImportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً.'), backgroundColor: Colors.red),
      );
      return;
    }

    final hasIssues = (_comparisonResult?.hasDiscrepancies ?? false) || (_comparisonResult?.hasCriticalMismatch ?? false);
    if (_selectedStatus == 'APPROVED' && hasIssues) {
      if (_overrideReasonController.text.trim().isEmpty) {
        _formKey.currentState?.validate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ يجب كتابة سبب ومبرر اعتماد الفاتورة مع وجود فروق جمركية (Discrepancy Override Justification).'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(standardInvoiceSessionsProvider.notifier);
      final payload = {
        'import_file_id': _selectedImportFile!.importFileId,
        'import_file_code': _selectedImportFile!.importFileCode,
        'acid_number': _supplierData?.acidNumber ?? _selectedImportFile!.acidNumber,
        'invoice_number': _supplierData?.invoiceNumber ?? 'INV-${_selectedImportFile!.importFileCode}',
        'invoice_date': _supplierData?.invoiceDate,
        'invoice_type': _supplierData?.invoiceType ?? 'Commercial Invoice',
        'purchase_order_number': _supplierData?.purchaseOrderNumber,
        'exporter_name': _supplierData?.sellerName ?? _selectedImportFile!.supplierName,
        'exporter_tax_id': _supplierData?.sellerTaxId,
        'exporter_country_code': _supplierData?.sellerCountryCode,
        'importer_name': _supplierData?.buyerName ?? _selectedImportFile!.companyName,
        'importer_tax_id': _supplierData?.buyerTaxId,
        'currency_code': _supplierData?.currencyCode ?? 'EUR',
        'incoterm': _supplierData?.incoterm ?? _selectedImportFile!.incotermCode,
        'pol_code': _supplierData?.originPort,
        'pod_code': _supplierData?.destinationPort,
        'gross_weight_kg': _supplierData?.grossWeight ?? 0.0,
        'net_weight_kg': _supplierData?.netWeight ?? 0.0,
        'weight_unit': _supplierData?.weightUnit ?? 'KGM',
        'subtotal_amount': _supplierData?.subtotal ?? 0.0,
        'freight_cost': _supplierData?.freightCost ?? 0.0,
        'insurance_cost': _supplierData?.insuranceCost ?? 0.0,
        'other_costs': _supplierData?.otherCosts ?? 0.0,
        'total_amount': _supplierData?.totalAmount ?? 0.0,
        'line_items_count': _supplierData?.items.length ?? 0,
        'has_discrepancies': _comparisonResult?.hasDiscrepancies ?? false,
        'has_critical_mismatch': _comparisonResult?.hasCriticalMismatch ?? false,
        'discrepancy_override_reason': _overrideReasonController.text.trim(),
        'status': _selectedStatus,
        'notes': _notesController.text.trim(),
      };

      final saved = await notifier.saveOrUpsertSession(payload);
      if (!mounted) return;
      setState(() {
        _existingSession = saved;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ واعتماد جلسة مراجعة الفاتورة المعيارية بنجاح [${saved.sessionCode}]'),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ الجلسة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم نسخ $label إلى الحافظة بنجاح'), backgroundColor: const Color(0xFF27AE60)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(importFilesProvider);
    final sessionsAsync = ref.watch(standardInvoiceSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderSection(),
              if (_isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              _buildFileSelector(filesAsync),
              if (_existingSession != null) ...[
                const SizedBox(height: 12),
                _buildPreExistingStudyAlertBanner(),
              ],
              const SizedBox(height: 20),
              _buildActionToolsBar(),
              const SizedBox(height: 20),
              _buildTabBar(),
              const SizedBox(height: 16),
              _buildActiveTabContent(sessionsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.table_chart, color: Color(0xFF27AE60), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مركز إدارة وتوليد الفاتورة التجارية المعيارية (Standard Commercial Invoice Hub)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 4),
                Text(
                  'توليد نموذج إكسيل الموحد ذو النطاقات المسمّاة (Named Ranges & Structured Tables)، مطابقة بيانات المورد آلياً، واكتشاف الفروق الجمركية قبل إرسال المظروف لـ CargoX ونافذة.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          if (_existingSession != null)
            _buildStatusBadge(_existingSession!.status),
        ],
      ),
    );
  }

  Widget _buildFileSelector(AsyncValue<List<ImportFileModel>> filesAsync) {
    return filesAsync.when(
      data: (files) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBDC3C7).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SearchableDropdownField<int>(
                  labelText: 'اختيار ملف الشحنة الاستيرادية (Import File)',
                  hintText: 'ابحث برقم الملف، ACID، اسم المورد أو الشركة...',
                  value: _selectedImportFile?.importFileId,
                  items: files
                      .map((f) => SearchableDropdownItem<int>(
                            value: f.importFileId,
                            label: '${f.importFileCode} — ${f.supplierName} (${f.companyName}) [ACID: ${f.acidNumber ?? "N/A"}]',
                            searchValue: '${f.importFileCode} ${f.supplierName} ${f.companyName} ${f.acidNumber ?? ""}',
                          ))
                      .toList(),
                  onChanged: (fileId) {
                    if (fileId != null) {
                      final match = files.where((f) => f.importFileId == fileId).firstOrNull;
                      if (match != null) _onSelectImportFile(match);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(importFilesProvider.notifier).fetchImportFiles();
                  ref.read(standardInvoiceSessionsProvider.notifier).fetchSessions();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('تحديث'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('خطأ في تحميل ملفات الشحن: $e', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildPreExistingStudyAlertBanner() {
    final s = _existingSession!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9E7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF39C12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD68910), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ تم العثور على دراسة ومطابقة سابقة محفوظة لهذه الشحنة برقم: [${s.sessionCode}]',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF7D6608)),
                ),
                const SizedBox(height: 4),
                Text(
                  'تاريخ الحفظ: ${_formatDateTime(s.updatedAt)} | الحالة: ${s.status} | إجمالي الفاتورة: ${s.totalAmount.toStringAsFixed(2)} ${s.currencyCode} (${s.lineItemsCount} بنود)',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7D6608)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم استدعاء بيانات الجلسة ${s.sessionCode}')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD68910),
              foregroundColor: Colors.white,
            ),
            child: const Text('عرض التفاصيل'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolsBar() {
    return Row(
      children: [
        Expanded(
          child: _buildToolActionCard(
            title: '1. توليد نموذج الإكسيل المعياري',
            subtitle: 'تجهيز ملف .xlsx بنطاقات مسمّاة لإرساله للمورد',
            icon: Icons.download_for_offline,
            color: const Color(0xFF27AE60),
            buttonLabel: 'تحميل نموذج Excel الموحد',
            isLoading: _isDownloading,
            onTap: _handleDownloadTemplate,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildToolActionCard(
            title: '2. قراءة واستخراج فاتورة المورد',
            subtitle: 'رفع ملف الإكسيل المكتمل واستخراجه آلياً',
            icon: Icons.upload_file,
            color: const Color(0xFF3498DB),
            buttonLabel: 'رفع وقراءة فاتورة المورد (.xlsx)',
            isLoading: _isParsing,
            onTap: _handlePickAndParseExcel,
          ),
        ),
      ],
    );
  }

  Widget _buildToolActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String buttonLabel,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onTap,
              icon: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(icon, size: 18),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _subTabController,
        labelColor: const Color(0xFF2C3E50),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF27AE60),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.visibility), text: 'بيانات الفاتورة المستخرجة'),
          Tab(icon: Icon(Icons.compare_arrows), text: 'مصفوفة المطابقة والفروق'),
          Tab(icon: Icon(Icons.gavel), text: 'الاعتماد والتحكم الجمركي'),
          Tab(icon: Icon(Icons.history), text: 'سجل الفواتير المعيارية'),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(AsyncValue<List<StandardInvoiceSessionModel>> sessionsAsync) {
    return AnimatedBuilder(
      animation: _subTabController,
      builder: (context, _) {
        switch (_subTabController.index) {
          case 0:
            return _buildExtractedDataTab();
          case 1:
            return _buildComparisonMatrixTab();
          case 2:
            return _buildApprovalAndGovernanceTab();
          case 3:
            return _buildSessionsRegistryTab(sessionsAsync);
          default:
            return const SizedBox();
        }
      },
    );
  }

  Widget _buildExtractedDataTab() {
    if (_supplierData == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.file_copy_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('لم يتم رفع وقراءة ملف فاتورة المورد بعد.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('قم بتحميل النموذج أولاً ثم ارفعه بعد قيام المورد بملء البيانات.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final p = _supplierData!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تفاصيل الفاتورة: ${p.invoiceNumber ?? p.invoiceType} (${p.invoiceDate ?? "N/A"})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
              Chip(
                label: Text('${p.totalAmount.toStringAsFixed(2)} ${p.currencyCode}'),
                backgroundColor: const Color(0xFF27AE60).withOpacity(0.15),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoCard('بيانات المصدّر (Seller)', [
                  'الشركة: ${p.sellerName ?? "N/A"}',
                  'الرقم الضريبي: ${p.sellerTaxId ?? "N/A"}',
                  'الدولة: ${p.sellerCountryCode ?? "N/A"}',
                  'العنوان: ${p.sellerAddress ?? "N/A"}',
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard('بيانات المستورد (Buyer)', [
                  'الشركة: ${p.buyerName ?? "N/A"}',
                  'الرقم الضريبي (Egypt Tax Code): ${p.buyerTaxId ?? "N/A"}',
                  'رقم القيد الجمركي (ACID #): ${p.acidNumber ?? "N/A"}',
                  'شرط التسليم: ${p.incoterm ?? "N/A"} | العملة: ${p.currencyCode}',
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('جدول البنود المستخرجة (Extracted Line Items)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildItemsTable(p.items),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> lines) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C3E50))),
          const SizedBox(height: 8),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(l, style: const TextStyle(fontSize: 12)),
              )),
        ],
      ),
    );
  }

  Widget _buildItemsTable(List<StandardInvoiceLineItemModel> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF34495E)),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('كود الصنف')),
          DataColumn(label: Text('بند التعريفة (HS Code)')),
          DataColumn(label: Text('الوصف')),
          DataColumn(label: Text('الكمية')),
          DataColumn(label: Text('الوحدة')),
          DataColumn(label: Text('سعر الوحدة')),
          DataColumn(label: Text('الإجمالي')),
          DataColumn(label: Text('الوزن القائم (كجم)')),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(Text('${item.index}')),
              DataCell(Text(item.productCode ?? 'N/A')),
              DataCell(Text(item.hsCode, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(item.description)),
              DataCell(Text('${item.quantity}')),
              DataCell(Text(item.qtyUnit)),
              DataCell(Text(item.unitPrice.toStringAsFixed(2))),
              DataCell(Text(item.totalAmount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text('${item.grossWeightKg}')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComparisonMatrixTab() {
    if (_comparisonResult == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(Icons.compare_arrows, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('لم يتم إجراء المطابقة بعد.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('قم برفع فاتورة المورد لتشغيل محرك المطابقة واكتشاف الفروق تلقائياً.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final c = _comparisonResult!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComparisonStatsBanner(c),
          const SizedBox(height: 20),
          const Text('1. مطابقة الترويسة والبيانات الأساسية (Headers & Compliance)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildComparisonTable(c.headerComparisons),
          const SizedBox(height: 20),
          const Text('2. مطابقة القيم المالية والضرائب (Financials Reconciliation)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildComparisonTable(c.financialComparisons),
          const SizedBox(height: 20),
          const Text('3. مطابقة بنود الأصناف (Line Items Discrepancy Matrix)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildLineItemsComparisonTable(c.lineItemComparisons),
          if (c.hasDiscrepancies) ...[
            const SizedBox(height: 24),
            _buildRectificationNoticeSection(c),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonStatsBanner(StandardInvoiceComparisonResponseModel c) {
    Color bg = const Color(0xFFE8F8F5);
    Color border = const Color(0xFF27AE60);
    IconData icon = Icons.check_circle;
    String title = 'مطابقة تامة 100% — لا توجد أي فروق جمركية أو مالية';

    if (c.hasCriticalMismatch) {
      bg = const Color(0xFFFDEDEC);
      border = const Color(0xFFC0392B);
      icon = Icons.cancel;
      title = '⚠️ تحذير جمركي حرج: يوجد ${c.criticalMismatchesCount} عدم تطابق حرج (ACID / الرقم الضريبي / HS Code)';
    } else if (c.hasDiscrepancies) {
      bg = const Color(0xFFFEF9E7);
      border = const Color(0xFFF39C12);
      icon = Icons.warning;
      title = 'تنبيه: يوجد ${c.totalDiscrepanciesCount} اختلافات بسيطة تحتاج مراجعة قبل الاعتماد';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: border, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: border)),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(List<StandardInvoiceComparisonRowModel> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF2C3E50)),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        columns: const [
          DataColumn(label: Text('الحقل المقارن')),
          DataColumn(label: Text('القيمة المعتمدة بالنظام')),
          DataColumn(label: Text('القيمة بفاتورة المورد')),
          DataColumn(label: Text('حالة التطابق')),
          DataColumn(label: Text('الفروق والملاحظات')),
        ],
        rows: rows.map((r) {
          return DataRow(
            cells: [
              DataCell(Text('${r.fieldLabelAr}\n${r.fieldLabelEn}', style: const TextStyle(fontSize: 11))),
              DataCell(Text(r.systemValue ?? '—', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(r.supplierValue ?? '—')),
              DataCell(_buildStatusBadge(r.status)),
              DataCell(Text(r.difference ?? r.notes ?? '—', style: TextStyle(color: r.status == 'MATCH' ? Colors.grey : Colors.red, fontSize: 12))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineItemsComparisonTable(List<StandardInvoiceLineComparisonRowModel> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF2C3E50)),
        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('كود الصنف')),
          DataColumn(label: Text('HS Code (النظام)')),
          DataColumn(label: Text('HS Code (المورد)')),
          DataColumn(label: Text('الكمية (النظام)')),
          DataColumn(label: Text('الكمية (المورد)')),
          DataColumn(label: Text('السعر (النظام)')),
          DataColumn(label: Text('السعر (المورد)')),
          DataColumn(label: Text('الحالة')),
          DataColumn(label: Text('الملاحظات')),
        ],
        rows: rows.map((r) {
          return DataRow(
            cells: [
              DataCell(Text('${r.index}')),
              DataCell(Text(r.productCode)),
              DataCell(Text(r.hsCodeSystem ?? '—')),
              DataCell(Text(r.hsCodeSupplier ?? '—')),
              DataCell(Text('${r.qtySystem}')),
              DataCell(Text('${r.qtySupplier}')),
              DataCell(Text(r.unitPriceSystem.toStringAsFixed(2))),
              DataCell(Text(r.unitPriceSupplier.toStringAsFixed(2))),
              DataCell(_buildStatusBadge(r.status)),
              DataCell(Text(r.notes ?? '—', style: const TextStyle(fontSize: 11))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRectificationNoticeSection(StandardInvoiceComparisonResponseModel c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إخطارات تصحيح الفاتورة الجاهزة للمورد (Rectification Notices)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          if (c.rectificationNoticeEn != null)
            ListTile(
              title: const Text('English Email Rectification Notice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(c.rectificationNoticeEn!, maxLines: 3, overflow: TextOverflow.ellipsis),
              trailing: ElevatedButton.icon(
                onPressed: () => _copyToClipboard(c.rectificationNoticeEn!, 'إخطار الإيميل الإنجليزي'),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('نسخ'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3498DB), foregroundColor: Colors.white),
              ),
            ),
          const Divider(),
          if (c.rectificationNoticeAr != null)
            ListTile(
              title: const Text('إخطار التصحيح بالعربية (واتساب / إيميل)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(c.rectificationNoticeAr!, maxLines: 3, overflow: TextOverflow.ellipsis),
              trailing: ElevatedButton.icon(
                onPressed: () => _copyToClipboard(c.rectificationNoticeAr!, 'إخطار الواتساب العربي'),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('نسخ'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApprovalAndGovernanceTab() {
    final hasIssues = (_comparisonResult?.hasDiscrepancies ?? false) || (_comparisonResult?.hasCriticalMismatch ?? false);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('حالة اعتماد الفاتورة المعيارية (Invoice Governance Status)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusRadio('DRAFT', 'مسودة (Draft)', Colors.grey),
              const SizedBox(width: 12),
              _buildStatusRadio('UNDER_REVIEW', 'قيد المراجعة (Under Review)', const Color(0xFFF39C12)),
              const SizedBox(width: 12),
              _buildStatusRadio('APPROVED', 'معتمدة ومطابقة (Approved)', const Color(0xFF27AE60)),
              const SizedBox(width: 12),
              _buildStatusRadio('REJECTED_NEEDS_MODIFICATION', 'مرفوضة / تحتاج تعديل المورد', const Color(0xFFC0392B)),
            ],
          ),
          const SizedBox(height: 20),
          if (_selectedStatus == 'APPROVED' && hasIssues) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFFDEDEC), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚡ تنبيه أمني وإجرائي إلزامي: تم رصد فروق في الفاتورة. يُشترط كتابة مبرر وسبب التجاوز والاعتماد قبل الحفظ.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _overrideReasonController,
              decoration: const InputDecoration(
                labelText: 'مبرر وسبب الموافقة على الاختلافات الجمركية (Discrepancy Override Justification) *',
                hintText: 'اكتب المبرر الإداري أو المالي للموافقة على الفروق...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.gavel, color: Colors.red),
              ),
              maxLines: 3,
              validator: (v) {
                if (_selectedStatus == 'APPROVED' && hasIssues && (v == null || v.trim().isEmpty)) {
                  return 'حقل إلزامي: لا يمكن اعتماد الفاتورة مع وجود فروق بدون توضيح السبب والمبرر.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'ملاحظات إضافية (Internal Audit Notes)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_alt),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSaveSession,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('حفظ واعتماد جلسة مراجعة الفاتورة المعيارية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRadio(String value, String label, Color color) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedStatus,
              onChanged: (v) => setState(() => _selectedStatus = v!),
              activeColor: color,
            ),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.black87, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsRegistryTab(AsyncValue<List<StandardInvoiceSessionModel>> sessionsAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'بحث في سجل الفواتير برقم الجلسة، ACID، المورد...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => ref.read(standardInvoiceSessionsProvider.notifier).fetchSessions(search: v, status: _filterStatus),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterStatus,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('كل الحالات')),
                  DropdownMenuItem(value: 'APPROVED', child: Text('معتمدة (APPROVED)')),
                  DropdownMenuItem(value: 'UNDER_REVIEW', child: Text('قيد المراجعة')),
                  DropdownMenuItem(value: 'REJECTED_NEEDS_MODIFICATION', child: Text('مرفوضة')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _filterStatus = v);
                    ref.read(standardInvoiceSessionsProvider.notifier).fetchSessions(search: _searchController.text, status: v);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لا توجد جلسات فواتير مسجلة.')));
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF2C3E50)),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  columns: const [
                    DataColumn(label: Text('كود الجلسة')),
                    DataColumn(label: Text('ملف الشحنة')),
                    DataColumn(label: Text('رقم ACID')),
                    DataColumn(label: Text('رقم الفاتورة')),
                    DataColumn(label: Text('المصدر الأجنبي')),
                    DataColumn(label: Text('الإجمالي')),
                    DataColumn(label: Text('البنود')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('تاريخ التحديث')),
                  ],
                  rows: sessions.map((s) {
                    return DataRow(
                      cells: [
                        DataCell(Text(s.sessionCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(s.importFileCode)),
                        DataCell(Text(s.acidNumber ?? '—')),
                        DataCell(Text(s.invoiceNumber ?? '—')),
                        DataCell(Text(s.exporterName ?? '—')),
                        DataCell(Text('${s.totalAmount.toStringAsFixed(2)} ${s.currencyCode}')),
                        DataCell(Text('${s.lineItemsCount}')),
                        DataCell(_buildStatusBadge(s.status)),
                        DataCell(Text(_formatDateTime(s.updatedAt))),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('خطأ: $e', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String label = status;

    switch (status) {
      case 'APPROVED':
      case 'MATCH':
        color = const Color(0xFF27AE60);
        label = status == 'MATCH' ? 'مطابق' : 'معتمد';
        break;
      case 'WARNING':
      case 'UNDER_REVIEW':
        color = const Color(0xFFF39C12);
        label = status == 'WARNING' ? 'فرق طفيف' : 'قيد المراجعة';
        break;
      case 'CRITICAL_MISMATCH':
      case 'REJECTED_NEEDS_MODIFICATION':
        color = const Color(0xFFC0392B);
        label = status == 'CRITICAL_MISMATCH' ? 'فرق حرج' : 'مرفوض للتعديل';
        break;
      case 'DRAFT':
        color = Colors.blueGrey;
        label = 'مسودة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
