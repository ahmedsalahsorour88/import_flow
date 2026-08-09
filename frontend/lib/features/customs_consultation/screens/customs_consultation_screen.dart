import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
import '../models/customs_consultation_model.dart';
import '../providers/customs_consultation_provider.dart';

class CustomsConsultationScreen extends ConsumerStatefulWidget {
  const CustomsConsultationScreen({super.key});

  @override
  ConsumerState<CustomsConsultationScreen> createState() => _CustomsConsultationScreenState();
}

class _CustomsConsultationScreenState extends ConsumerState<CustomsConsultationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController(text: 'دراسة المراجعة الجمركية الأولية لخط إنتاج ومعدات الشحنة');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _estimatedDutiesController = TextEditingController(text: '0.0');

  int? _selectedBrokerId;
  String _selectedBrokerName = '';
  String? _brokerContactPerson;
  int? _selectedImportFileId;
  int? _selectedPoId;
  int? _selectedProjectId;

  final List<CustomsChecklistItemModel> _checklist = [];
  bool _isSaving = false;

  // History Tab Filter State
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeDefaultChecklist();
    Future.microtask(() {
      ref.read(customsConsultationsProvider.notifier).fetchConsultations();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _estimatedDutiesController.dispose();
    super.dispose();
  }

  void _initializeDefaultChecklist() {
    _checklist.clear();
    _checklist.addAll([
      CustomsChecklistItemModel(
        documentType: 'Proforma Invoice (الفاتورة المبدئية)',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Supplier / Exporter',
        status: 'Approved',
        remarks: 'الفاتورة المبدئية معتمدة ومطابقة للبند الجمركي.',
      ),
      CustomsChecklistItemModel(
        documentType: 'Packing List (قائمة التعبئة والتغليف)',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Supplier / Exporter',
        status: 'Approved',
        remarks: 'محدثة بإجمالي الأوزان الأحجام والطرود.',
      ),
      CustomsChecklistItemModel(
        documentType: 'Certificate of Origin (شهادة المنشأ COO)',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Customs Broker',
        status: 'Pending',
        remarks: 'مطلوب توثيق السفيرة والغرفة التجارية.',
      ),
      CustomsChecklistItemModel(
        documentType: 'GOEIC Inspection (عرض هيئة الصادرات والواردات)',
        isRequired: true,
        isBlockingShipment: true,
        responsibleParty: 'Customs Broker',
        regulatoryAgency: 'GOEIC (هيئة الرقابة على الصادرات والواردات)',
        status: 'Pending',
        remarks: 'يتطلب فحص ظاهري وعينات المعمل فور الوصول.',
      ),
      CustomsChecklistItemModel(
        documentType: 'NTRA Telecommunications Approval (موافقة جهاز الاتصالات)',
        isRequired: false,
        isBlockingShipment: false,
        responsibleParty: 'Importer / Broker',
        regulatoryAgency: 'NTRA (الجهاز القومي لتنظيم الاتصالات)',
        status: 'Pending',
        remarks: 'تنطبق في حال وجود وحدات تحكم لاسلكية.',
      ),
    ]);
  }

  void _addChecklistItem() {
    showDialog(
      context: context,
      builder: (context) {
        final docController = TextEditingController();
        final hsController = TextEditingController();
        final agencyController = TextEditingController();
        final remarksController = TextEditingController();
        bool isReq = true;
        bool isBlock = true;
        String party = 'Customs Broker';
        String itemStatus = 'Pending';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة بند جديد في قائمة الفحص الجمركي (Customs Checklist)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: docController,
                        decoration: const InputDecoration(labelText: 'نوع المستند / الموافقة الجمركية *', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hsController,
                        decoration: const InputDecoration(labelText: 'بند التعريفة الجمركية المرتبط (HS Code)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: party,
                        decoration: const InputDecoration(labelText: 'الجهة المسؤولة عن المستند', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Customs Broker', child: Text('Customs Broker (المستخلص الجمركي)')),
                          DropdownMenuItem(value: 'Supplier / Exporter', child: Text('Supplier / Exporter (المورد الخارجي)')),
                          DropdownMenuItem(value: 'Importer Team', child: Text('Importer Team (فريق الاستيراد)')),
                          DropdownMenuItem(value: 'Freight Forwarder', child: Text('Freight Forwarder (شركة الشحن)')),
                        ],
                        onChanged: (v) => setDialogState(() => party = v!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: agencyController,
                        decoration: const InputDecoration(labelText: 'الجهة الرقابية / العرض الجمركي (GOEIC, NTRA, Food Safety...)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: itemStatus,
                        decoration: const InputDecoration(labelText: 'حالة المستند المبدئية', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Pending', child: Text('Pending (قيد الانتظار)')),
                          DropdownMenuItem(value: 'Received', child: Text('Received (تم الاستلام)')),
                          DropdownMenuItem(value: 'Verified', child: Text('Verified (تم التدقيق)')),
                          DropdownMenuItem(value: 'Approved', child: Text('Approved (معتمد جمركياً)')),
                          DropdownMenuItem(value: 'Rejected', child: Text('Rejected (مرفوض / يتطلب إجراء)')),
                        ],
                        onChanged: (v) => setDialogState(() => itemStatus = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: isReq,
                            onChanged: (v) => setDialogState(() => isReq = v!),
                          ),
                          const Text('مستند إجباري (Required)'),
                          const Spacer(),
                          Checkbox(
                            value: isBlock,
                            onChanged: (v) => setDialogState(() => isBlock = v!),
                          ),
                          const Text('يعطل الشحنة (Blocking Shipment)'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: remarksController,
                        decoration: const InputDecoration(labelText: 'ملاحظات المستخلص / المتطلبات', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                  onPressed: () {
                    if (docController.text.trim().isEmpty) return;
                    setState(() {
                      _checklist.add(CustomsChecklistItemModel(
                        documentType: docController.text.trim(),
                        hsCode: hsController.text.trim().isNotEmpty ? hsController.text.trim() : null,
                        isRequired: isReq,
                        isBlockingShipment: isBlock,
                        responsibleParty: party,
                        status: itemStatus,
                        regulatoryAgency: agencyController.text.trim().isNotEmpty ? agencyController.text.trim() : null,
                        remarks: remarksController.text.trim().isNotEmpty ? remarksController.text.trim() : null,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('إضافة البند', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveConsultation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrokerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى اختيار المستخلص الجمركي المعني (Customs Broker)'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_checklist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى إضافة بند واحد على الأقل في قائمة الفحص الجمركي'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'title': _titleController.text.trim(),
        'broker_id': _selectedBrokerId,
        'broker_name': _selectedBrokerName,
        'broker_contact_person': _brokerContactPerson,
        'import_file_id': _selectedImportFileId,
        'po_id': _selectedPoId,
        'project_id': _selectedProjectId,
        'estimated_duties_egp': double.tryParse(_estimatedDutiesController.text.trim()) ?? 0.0,
        'notes': _notesController.text.trim(),
        'checklist_items': _checklist.map((item) => item.toJson()).toList(),
      };

      final created = await ref.read(customsConsultationsProvider.notifier).createConsultation(payload);
      if (mounted && created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم حفظ دراسة الاستشارة الجمركية بنجاح! كود الدراسة: ${created.consultationCode}'), backgroundColor: AppTheme.emerald),
        );
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showConsultationDetailsDialog(CustomsConsultationModel session) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.verified_user, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Expanded(
                child: Text('تفاصيل الاستشارة الجمركية: ${session.consultationCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _buildStatusBadge(session.overallStatus),
            ],
          ),
          content: SizedBox(
            width: 750,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('العنوان: ${session.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('المستخلص الجمركي: ${session.brokerName} ${session.brokerContactPerson != null ? "(${session.brokerContactPerson})" : ""}'),
                        const SizedBox(height: 6),
                        Text('الرسوم الجمركية والضرائب التقديرية: ${session.estimatedDutiesEgp.toStringAsFixed(2)} EGP'),
                        if (session.notes != null && session.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('ملاحظات: ${session.notes}'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricBadge('نسبة الجاهزية الجمركية', '${session.readinessPercentage}%', Colors.blue),
                      const SizedBox(width: 8),
                      _buildMetricBadge('إجمالي المستندات', '${session.totalDocumentsCount}', Colors.grey),
                      const SizedBox(width: 8),
                      _buildMetricBadge('المستندات المعتمدة', '${session.approvedDocumentsCount}', Colors.green),
                      const SizedBox(width: 8),
                      _buildMetricBadge('عوائق شحن (Blocking)', '${session.blockingIssuesCount}', session.blockingIssuesCount > 0 ? Colors.red : Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('قائمة فحص المستندات والاشتراطات الجمركية (Checklist):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: AppTheme.charcoal.withOpacity(0.05)),
                        children: const [
                          Padding(padding: EdgeInsets.all(8.0), child: Text('نوع المستند / البند', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('الجهة المسؤولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('الحالة الجمركية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('ملاحظات المستخلص', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      ...session.checklistItems.map(
                        (item) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.documentType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  if (item.regulatoryAgency != null) Text('الجهة: ${item.regulatoryAgency}', style: const TextStyle(fontSize: 10, color: Colors.purple)),
                                ],
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text(item.responsibleParty, style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(8.0), child: _buildDocItemStatusBadge(item.status)),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text(item.remarks ?? '-', style: const TextStyle(fontSize: 11))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnersState = ref.watch(partnersProvider);
    final projectsState = ref.watch(projectsProvider);
    final poState = ref.watch(purchaseOrdersProvider);
    final consultationsState = ref.watch(customsConsultationsProvider);

    final partnersList = partnersState.value ?? [];
    final brokersList = partnersList.where((p) => p.partnerType.contains('Customs Broker') || p.partnerType.contains('Partner')).toList();
    final projectsList = projectsState.value ?? [];
    final poList = poState.purchaseOrders;

    final double approvedDocs = _checklist.where((c) => c.status == 'Approved').length.toDouble();
    final double totalDocs = _checklist.isNotEmpty ? _checklist.length.toDouble() : 1.0;
    final double liveReadinessPct = double.parse(((approvedDocs / totalDocs) * 100.0).toStringAsFixed(1));
    final int blockingCount = _checklist.where((c) => c.isBlockingShipment && c.status == 'Rejected').length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTheme.charcoal,
        title: const Row(
          children: [
            Icon(Icons.gavel, color: AppTheme.cobalt),
            SizedBox(width: 10),
            Text('الاستشارة الجمركية الأولية (BP-009 – Consult Customs Broker)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.cobalt,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.assignment_turned_in), text: 'Customs Workspace (مركز الاستشارة والفحص)'),
            Tab(icon: Icon(Icons.history), text: 'Saved Consultations Log (سجل الدراسات المحفوظة)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: CUSTOMS CONSULTATION WORKSPACE
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Metrics Bar
                  Row(
                    children: [
                      _buildMetricBadge('جاهزية الفحص الجمركي', '$liveReadinessPct%', Colors.blue),
                      const SizedBox(width: 12),
                      _buildMetricBadge('عدد البنود والمستندات', '${_checklist.length}', Colors.grey),
                      const SizedBox(width: 12),
                      _buildMetricBadge('المستندات المعتمدة', '${approvedDocs.toInt()}', Colors.green),
                      const SizedBox(width: 12),
                      _buildMetricBadge('عوائق التخليص (Blocking)', '$blockingCount', blockingCount > 0 ? Colors.red : Colors.green),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onPressed: _isSaving ? null : _saveConsultation,
                        icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                        label: const Text('حفظ دراسة الاستشارة الجمركية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Session Setup Header Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('بيانات الجلسة والمستخلص الجمركي المعني (Customs Broker)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(labelText: 'عنوان الاستشارة / موضوع الدراسة *', border: OutlineInputBorder()),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال عنوان الدراسة' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<int>(
                                  value: _selectedBrokerId,
                                  decoration: const InputDecoration(labelText: 'المستخلص الجمركي (Customs Broker) *', border: OutlineInputBorder()),
                                  items: brokersList.map((b) => DropdownMenuItem<int>(value: b.providerId, child: Text(b.partnerName))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final b = brokersList.firstWhere((element) => element.providerId == val);
                                      setState(() {
                                        _selectedBrokerId = val;
                                        _selectedBrokerName = b.partnerName;
                                        _brokerContactPerson = b.contactPerson;
                                      });
                                    }
                                  },
                                  validator: (v) => v == null ? 'مطلوب تحديد المستخلص' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int?>(
                                  value: _selectedImportFileId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'ملف الشحنة الاستيرادية (Import File)',
                                    prefixIcon: Icon(Icons.folder_special, color: AppTheme.cobalt),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('-- بدون ربط بملف شحنة --'),
                                    ),
                                    ...(ref.watch(importFilesProvider).value ?? []).map((f) => DropdownMenuItem<int?>(
                                          value: f.importFileId,
                                          child: Text('[${f.importFileCode}] ${f.customFileNumber ?? f.poNumber ?? "File #${f.importFileId}"}', overflow: TextOverflow.ellipsis),
                                        )),
                                  ],
                                  onChanged: (v) => setState(() => _selectedImportFileId = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int?>(
                                  value: _selectedPoId,
                                  decoration: const InputDecoration(labelText: 'ربط بأمر الشراء (Purchase Order - اختياري)', border: OutlineInputBorder()),
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text('بدون ربط (مستقل)')),
                                    ...poList.map((po) => DropdownMenuItem<int?>(value: po.poId, child: Text('${po.poNumber} - ${po.supplierName}'))),
                                  ],
                                  onChanged: (val) => setState(() => _selectedPoId = val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int?>(
                                  value: _selectedProjectId,
                                  decoration: const InputDecoration(labelText: 'ربط بالمشروع (Project - اختياري)', border: OutlineInputBorder()),
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text('بدون ربط مشروع')),
                                    ...projectsList.map((pj) => DropdownMenuItem<int?>(value: pj.projectId, child: Text('${pj.projectCode} - ${pj.projectName}'))),
                                  ],
                                  onChanged: (val) => setState(() => _selectedProjectId = val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _estimatedDutiesController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'تقدير الرسوم الجمركية والضرائب (EGP)', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Checklist Table & Controls
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('قائمة فحص واشتراطات المستندات الجمركية (Customs Checklist)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
                              const Spacer(),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                                onPressed: _addChecklistItem,
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text('إضافة بند جديد للفحص', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 10),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _checklist.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _checklist[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.documentType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          if (item.regulatoryAgency != null) Text('الجهة: ${item.regulatoryAgency}', style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButton<String>(
                                        value: item.responsibleParty,
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(value: 'Customs Broker', child: Text('Customs Broker', style: TextStyle(fontSize: 11))),
                                          DropdownMenuItem(value: 'Supplier / Exporter', child: Text('Supplier / Exporter', style: TextStyle(fontSize: 11))),
                                          DropdownMenuItem(value: 'Importer Team', child: Text('Importer Team', style: TextStyle(fontSize: 11))),
                                          DropdownMenuItem(value: 'Freight Forwarder', child: Text('Freight Forwarder', style: TextStyle(fontSize: 11))),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _checklist[index] = item.copyWith(responsibleParty: val);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButton<String>(
                                        value: item.status,
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(value: 'Pending', child: Text('Pending (انتظار)', style: TextStyle(fontSize: 11))),
                                          DropdownMenuItem(value: 'Received', child: Text('Received (مستلم)', style: TextStyle(fontSize: 11))),
                                          DropdownMenuItem(value: 'Verified', child: Text('Verified (مدقق)', style: TextStyle(fontSize: 11))),
                                          DropdownMenuItem(value: 'Approved', child: Text('Approved (معتمد)', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
                                          DropdownMenuItem(value: 'Rejected', child: Text('Rejected (مرفوض)', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _checklist[index] = item.copyWith(status: val);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(item.isBlockingShipment ? Icons.block : Icons.check_circle_outline, color: item.isBlockingShipment ? Colors.red : Colors.grey, size: 20),
                                      tooltip: item.isBlockingShipment ? 'بند يعطل الشحنة (Blocking)' : 'بند غير معطل',
                                      onPressed: () {
                                        setState(() {
                                          _checklist[index] = item.copyWith(isBlockingShipment: !item.isBlockingShipment);
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _checklist.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TAB 2: SAVED CONSULTATIONS HISTORY REGISTRY
          consultationsState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('❌ Error: $err')),
            data: (sessions) {
              final filtered = sessions.where((s) {
                final matchQuery = _searchQuery.isEmpty ||
                    s.consultationCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    s.brokerName.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchStatus = _statusFilter == 'All' || s.overallStatus == _statusFilter;
                return matchQuery && matchStatus;
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Search & Filter Header
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'البحث عن دراسة استشارة برقم السريال أو العنوان أو اسم المستخلص...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _statusFilter,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('جميع الحالات')),
                            DropdownMenuItem(value: 'Pending Review', child: Text('Pending Review')),
                            DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                            DropdownMenuItem(value: 'Action Required', child: Text('Action Required')),
                            DropdownMenuItem(value: 'Clearance Ready', child: Text('Clearance Ready')),
                            DropdownMenuItem(value: 'Blocked', child: Text('Blocked')),
                          ],
                          onChanged: (v) => setState(() => _statusFilter = v!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('لا توجد دراسات استشارة جمركية مطابقة للبحث.'))
                          : SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppTheme.charcoal.withOpacity(0.05)),
                                columns: const [
                                  DataColumn(label: Text('كود الدراسة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('ملف الشحنة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('عنوان الدراسة والموضوع', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('المستخلص الجمركي', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('نسبة الجاهزية', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الحالة العامة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: filtered.map((session) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(session.consultationCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.charcoal.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            session.importFileCode ?? (session.importFileId != null ? 'IMP-${session.importFileId}' : '-'),
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal, fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(session.title)),
                                      DataCell(Text(session.brokerName)),
                                      DataCell(Text('${session.readinessPercentage}%', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(_buildStatusBadge(session.overallStatus)),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility, color: AppTheme.cobalt),
                                              tooltip: 'عرض تفاصيل الفحص الجمركي',
                                              onPressed: () => _showConsultationDetailsDialog(session),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Clearance Ready') bg = Colors.green;
    if (status == 'Blocked') bg = Colors.red;
    if (status == 'Action Required') bg = Colors.orange;
    if (status == 'In Progress') bg = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildDocItemStatusBadge(String status) {
    Color bg = Colors.grey;
    if (status == 'Approved') bg = Colors.green;
    if (status == 'Rejected') bg = Colors.red;
    if (status == 'Verified') bg = Colors.blue;
    if (status == 'Received') bg = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
