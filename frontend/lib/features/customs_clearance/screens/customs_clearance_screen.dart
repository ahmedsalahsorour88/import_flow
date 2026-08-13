import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
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
    final recordsState = ref.watch(customsClearanceProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.gavel, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('التخليص الجمركي والمعاينة الإجبارية (Phase 7 - Customs Clearance & Release)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          const BackToDashboardButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(customsClearanceProvider.notifier).fetchRecords(),
          ),
          const SizedBox(width: 10),
        ],

      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar Bar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add_task, color: Colors.white),
                      label: const Text('تسجيل معاملة تخليص ومعاينة جمركية (New Customs Entry)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'بحث بكود التخليص أو الإقرار 46...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          ref.read(customsClearanceProvider.notifier).fetchRecords(search: val, status: _selectedStatusFilter);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 220,
                      child: SearchableDropdownField<String>(
                        value: _selectedStatusFilter,
                        labelText: 'تصفية حسب الحالة',
                        searchHintText: 'ابحث عن الحالة...',
                        items: const [
                          SearchableDropdownItem(value: 'All', label: 'جميع الحالات'),
                          SearchableDropdownItem(value: 'Inspection In Progress', label: 'Inspection In Progress (المعاينة جارية)'),
                          SearchableDropdownItem(value: 'Duty Paid', label: 'Duty Paid (تم سداد الرسوم)'),
                          SearchableDropdownItem(value: 'Final Release Granted', label: 'Final Release Granted (مُفرج نهائياً)'),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatusFilter = val);
                            ref.read(customsClearanceProvider.notifier).fetchRecords(search: _searchController.text, status: val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content List Area
            Expanded(
              child: recordsState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('خطأ في جلب بيانات التخليص: $err', style: const TextStyle(color: AppTheme.crimson))),
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(child: Text('لا توجد معاملات تخليص جمركي مسجلة حالياً.'));
                  }

                  return ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, idx) {
                      final r = records[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: AppTheme.cobalt.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(r.clearanceCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('الإقرار الجمركي 46: ${r.declaration46No ?? "غير محدد"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 12),
                                  _buildChannelBadge(r.channelType),
                                  const Spacer(),
                                  _buildStatusBadge(r.status),
                                ],
                              ),
                              const Divider(height: 20),

                              // Inspection & Office Details
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('المقر والجمرك المختص: ${r.customsOfficeName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text('الجهات الرقابية المشاركة: ${r.regulatoryBodies.isNotEmpty ? r.regulatoryBodies.join(", ") : "لا توجد جهات إضافية"}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('حالة الفحص المعملي: ${r.sampleTestStatus}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text('المسئول المتابع: ${r.owner}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Duty Payment & Final Release Status Box
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.4), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('إجمالي المستحقات الجمركية: ${r.totalDutyPayable.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 13)),
                                          Text('تفاصيل: جمرك ${r.importDutyAmount.toStringAsFixed(0)} | VAT ${r.vatAmount.toStringAsFixed(0)} | الجدول ${r.scheduleTaxAmount.toStringAsFixed(0)} | أرباح تجارية ${r.whtAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('حالة السداد: ${r.paymentStatus}', style: TextStyle(fontWeight: FontWeight.bold, color: r.paymentStatus == 'Paid & Verified' ? AppTheme.emerald : Colors.orange.shade900)),
                                        if (r.bankReceiptNo != null) Text('إيصال البنك: ${r.bankReceiptNo}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.restore_from_trash, color: AppTheme.emerald),
                                      tooltip: 'استعادة السجل',
                                      onPressed: () async {
                                        await ref.read(customsClearanceProvider.notifier).restoreRecord(r.customsClearanceId);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('✅ تم استعادة سجل التخليص الجمركي ${r.clearanceCode} بنجاح'), backgroundColor: AppTheme.emerald),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (r.paymentStatus != 'Paid & Verified') ...[
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                                      icon: const Icon(Icons.receipt_long, size: 16, color: Colors.white),
                                      label: const Text('تسجيل وتوثيق سداد الرسوم الجمركية (BP-031)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _showDutyPaymentDialog(r),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (r.status != 'Final Release Granted') ...[
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                      icon: const Icon(Icons.verified, size: 16, color: Colors.white),
                                      label: const Text('إصدار الإفراج الجمركي النهائي وتصريح الخروج (BP-032)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _showFinalReleaseDialog(r),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.crimson),
                                    tooltip: 'حذف لطفياً',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('حذف معاملة التخليص'),
                                          content: const Text('هل أنت تأكد من نقل هذه المعاملة للمحذوفات؟'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف', style: TextStyle(color: AppTheme.crimson))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        ref.read(customsClearanceProvider.notifier).softDeleteRecord(r.customsClearanceId);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
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

  Widget _buildChannelBadge(String channel) {
    Color bg = Colors.red.shade100;
    Color fg = Colors.red.shade900;
    if (channel == 'Green Channel') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    } else if (channel == 'Yellow Channel') {
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(channel, style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 11)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.cobalt;
    if (status == 'Final Release Granted') color = AppTheme.emerald;
    if (status == 'Duty Paid') color = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
      child: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
    );
  }
}

// -----------------------------------------------------------------------------
// FORM DIALOGS
// -----------------------------------------------------------------------------

class _CustomsClearanceFormDialog extends ConsumerStatefulWidget {
  final CustomsClearanceModel? recordToEdit;
  const _CustomsClearanceFormDialog({this.recordToEdit});

  @override
  ConsumerState<_CustomsClearanceFormDialog> createState() => _CustomsClearanceFormDialogState();
}

class _CustomsClearanceFormDialogState extends ConsumerState<_CustomsClearanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedImportFileId;
  late TextEditingController _decl46Ctrl;
  late TextEditingController _officeCtrl;
  String _channelType = 'Red Channel';
  late TextEditingController _dutyCtrl;
  late TextEditingController _vatCtrl;
  late TextEditingController _scheduleTaxCtrl;
  late TextEditingController _whtCtrl;
  late TextEditingController _labFeesCtrl;
  late TextEditingController _notesCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recordToEdit;
    _selectedImportFileId = r?.importFileId;
    _decl46Ctrl = TextEditingController(text: r?.declaration46No ?? '');
    _officeCtrl = TextEditingController(text: r?.customsOfficeName ?? 'Alexandria Port Customs');
    _channelType = r?.channelType ?? 'Red Channel';
    _dutyCtrl = TextEditingController(text: r?.importDutyAmount.toString() ?? '0');
    _vatCtrl = TextEditingController(text: r?.vatAmount.toString() ?? '0');
    _scheduleTaxCtrl = TextEditingController(text: r?.scheduleTaxAmount.toString() ?? '0');
    _whtCtrl = TextEditingController(text: r?.whtAmount.toString() ?? '0');
    _labFeesCtrl = TextEditingController(text: r?.labServiceFees.toString() ?? '0');
    _notesCtrl = TextEditingController(text: r?.notes ?? '');
  }

  @override
  void dispose() {
    _decl46Ctrl.dispose();
    _officeCtrl.dispose();
    _dutyCtrl.dispose();
    _vatCtrl.dispose();
    _scheduleTaxCtrl.dispose();
    _whtCtrl.dispose();
    _labFeesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return AlertDialog(
      title: Text(widget.recordToEdit == null ? 'تسجيل معاملة تخليص ومعاينة جديدة' : 'تعديل بيانات التخليص'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SearchableDropdownField<int?>(
                  value: _selectedImportFileId,
                  labelText: 'ملف الشحنة الاستيرادية *',
                  searchHintText: 'ابحث عن ملف الشحنة بالرقم أو اسم الشركة...',
                  items: importFiles
                      .map((f) => SearchableDropdownItem<int?>(
                            value: f.importFileId,
                            label: '[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}',
                            subtitle: f.companyName,
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedImportFileId = val),
                  validator: (v) => v == null ? 'يرجى اختيار ملف الشحنة' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _decl46Ctrl,
                        decoration: const InputDecoration(labelText: 'رقم الإقرار الجمركي 46 *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رقم الإقرار 46' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SearchableDropdownField<String>(
                        value: _channelType,
                        labelText: 'المسار الجمركي (Channel) *',
                        searchHintText: 'ابحث عن المسار الجمركي...',
                        items: const [
                          SearchableDropdownItem(value: 'Red Channel', label: 'Red Channel (مسار أحمر - معاينة كاملة)'),
                          SearchableDropdownItem(value: 'Green Channel', label: 'Green Channel (مسار أخضر - إفراج مباشر)'),
                          SearchableDropdownItem(value: 'Yellow Channel', label: 'Yellow Channel (مسار مستندي)'),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _channelType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _officeCtrl,
                  decoration: const InputDecoration(labelText: 'اسم الجمرك والدائرة الجمركية *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الجمرك' : null,
                ),
                const SizedBox(height: 14),

                // Duty Breakdown Fields
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('مطالبة الرسوم والضرائب الإجبارية الجمركية (Duty Breakdown):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.cobalt)),
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
                        decoration: const InputDecoration(labelText: 'ضريبة الجدول (Schedule Tax)', border: OutlineInputBorder()),
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
                        'customs_office_name': _officeCtrl.text.trim(),
                        'channel_type': _channelType,
                        'import_duty_amount': double.tryParse(_dutyCtrl.text.trim()) ?? 0.0,
                        'vat_amount': double.tryParse(_vatCtrl.text.trim()) ?? 0.0,
                        'schedule_tax_amount': double.tryParse(_scheduleTaxCtrl.text.trim()) ?? 0.0,
                        'wht_amount': double.tryParse(_whtCtrl.text.trim()) ?? 0.0,
                        'lab_service_fees': double.tryParse(_labFeesCtrl.text.trim()) ?? 0.0,
                      };

                      await ref.read(customsClearanceProvider.notifier).createRecord(payload);
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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final partners = ref.watch(partnersProvider).value ?? [];
    final banks = partners.where((p) => p.partnerType.contains('Bank') || p.partnerType.contains('Financial')).toList();

    return AlertDialog(
      title: Text('توثيق سداد الرسوم الجمركية (${widget.record.clearanceCode})'),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('المبلغ الإجمالي المطلوب سداده: ${widget.record.totalDutyPayable.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 15)),
              const SizedBox(height: 14),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
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
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('تأكيد السداد وتوثيقه', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      messenger.showSnackBar(SnackBar(content: Text('خطأ في الإفراج: $e'), backgroundColor: AppTheme.crimson));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('إصدار الإفراج وتخريج الشحنة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
