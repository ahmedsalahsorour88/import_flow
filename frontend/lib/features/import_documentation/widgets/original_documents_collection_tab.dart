import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/original_documents_collection_model.dart';
import '../providers/original_documents_collection_provider.dart';

String _formatDateTime(DateTime dt) {
  final str = dt.toIso8601String();
  if (str.length >= 16) {
    return str.substring(0, 16).replaceAll('T', ' ');
  }
  return str;
}

class OriginalDocumentsCollectionTab extends ConsumerStatefulWidget {
  final int? initialImportFileId;

  const OriginalDocumentsCollectionTab({super.key, this.initialImportFileId});

  @override
  ConsumerState<OriginalDocumentsCollectionTab> createState() =>
      _OriginalDocumentsCollectionTabState();
}

class _OriginalDocumentsCollectionTabState
    extends ConsumerState<OriginalDocumentsCollectionTab> {
  final _formKey = GlobalKey<FormState>();

  ImportFileModel? _selectedImportFile;
  OriginalDocumentsCollectionSessionModel? _existingSession;

  List<CourierEntryModel> _couriers = [];
  List<OriginalDocumentItemModel> _documents = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isExporting = false;

  String _sessionStatus = 'DRAFT';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _overrideReasonController = TextEditingController();
  final TextEditingController _registrySearchController = TextEditingController();
  String _registryStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(originalDocumentsSessionsProvider.notifier).fetchSessions();
      if (widget.initialImportFileId != null) {
        _loadInitialFile(widget.initialImportFileId!);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _overrideReasonController.dispose();
    _registrySearchController.dispose();
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
      _couriers = [];
      _documents = [];
      _notesController.clear();
      _overrideReasonController.clear();
      _isLoading = true;
    });

    try {
      final notifier = ref.read(originalDocumentsSessionsProvider.notifier);
      final autoData = await notifier.fetchAutoPopulate(file.importFileId);

      if (!mounted) return;
      setState(() {
        if (autoData.existingSession != null) {
          _existingSession = autoData.existingSession;
          _couriers = List.from(autoData.existingSession!.couriersList);
          _documents = List.from(autoData.existingSession!.documentsList);
          _sessionStatus = autoData.existingSession!.status;
          _notesController.text = autoData.existingSession!.notes ?? '';
          _overrideReasonController.text =
              autoData.existingSession!.discrepancyOverrideReason ?? '';
        } else {
          _couriers = List.from(autoData.defaultCouriers);
          _documents = List.from(autoData.requiredDocuments);
          _sessionStatus = 'DRAFT';
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في استدعاء بيانات الأرشيف: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _addCourier() {
    setState(() {
      _couriers.add(
        CourierEntryModel(
          courierNo: '',
          courierCompany: 'DHL',
          dispatchDate: DateTime.now().toIso8601String().substring(0, 10),
          isReceived: false,
        ),
      );
    });
  }

  void _removeCourier(int index) {
    setState(() {
      _couriers.removeAt(index);
    });
  }

  void _addCustomDocument() {
    setState(() {
      _documents.add(
        OriginalDocumentItemModel(
          category: 'Commercial',
          documentName: 'مستند إضافي جديد',
          isRequired: 'Yes',
          responsibleParty: 'Supplier',
          status: 'Pending',
        ),
      );
    });
  }

  void _removeDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
  }

  Future<void> _handleSaveSession({bool isConfirmComplete = false}) async {
    if (_selectedImportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (isConfirmComplete) {
      final unverified = _documents.where((d) => !d.isVerified && d.isRequired == 'Yes').toList();
      if (unverified.isNotEmpty && _overrideReasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ توجد مستندات إلزامية لم يتم تدقيقها بعد. يرجى ذكر مبرر الاعتماد قبل التأكيد النهائي.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(originalDocumentsSessionsProvider.notifier);
      final payload = {
        'import_file_id': _selectedImportFile!.importFileId,
        'import_file_code': _selectedImportFile!.importFileCode,
        'acid_number': _selectedImportFile!.acidNumber,
        'importer_name': _selectedImportFile!.companyName,
        'supplier_name': _selectedImportFile!.supplierName,
        'status': isConfirmComplete ? 'FULLY_VERIFIED' : _sessionStatus,
        'couriers_list': _couriers.map((c) => c.toJson()).toList(),
        'documents_list': _documents.map((d) => d.toJson()).toList(),
        'discrepancy_override_reason': _overrideReasonController.text.trim(),
        'notes': _notesController.text.trim(),
      };

      final saved = await notifier.saveOrUpsertSession(payload);
      if (!mounted) return;
      setState(() {
        _existingSession = saved;
        _sessionStatus = saved.status;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ وتحديث جلسة تحصيل أصول المستندات بنجاح [${saved.collectionCode}]'),
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

  Future<void> _handleExportExcel() async {
    if (_selectedImportFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف الشحنة أولاً.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final notifier = ref.read(originalDocumentsSessionsProvider.notifier);
      final bytes = await notifier.downloadExcel(_selectedImportFile!.importFileId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم توليد وتصدير ملف Excel بنجاح (${bytes.length} bytes)'),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تصدير Excel: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filesAsync = ref.watch(importFilesProvider);
    final sessionsAsync = ref.watch(originalDocumentsSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              if (_isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              _buildFileSelector(filesAsync),
              if (_selectedImportFile != null) ...[
                const SizedBox(height: 16),
                _buildStatisticsCards(),
                const SizedBox(height: 16),
                _buildCouriersManagementCard(),
                const SizedBox(height: 16),
                _buildDocumentsCollectionGrid(),
                const SizedBox(height: 16),
                _buildActionToolbar(),
              ],
              const SizedBox(height: 24),
              _buildRegistrySection(sessionsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              color: AppTheme.cobalt.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.markunread_mailbox_outlined, color: AppTheme.cobalt, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تحصيل أصول المستندات وتتبع طرود الكورير (Original Documents Collection Hub)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  'استدعاء تلقائي للمستندات المطلوبة من الأرشيف المركزي للشحنة، تتبع طرود البريد السريع المتعددة (DHL / FedEx)، وتدقيق استلام الأصول الورقية.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          if (_existingSession != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF27AE60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF27AE60), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'جلسة محفوظة: ${_existingSession!.collectionCode}',
                    style: const TextStyle(color: Color(0xFF27AE60), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileSelector(AsyncValue<List<ImportFileModel>> filesAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: filesAsync.when(
        data: (files) {
          return Row(
            children: [
              Expanded(
                child: SearchableDropdownField<int>(
                  labelText: 'اختيار ملف الشحنة (Import File)',
                  hintText: 'ابحث برقم الملف، ACID، المورد أو الشركة المستوردة...',
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
                onPressed: () => ref.read(importFilesProvider.notifier).fetchImportFiles(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('تحديث'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('خطأ في جلب ملفات الاستيراد: $e', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final totalDocs = _documents.length;
    final receivedDocs = _documents.where((d) => d.isReceived).length;
    final verifiedDocs = _documents.where((d) => d.isVerified).length;
    final pendingDocs = totalDocs - receivedDocs;
    final completionPct = totalDocs > 0 ? (verifiedDocs / totalDocs * 100).toStringAsFixed(1) : '0.0';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statCard('إجمالي المستندات المطلوبة', '$totalDocs', Icons.description_outlined, AppTheme.charcoal),
          const SizedBox(width: 12),
          _statCard('تم استلام الأصل الورقي', '$receivedDocs', Icons.inbox_outlined, const Color(0xFF3498DB)),
          const SizedBox(width: 12),
          _statCard('تم الفحص والتدقيق', '$verifiedDocs', Icons.verified_outlined, const Color(0xFF27AE60)),
          const SizedBox(width: 12),
          _statCard('قيد الانتظار', '$pendingDocs', Icons.hourglass_empty_outlined, const Color(0xFFE67E22)),
          const SizedBox(width: 12),
          _statCard('نسبة الاكتمال والجاهزية', '$completionPct%', Icons.pie_chart_outline, const Color(0xFF8E44AD)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildCouriersManagementCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: AppTheme.cobalt, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'طرود وبوالص الشحن السريع للكورير (Courier Dispatch Packages):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _addCourier,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('إضافة بوليصة كورير'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_couriers.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text('لم يتم تسجيل بوالص كورير بعد. اضغط زر إضافة بوليصة لإدراج شحنة بريد سريع.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _couriers.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final c = _couriers[idx];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.cobalt.withOpacity(0.15),
                      child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: c.courierNo,
                        decoration: const InputDecoration(
                          labelText: 'رقم بوليصة الكورير (AWB / Tracking No)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => c.courierNo = val.trim(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: ['DHL', 'FedEx', 'Aramex', 'UPS', 'Naqel', 'SMSA', 'Hand Delivery', 'Other'].contains(c.courierCompany)
                            ? c.courierCompany
                            : 'DHL',
                        decoration: const InputDecoration(
                          labelText: 'شركة الكورير',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: ['DHL', 'FedEx', 'Aramex', 'UPS', 'Naqel', 'SMSA', 'Hand Delivery', 'Other']
                            .map((company) => DropdownMenuItem(value: company, child: Text(company, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => c.courierCompany = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: c.dispatchDate,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الإرسال (YYYY-MM-DD)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => c.dispatchDate = val.trim(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: c.isReceived,
                          activeColor: const Color(0xFF27AE60),
                          onChanged: (val) {
                            setState(() {
                              c.isReceived = val ?? false;
                              if (c.isReceived && (c.receivedDate == null || c.receivedDate!.isEmpty)) {
                                c.receivedDate = DateTime.now().toIso8601String().substring(0, 10);
                              }
                            });
                          },
                        ),
                        const Text('تم الاستلام', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: c.receivedBy,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستلم',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => c.receivedBy = val.trim(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _removeCourier(idx),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentsCollectionGrid() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.table_view_outlined, color: Color(0xFF27AE60), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'مصفوفة استلام وتدقيق أصول المستندات الورقية (Physical Documents Verification Matrix):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _addCustomDocument,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('إضافة مستند إضافي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF2C3E50)),
              headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columns: const [
                DataColumn(label: Text('رقم الكورير (Courier No)')),
                DataColumn(label: Text('تصنيف الوثيقة')),
                DataColumn(label: Text('اسم المستند')),
                DataColumn(label: Text('الإلزامية')),
                DataColumn(label: Text('الجهة المسؤولة')),
                DataColumn(label: Text('تم الاستلام الورقي')),
                DataColumn(label: Text('تاريخ الاستلام')),
                DataColumn(label: Text('تم الفحص والتدقيق')),
                DataColumn(label: Text('القائم بالتدقيق')),
                DataColumn(label: Text('الحالة')),
                DataColumn(label: Text('ملاحظات')),
                DataColumn(label: Text('إجراء')),
              ],
              rows: List.generate(_documents.length, (index) {
                final doc = _documents[index];
                return DataRow(
                  cells: [
                    // Courier No
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<String>(
                          value: _couriers.any((c) => c.courierNo == doc.courierNo && c.courierNo.isNotEmpty)
                              ? doc.courierNo
                              : null,
                          isDense: true,
                          hint: const Text('اختر الكورير', style: TextStyle(fontSize: 11)),
                          decoration: const InputDecoration(border: InputBorder.none),
                          items: _couriers
                              .where((c) => c.courierNo.isNotEmpty)
                              .map((c) => DropdownMenuItem(value: c.courierNo, child: Text(c.courierNo, style: const TextStyle(fontSize: 11))))
                              .toList(),
                          onChanged: (val) {
                            setState(() => doc.courierNo = val);
                          },
                        ),
                      ),
                    ),
                    // Category
                    DataCell(
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<String>(
                          value: doc.category,
                          isDense: true,
                          decoration: const InputDecoration(border: InputBorder.none),
                          items: ['Commercial', 'Certificate', 'Shipping', 'Egypt Import', 'Banking', 'Regulatory', 'Other']
                              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 11))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => doc.category = val);
                          },
                        ),
                      ),
                    ),
                    // Document Name
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: TextFormField(
                          initialValue: doc.documentName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(border: InputBorder.none),
                          onChanged: (val) => doc.documentName = val.trim(),
                        ),
                      ),
                    ),
                    // Required
                    DataCell(_buildRequiredBadge(doc.isRequired)),
                    // Responsible Party
                    DataCell(Text(doc.responsibleParty, style: const TextStyle(fontSize: 11))),
                    // Received Checkbox
                    DataCell(
                      Checkbox(
                        value: doc.isReceived,
                        activeColor: const Color(0xFF3498DB),
                        onChanged: (val) {
                          setState(() {
                            doc.isReceived = val ?? false;
                            if (doc.isReceived && (doc.receivedDate == null || doc.receivedDate!.isEmpty)) {
                              doc.receivedDate = DateTime.now().toIso8601String().substring(0, 10);
                            }
                            if (doc.isReceived && doc.status == 'Pending') {
                              doc.status = 'Received';
                            }
                          });
                        },
                      ),
                    ),
                    // Received Date
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: doc.receivedDate,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(hintText: 'YYYY-MM-DD', border: InputBorder.none),
                          onChanged: (val) => doc.receivedDate = val.trim(),
                        ),
                      ),
                    ),
                    // Verified Checkbox
                    DataCell(
                      Checkbox(
                        value: doc.isVerified,
                        activeColor: const Color(0xFF27AE60),
                        onChanged: (val) {
                          setState(() {
                            doc.isVerified = val ?? false;
                            if (doc.isVerified) {
                              doc.isReceived = true;
                              doc.status = 'Verified';
                              if (doc.verificationDate == null || doc.verificationDate!.isEmpty) {
                                doc.verificationDate = DateTime.now().toIso8601String().substring(0, 10);
                              }
                              if (doc.verifiedBy == null || doc.verifiedBy!.isEmpty) {
                                doc.verifiedBy = 'Kamal';
                              }
                            } else {
                              doc.status = doc.isReceived ? 'Received' : 'Pending';
                            }
                          });
                        },
                      ),
                    ),
                    // Verified By
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue: doc.verifiedBy,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(hintText: 'المدقق', border: InputBorder.none),
                          onChanged: (val) => doc.verifiedBy = val.trim(),
                        ),
                      ),
                    ),
                    // Status Badge
                    DataCell(_buildStatusBadge(doc.status)),
                    // Remarks
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          initialValue: doc.remarks,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(hintText: 'ملاحظات...', border: InputBorder.none),
                          onChanged: (val) => doc.remarks = val.trim(),
                        ),
                      ),
                    ),
                    // Actions
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        onPressed: () => _removeDocument(index),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredBadge(String req) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade800;
    if (req == 'Yes') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else if (req == 'Conditional') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(req, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;
    switch (status) {
      case 'Verified':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'Received':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case 'In Transit':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      case 'Discrepant':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case 'Pending':
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _handleSaveSession(isConfirmComplete: false),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('حفظ مؤقت (Save Draft)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.charcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _handleSaveSession(isConfirmComplete: true),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('اعتماد واكتمال التحصيل (Complete Collection)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isExporting ? null : _handleExportExcel,
                  icon: const Icon(Icons.table_chart, size: 18, color: Color(0xFF27AE60)),
                  label: const Text('تصدير Excel', style: TextStyle(color: Color(0xFF27AE60), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF27AE60)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrySection(AsyncValue<List<OriginalDocumentsCollectionSessionModel>> sessionsAsync) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_edu_outlined, color: AppTheme.cobalt, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'سجل جلسات تحصيل أصول المستندات (Physical Documents Collection Registry):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.charcoal),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _registrySearchController,
                        decoration: const InputDecoration(
                          hintText: 'بحث برقم الكود أو الشحنة...',
                          prefixIcon: Icon(Icons.search, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref.read(originalDocumentsSessionsProvider.notifier).fetchSessions(
                                search: val,
                                status: _registryStatusFilter,
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _registryStatusFilter,
                      items: ['All', 'DRAFT', 'PARTIALLY_RECEIVED', 'FULLY_RECEIVED', 'FULLY_VERIFIED']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _registryStatusFilter = val);
                          ref.read(originalDocumentsSessionsProvider.notifier).fetchSessions(
                                search: _registrySearchController.text,
                                status: val,
                              );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text('لا توجد جلسات تحصيل مسجلة بعد.', style: TextStyle(color: Colors.grey.shade600)),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF2F4F4)),
                  headingTextStyle: const TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 12),
                  columns: const [
                    DataColumn(label: Text('كود الجلسة')),
                    DataColumn(label: Text('ملف الشحنة')),
                    DataColumn(label: Text('رقم ACID')),
                    DataColumn(label: Text('المورد الأجنبي')),
                    DataColumn(label: Text('إجمالي المستندات')),
                    DataColumn(label: Text('تم الاستلام')),
                    DataColumn(label: Text('تم التدقيق')),
                    DataColumn(label: Text('نسبة الإنجاز')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('تاريخ التحديث')),
                  ],
                  rows: sessions.map((s) {
                    return DataRow(
                      cells: [
                        DataCell(Text(s.collectionCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(s.importFileCode)),
                        DataCell(Text(s.acidNumber ?? '—')),
                        DataCell(Text(s.supplierName ?? '—')),
                        DataCell(Text('${s.totalDocumentsCount}')),
                        DataCell(Text('${s.receivedDocumentsCount}')),
                        DataCell(Text('${s.verifiedDocumentsCount}')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: s.completionPercentage == 100 ? Colors.green.shade100 : Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${s.completionPercentage}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: s.completionPercentage == 100 ? Colors.green.shade800 : Colors.amber.shade900,
                                )),
                          ),
                        ),
                        DataCell(_buildStatusBadge(s.status)),
                        DataCell(Text(_formatDateTime(s.updatedAt))),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('خطأ في جلب السجل: $e', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
