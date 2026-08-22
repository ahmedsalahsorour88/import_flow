import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../models/customs_clearance_model.dart';
import '../providers/customs_clearance_provider.dart';

class CustomsClearanceScreen extends ConsumerStatefulWidget {
  const CustomsClearanceScreen({super.key});

  @override
  ConsumerState<CustomsClearanceScreen> createState() => _CustomsClearanceScreenState();
}

class _CustomsClearanceScreenState extends ConsumerState<CustomsClearanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customsClearanceProvider.notifier).fetchRecords();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(partnersProvider.notifier).fetchPartners();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([CustomsClearanceModel? recordToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CustomsClearanceFormDialog(recordToEdit: recordToEdit),
    );
  }

  void _showDutyPaymentDialog(CustomsClearanceModel record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DutyPaymentDialog(record: record),
    );
  }

  void _showFinalReleaseDialog(CustomsClearanceModel record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FinalReleaseDialog(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clearanceAsync = ref.watch(customsClearanceProvider);

    return VerticalStageScaffold(
      stageCode: 'PHASE-07',
      titleAr: 'التخليص الجمركي والمعاينة والمطابقة',
      titleEn: 'Customs Clearance & Inspection',
      headerIcon: Icons.gavel_rounded,
      selectedIndex: _selectedTab,
      onTabSelected: (idx) => setState(() => _selectedTab = idx),
      tabs: const [
        VerticalNavTabItem(
          icon: Icons.assignment_outlined,
          titleAr: 'سجل التخليص والمعاينة',
          titleEn: 'Clearance & Inspection Registry',
        ),
        VerticalNavTabItem(
          icon: Icons.payments_outlined,
          titleAr: 'مطابقة وسداد رسوم نافذة',
          titleEn: 'Nafeza Duty Assessment & Ledger',
        ),
      ],
      body: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'بحث بكود التخليص، رقم 46 ك.م، إذن التسليم...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        ref.read(customsClearanceProvider.notifier).fetchRecords(
                              search: val,
                              status: _selectedStatusFilter,
                            );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedStatusFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('جميع الحالات')),
                      DropdownMenuItem(value: 'Inspection In Progress', child: Text('قيد المعاينة والفحص')),
                      DropdownMenuItem(value: 'Duty Requested', child: Text('مطلوب سداد الجمارك')),
                      DropdownMenuItem(value: 'Duty Paid', child: Text('تم سداد الرسوم')),
                      DropdownMenuItem(value: 'Final Release Granted', child: Text('تم الإفراج النهائي')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedStatusFilter = val);
                        ref.read(customsClearanceProvider.notifier).fetchRecords(
                              search: _searchController.text,
                              status: val,
                            );
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cobalt,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('تسجيل معاملة تخليص'),
                    onPressed: () => _showAddEditDialog(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.cobalt),
                    tooltip: 'تحديث البيانات',
                    onPressed: () {
                      ref.read(customsClearanceProvider.notifier).fetchRecords(
                            search: _searchController.text,
                            status: _selectedStatusFilter,
                          );
                      ref.read(importFilesProvider.notifier).fetchImportFiles();
                      ref.read(partnersProvider.notifier).fetchPartners();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Records List
            Expanded(
              child: clearanceAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('خطأ في جلب بيانات التخليص الجمركي: $err', style: const TextStyle(color: Colors.red)),
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(
                      child: Text('لا توجد سجلات تخليص جمركي مسجلة حالياً.'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return _buildClearanceCard(record);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearanceCard(CustomsClearanceModel record) {
    Color statusColor = Colors.blueGrey;
    if (record.status == 'Final Release Granted') statusColor = AppTheme.emerald;
    if (record.status == 'Duty Paid') statusColor = AppTheme.cobalt;
    if (record.status == 'Duty Requested') statusColor = AppTheme.orange;

    final isGreenChannel = record.channelType.toLowerCase().contains('green');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.clearanceCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isGreenChannel ? AppTheme.emerald : AppTheme.crimson).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isGreenChannel ? AppTheme.emerald : AppTheme.crimson, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isGreenChannel ? Icons.check_circle_outline : Icons.flag_rounded, size: 14, color: isGreenChannel ? AppTheme.emerald : AppTheme.crimson),
                          const SizedBox(width: 4),
                          Text(
                            record.channelType,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isGreenChannel ? AppTheme.emerald : AppTheme.crimson),
                          ),
                        ],
                      ),
                    ),
                    if (record.declaration46No != null && record.declaration46No!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('46 ك.م: ${record.declaration46No}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt)),
                    ],
                    if (record.deliveryOrderNumber != null && record.deliveryOrderNumber!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('إذن التسليم: ${record.deliveryOrderNumber}', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    record.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🏢 الجمرك / المركز: ${record.customsOfficeName}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('ملف الشحنة المرجعي: IMP-${record.importFileId}', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                      if (record.freeDaysAllowed > 0)
                        Text('⏱️ فترة السماح بالميناء: ${record.freeDaysAllowed} يوم', style: const TextStyle(fontSize: 11.5, color: Colors.indigo, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💰 إجمالي الرسوم: ${(record.actualDutyTotal > 0 ? record.actualDutyTotal : record.totalDutyPayable).toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                      const SizedBox(height: 4),
                      if (record.estimatedDutyTotal > 0)
                        Text(
                          '⚖️ التقديري: ${record.estimatedDutyTotal.toStringAsFixed(2)} ج.م (الفارق: ${record.dutyVarianceAmount >= 0 ? "+" : ""}${record.dutyVarianceAmount.toStringAsFixed(2)} ج.م [${record.dutyVariancePercentage}%])',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: record.dutyVarianceAmount.abs() > 500 ? AppTheme.orange : Colors.black54),
                        ),
                      Text('حالة السداد: ${record.paymentStatus}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: record.paymentStatus == 'Paid & Verified' ? AppTheme.emerald : Colors.red)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.cobalt, size: 20),
                      tooltip: 'تعديل المعاملة',
                      onPressed: () => _showAddEditDialog(record),
                    ),
                    IconButton(
                      icon: const Icon(Icons.payments_outlined, color: AppTheme.emerald, size: 20),
                      tooltip: 'سداد ومطابقة الجمارك من نافذة',
                      onPressed: () => _showDutyPaymentDialog(record),
                    ),
                    IconButton(
                      icon: const Icon(Icons.assignment_turned_in_outlined, color: Colors.indigo, size: 20),
                      tooltip: 'إصدار الإفراج النهائي',
                      onPressed: () => _showFinalReleaseDialog(record),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomsClearanceFormDialog extends ConsumerStatefulWidget {
  final CustomsClearanceModel? recordToEdit;
  const _CustomsClearanceFormDialog({this.recordToEdit});

  @override
  ConsumerState<_CustomsClearanceFormDialog> createState() => _CustomsClearanceFormDialogState();
}

class _CustomsClearanceFormDialogState extends ConsumerState<_CustomsClearanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedImportFileId;
  final TextEditingController _decl46Ctrl = TextEditingController();
  final TextEditingController _officeCtrl = TextEditingController(text: 'Alexandria Port Customs');
  final TextEditingController _doNumberCtrl = TextEditingController();
  final TextEditingController _freeDaysCtrl = TextEditingController(text: '14');
  String _channelType = 'Red Channel';
  final TextEditingController _dutyCtrl = TextEditingController(text: '0');
  final TextEditingController _vatCtrl = TextEditingController(text: '0');
  final TextEditingController _scheduleTaxCtrl = TextEditingController(text: '0');
  final TextEditingController _whtCtrl = TextEditingController(text: '0');
  final TextEditingController _labFeesCtrl = TextEditingController(text: '0');
  final TextEditingController _estimatedDutyCtrl = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.recordToEdit != null) {
      final r = widget.recordToEdit!;
      _selectedImportFileId = r.importFileId;
      _decl46Ctrl.text = r.declaration46No ?? '';
      _officeCtrl.text = r.customsOfficeName;
      _doNumberCtrl.text = r.deliveryOrderNumber ?? '';
      _freeDaysCtrl.text = r.freeDaysAllowed.toString();
      _channelType = r.channelType;
      _dutyCtrl.text = r.importDutyAmount.toString();
      _vatCtrl.text = r.vatAmount.toString();
      _scheduleTaxCtrl.text = r.scheduleTaxAmount.toString();
      _whtCtrl.text = r.whtAmount.toString();
      _labFeesCtrl.text = r.labServiceFees.toString();
      _estimatedDutyCtrl.text = r.estimatedDutyTotal.toString();
    }
  }

  void _applyExtractedNafezaData(Map<String, dynamic> ext) {
    setState(() {
      if (ext['declaration_no'] != null && ext['declaration_no'].toString().isNotEmpty) {
        _decl46Ctrl.text = ext['declaration_no'].toString();
      }
      if (ext['customs_office_name'] != null && ext['customs_office_name'].toString().isNotEmpty) {
        _officeCtrl.text = ext['customs_office_name'].toString();
      }
      if (ext['channel_type'] != null && ext['channel_type'].toString().isNotEmpty) {
        _channelType = ext['channel_type'].toString();
      }
      if (ext['import_duty'] != null) {
        _dutyCtrl.text = ext['import_duty'].toString();
      }
      if (ext['vat_amount'] != null) {
        _vatCtrl.text = ext['vat_amount'].toString();
      }
      if (ext['schedule_tax'] != null) {
        _scheduleTaxCtrl.text = ext['schedule_tax'].toString();
      }
      if (ext['wht_amount'] != null) {
        _whtCtrl.text = ext['wht_amount'].toString();
      }
      if (ext['lab_service_fees'] != null) {
        _labFeesCtrl.text = ext['lab_service_fees'].toString();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚡ تم استخلاص وتعبئة بيانات إقرار نافذة والرسوم بنجاح!'), backgroundColor: AppTheme.emerald),
    );
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.recordToEdit == null ? 'تسجيل معاملة تخليص جمركي وميناء جديدة' : 'تعديل بيانات التخليص الجمركي (${widget.recordToEdit!.clearanceCode})'),
          SmartUploadButton(
            module: SmartUploadModule.customsClearance,
            compact: true,
            label: '⚡ استخلاص من نافذة',
            onDataExtracted: (res) => _applyExtractedNafezaData(res.extractedFields),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchableDropdownField<int>(
                  value: _selectedImportFileId,
                  labelText: 'ملف الشحنة الاستيرادية المرتكز عليه *',
                  searchHintText: 'ابحث برقم الملف أو كود الشحنة...',
                  items: importFiles
                      .map((f) => SearchableDropdownItem<int>(
                            value: f.importFileId,
                            label: '${f.importFileCode} - ${f.companyName}',
                            subtitle: 'PO: ${f.poNumber ?? "N/A"} | ACID: ${f.acidNumber ?? "N/A"}',
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedImportFileId = val),
                  validator: (val) => val == null ? 'يرجى اختيار ملف الشحنة' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _decl46Ctrl,
                        decoration: const InputDecoration(labelText: 'رقم الإقرار الجمركي (46 ك.م)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _doNumberCtrl,
                        decoration: const InputDecoration(labelText: 'رقم إذن التسليم (D/O Number)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _freeDaysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'أيام السماح (Free Days)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _officeCtrl,
                        decoration: const InputDecoration(labelText: 'اسم الجمرك والدائرة الجمركية *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الجمرك' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _channelType,
                        decoration: const InputDecoration(labelText: 'المسار الجمركي *', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Red Channel', child: Text('🔴 مسار أحمر (معاينة وعينات)')),
                          DropdownMenuItem(value: 'Green Channel', child: Text('🟢 مسار أخضر (إفراج مستندي)')),
                          DropdownMenuItem(value: 'Yellow Channel', child: Text('🟡 مسار أصفر (مراجعة مستندية)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _channelType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('مطالبة الرسوم والضرائب الجمركية (Duty Breakdown EGP):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dutyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ضريبة الوارد (Duty EGP)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _vatCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'القيمة المضافة (VAT EGP)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _scheduleTaxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ضريبة الجدول (Schedule)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _whtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'أرباح تجارية (WHT 1%)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _labFeesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'رسوم المعامل والخدمات', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final payload = {
                        'import_file_id': _selectedImportFileId,
                        'declaration_46_no': _decl46Ctrl.text.trim(),
                        'delivery_order_number': _doNumberCtrl.text.trim().isEmpty ? null : _doNumberCtrl.text.trim(),
                        'free_days_allowed': int.tryParse(_freeDaysCtrl.text.trim()) ?? 14,
                        'customs_office_name': _officeCtrl.text.trim(),
                        'channel_type': _channelType,
                        'import_duty_amount': double.tryParse(_dutyCtrl.text.trim()) ?? 0.0,
                        'vat_amount': double.tryParse(_vatCtrl.text.trim()) ?? 0.0,
                        'schedule_tax_amount': double.tryParse(_scheduleTaxCtrl.text.trim()) ?? 0.0,
                        'wht_amount': double.tryParse(_whtCtrl.text.trim()) ?? 0.0,
                        'lab_service_fees': double.tryParse(_labFeesCtrl.text.trim()) ?? 0.0,
                        'estimated_duty_total': double.tryParse(_estimatedDutyCtrl.text.trim()) ?? 0.0,
                      };

                      if (widget.recordToEdit == null) {
                        await ref.read(customsClearanceProvider.notifier).createRecord(payload);
                      }
                      nav.pop();
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppTheme.crimson));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('حفظ وتسجيل المعاملة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _DutyPaymentDialog extends ConsumerStatefulWidget {
  final CustomsClearanceModel record;
  const _DutyPaymentDialog({required this.record});

  @override
  ConsumerState<_DutyPaymentDialog> createState() => _DutyPaymentDialogState();
}

class _DutyPaymentDialogState extends ConsumerState<_DutyPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rcptCtrl = TextEditingController();
  final TextEditingController _bankCtrl = TextEditingController(text: 'National Bank of Egypt (NBE)');
  late TextEditingController _actualDutyCtrl;
  late TextEditingController _estimatedDutyCtrl;
  final TextEditingController _reasonCtrl = TextEditingController();
  Map<String, dynamic>? _nafezaExtractedJson;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final actual = widget.record.actualDutyTotal > 0 ? widget.record.actualDutyTotal : widget.record.totalDutyPayable;
    _actualDutyCtrl = TextEditingController(text: actual.toStringAsFixed(2));
    _estimatedDutyCtrl = TextEditingController(text: widget.record.estimatedDutyTotal.toStringAsFixed(2));
    _rcptCtrl.text = widget.record.bankReceiptNo ?? '';
    if (widget.record.payingBankName != null) {
      _bankCtrl.text = widget.record.payingBankName!;
    }
    _reasonCtrl.text = widget.record.dutyVarianceReason ?? '';
  }

  void _applyExtractedNafezaData(Map<String, dynamic> ext) {
    setState(() {
      _nafezaExtractedJson = ext;
      if (ext['total_taxes'] != null) {
        _actualDutyCtrl.text = ext['total_taxes'].toString();
      } else if (ext['total_duty_payable'] != null) {
        _actualDutyCtrl.text = ext['total_duty_payable'].toString();
      }
      if (ext['declaration_no'] != null && ext['declaration_no'].toString().isNotEmpty) {
        _reasonCtrl.text = 'استخلاص آلي من إذن سداد نافذة رقم ${ext["assessment_reference"] ?? ext["declaration_no"]}';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚡ تم استخلاص إذن سداد نافذة الفعلي ومطابقته فورياً!'), backgroundColor: AppTheme.emerald),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partners = ref.watch(partnersProvider).value ?? [];
    final banks = partners.where((p) => p.partnerType.contains('Bank') || p.partnerType.contains('Financial')).toList();

    final actualVal = double.tryParse(_actualDutyCtrl.text.trim()) ?? 0.0;
    final estimatedVal = double.tryParse(_estimatedDutyCtrl.text.trim()) ?? 0.0;
    final varianceVal = estimatedVal > 0 ? (actualVal - estimatedVal) : 0.0;
    final variancePct = estimatedVal > 0 ? ((varianceVal / estimatedVal) * 100) : 0.0;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'توثيق سداد الرسوم ومطابقة نافذة (${widget.record.clearanceCode})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SmartUploadButton(
            module: SmartUploadModule.customsClearance,
            compact: true,
            label: '⚡ استخلاص من نافذة',
            onDataExtracted: (res) => _applyExtractedNafezaData(res.extractedFields),
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Live Variance Comparison Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.compare_arrows_rounded, size: 18, color: AppTheme.cobalt),
                          SizedBox(width: 6),
                          Text(
                            'مطابقة الرسوم الجمركية: التقديري (Estimator) vs الفعلي (Nafeza)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.charcoal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('التقديري السابق (Estimator)', style: TextStyle(fontSize: 10.5, color: Colors.black54)),
                                  const SizedBox(height: 2),
                                  Text('${estimatedVal.toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('الفعلي المطلوب من نافذة', style: TextStyle(fontSize: 10.5, color: Colors.black54)),
                                  const SizedBox(height: 2),
                                  Text('${actualVal.toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (varianceVal.abs() < 10 ? Colors.green.shade50 : (varianceVal > 0 ? Colors.orange.shade50 : Colors.blue.shade50)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: (varianceVal.abs() < 10 ? Colors.green.shade200 : Colors.orange.shade200)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('الفارق (Variance Δ)', style: TextStyle(fontSize: 10.5, color: Colors.black54)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${varianceVal >= 0 ? "+" : ""}${varianceVal.toStringAsFixed(2)} (${variancePct.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: varianceVal.abs() < 10 ? AppTheme.emerald : (varianceVal > 0 ? AppTheme.orange : AppTheme.cobalt),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _actualDutyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'إجمالي إذن السداد الفعلي من نافذة (EGP) *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال المبلغ الفعلي' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _estimatedDutyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'التقديري من الحاسبة (EGP)', border: OutlineInputBorder()),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rcptCtrl,
                  decoration: const InputDecoration(labelText: 'رقم إيصال السداد البنكي الرسمي *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رقم الإيصال البنكي' : null,
                ),
                const SizedBox(height: 12),
                SearchableDropdownField<String>(
                  value: banks.any((b) => b.partnerName == _bankCtrl.text) ? _bankCtrl.text : (banks.isNotEmpty ? banks.first.partnerName : _bankCtrl.text),
                  labelText: 'اسم البنك المنفذ للسداد *',
                  searchHintText: 'ابحث عن البنك المنفذ...',
                  items: banks.isNotEmpty
                      ? banks.map((b) => SearchableDropdownItem<String>(value: b.partnerName, label: b.partnerName, subtitle: b.partnerType)).toList()
                      : [SearchableDropdownItem<String>(value: _bankCtrl.text, label: _bankCtrl.text)],
                  onChanged: (val) {
                    if (val != null) setState(() => _bankCtrl.text = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات وتفسير فروقات السداد (إن وجدت)',
                    hintText: 'تغير سعر الدولار الجمركي، مصاريف معمل إضافية...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
          icon: _isLoading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          label: const Text('اعتماد السداد وتثبيت التكاليف للـ Landed Cost ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final payload = {
                        'bank_receipt_no': _rcptCtrl.text.trim(),
                        'paying_bank_name': _bankCtrl.text.trim(),
                        'payment_date': DateTime.now().toIso8601String(),
                        'actual_duty_total': double.tryParse(_actualDutyCtrl.text.trim()) ?? 0.0,
                        'estimated_duty_total': double.tryParse(_estimatedDutyCtrl.text.trim()) ?? 0.0,
                        'duty_variance_reason': _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
                        'nafeza_assessment_json': _nafezaExtractedJson,
                      };
                      await ref.read(customsClearanceProvider.notifier).submitDutyPayment(widget.record.customsClearanceId, payload);
                      nav.pop();
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('خطأ في السداد: $e'), backgroundColor: AppTheme.crimson));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
        ),
      ],
    );
  }
}

class _FinalReleaseDialog extends ConsumerStatefulWidget {
  final CustomsClearanceModel record;
  const _FinalReleaseDialog({required this.record});

  @override
  ConsumerState<_FinalReleaseDialog> createState() => _FinalReleaseDialogState();
}

class _FinalReleaseDialogState extends ConsumerState<_FinalReleaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _permitCtrl = TextEditingController();
  final TextEditingController _demurrageCtrl = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إصدار الإفراج الجمركي النهائي (${widget.record.clearanceCode})'),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _permitCtrl,
                decoration: const InputDecoration(labelText: 'رقم تصريح / إذن الإفراج النهائي *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رقم تصريح الإفراج' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _demurrageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رسوم الأرضيات والحراسات (EGP)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final payload = {
                        'release_permit_no': _permitCtrl.text.trim(),
                        'release_date': DateTime.now().toIso8601String(),
                        'demurrage_storage_fees': double.tryParse(_demurrageCtrl.text.trim()) ?? 0.0,
                        'dispatch_authorized': true,
                      };
                      await ref.read(customsClearanceProvider.notifier).completeRelease(widget.record.customsClearanceId, payload);
                      nav.pop();
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('خطأ في إتمام الإفراج: $e'), backgroundColor: AppTheme.crimson));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('إصدار الإفراج وتصريح النقل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
