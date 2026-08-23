import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/customs_clearance_model.dart';
import '../providers/customs_clearance_provider.dart';

class CustomsClearanceScreen extends ConsumerStatefulWidget {
  final int initialSubTab;
  final int? initialImportFileId;

  const CustomsClearanceScreen({
    super.key,
    this.initialSubTab = 0,
    this.initialImportFileId,
  });

  @override
  ConsumerState<CustomsClearanceScreen> createState() => _CustomsClearanceScreenState();
}

class _CustomsClearanceScreenState extends ConsumerState<CustomsClearanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';
  int _selectedTab = 0;

  // Local state for sample drawing items & discrepancy protocols
  final List<Map<String, dynamic>> _drawnSamples = [
    {
      'sample_id': 'SMP-2026-001',
      'authority': 'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)',
      'drawing_date': '2026-08-20',
      'receipt_no': 'REC-GOEIC-9921',
      'test_type': 'مطابقة المواصفات القياسية والفيزيائية',
      'status': 'PASSED',
      'notes': 'العينات مطابقة للمواصفة القياسية المصرية ES:1234',
    },
    {
      'sample_id': 'SMP-2026-002',
      'authority': 'الهيئة القومية لسلامة الغذاء (NFSA)',
      'drawing_date': '2026-08-21',
      'receipt_no': 'REC-NFSA-8834',
      'test_type': 'فحص ميكروبيولوجي ومعادن ثقيلة',
      'status': 'PENDING',
      'notes': 'قيد الفحص المعملي المركزي - مهلة 48 ساعة',
    },
    {
      'sample_id': 'SMP-2026-003',
      'authority': 'مصلحة الكيمياء والأشعة',
      'drawing_date': '2026-08-22',
      'receipt_no': 'REC-CHEM-5512',
      'test_type': 'فحص المكونات الكيميائية ونسبة النقاء',
      'status': 'PASSED',
      'notes': 'تقرير رقم 5512: النتيجة إيجابية ومطابقة تماماً',
    },
  ];

  final List<Map<String, dynamic>> _discrepancyProtocols = [
    {
      'protocol_no': 'DMG-ALX-2026-001',
      'declaration_no': '46-ALX-IMP-2026-001',
      'container_no': 'MSCU9812450',
      'damage_type': 'كسر وبلل بكرتونة العبوة الخارجية',
      'damaged_qty': '12 كرتونة',
      'estimated_loss_egp': 14500.0,
      'responsible_party': 'الناقل البحري (Shipping Line)',
      'insurance_claim_status': 'CLAIM_SUBMITTED',
      'date': '2026-08-22',
      'notes': 'تم تحرير محضر مشترك بحضور مندوب التوكيل الملاحي وخبير المعاينة',
    },
    {
      'protocol_no': 'SHT-ALX-2026-002',
      'declaration_no': '46-ALX-IMP-2026-002',
      'container_no': 'MEDU4412998',
      'damage_type': 'عجز بالوزن عند فتح الحاوية (Shortage)',
      'damaged_qty': 'عجز 45 كجم',
      'estimated_loss_egp': 8200.0,
      'responsible_party': 'الشاحن الأجنبي (Supplier)',
      'insurance_claim_status': 'APPROVED',
      'date': '2026-08-21',
      'notes': 'تم تسوية الفارق بخصم القيمة من الرصيد الدائن للمورد',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialSubTab;
    Future.microtask(() {
      _refreshData();
    });
  }

  @override
  void didUpdateWidget(covariant CustomsClearanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubTab != oldWidget.initialSubTab) {
      setState(() => _selectedTab = widget.initialSubTab);
    }
  }

  void _refreshData() {
    ref.read(customsClearanceProvider.notifier).fetchRecords();
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(partnersProvider.notifier).fetchPartners();
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

  void _showAddSampleDialog() {
    final formKey = GlobalKey<FormState>();
    final authCtrl = TextEditingController(text: 'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)');
    final receiptCtrl = TextEditingController(text: 'REC-LAB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final testTypeCtrl = TextEditingController(text: 'مطابقة المواصفات القياسية وسحب عينات');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science, color: AppTheme.cobalt),
            SizedBox(width: 8),
            Text('تسجيل سحب عينة معملية جديدة'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: authCtrl,
                  decoration: const InputDecoration(labelText: 'الجهة الرقابية / المعمل *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: receiptCtrl,
                  decoration: const InputDecoration(labelText: 'رقم إيصال السحب *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: testTypeCtrl,
                  decoration: const InputDecoration(labelText: 'نوع التحليل المطلوب *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'ملاحظات الكشاف والمعمل', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _drawnSamples.insert(0, {
                    'sample_id': 'SMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    'authority': authCtrl.text.trim(),
                    'drawing_date': DateTime.now().toString().substring(0, 10),
                    'receipt_no': receiptCtrl.text.trim(),
                    'test_type': testTypeCtrl.text.trim(),
                    'status': 'PENDING',
                    'notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : 'قيد الفحص المعملي',
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل سحب العينة المعملية بنجاح'), backgroundColor: AppTheme.emerald),
                );
              }
            },
            child: const Text('حفظ العينة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDamageDialog() {
    final formKey = GlobalKey<FormState>();
    final declCtrl = TextEditingController(text: '46-ALX-IMP-2026-');
    final containerCtrl = TextEditingController();
    final damageTypeCtrl = TextEditingController(text: 'كسر وبلل بالطرود');
    final damagedQtyCtrl = TextEditingController(text: '1 طرد');
    final lossCtrl = TextEditingController(text: '5000');
    final partyCtrl = TextEditingController(text: 'الناقل البحري (Shipping Line)');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: AppTheme.crimson),
            SizedBox(width: 8),
            Text('تحرير محضر تلف / فاقد جمركي ومعاينة مشتركة'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: declCtrl,
                        decoration: const InputDecoration(labelText: 'رقم الإقرار (46 ك.م) *', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: containerCtrl,
                        decoration: const InputDecoration(labelText: 'رقم الحاوية *', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: damageTypeCtrl,
                        decoration: const InputDecoration(labelText: 'طبيعة الضرر / التلف *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: damagedQtyCtrl,
                        decoration: const InputDecoration(labelText: 'الكمية التالفة *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: lossCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الخسارة المقدرة (جنيه) *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: partyCtrl,
                        decoration: const InputDecoration(labelText: 'الجهة المسؤولة عن الضرر *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'تفاصيل المحضر المشترك والمعاينة', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _discrepancyProtocols.insert(0, {
                    'protocol_no': 'DMG-ALX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    'declaration_no': declCtrl.text.trim(),
                    'container_no': containerCtrl.text.trim(),
                    'damage_type': damageTypeCtrl.text.trim(),
                    'damaged_qty': damagedQtyCtrl.text.trim(),
                    'estimated_loss_egp': double.tryParse(lossCtrl.text.trim()) ?? 0.0,
                    'responsible_party': partyCtrl.text.trim(),
                    'insurance_claim_status': 'CLAIM_SUBMITTED',
                    'date': DateTime.now().toString().substring(0, 10),
                    'notes': notesCtrl.text.trim(),
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحرير وحفظ محضر المعاينة المشتركة بنجاح'), backgroundColor: AppTheme.emerald),
                );
              }
            },
            child: const Text('حفظ المحضر', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clearanceAsync = ref.watch(customsClearanceProvider);

    return VerticalStageScaffold(
      stageCode: 'PHASE-07',
      titleAr: 'الميناء والتخليص الجمركي والمعاينة والمطابقة',
      titleEn: 'Port Operations & Customs Clearance Hub',
      headerIcon: Icons.gavel_rounded,
      headerColor: Colors.purple,
      selectedIndex: _selectedTab,
      onTabSelected: (idx) => setState(() => _selectedTab = idx),
      tabs: const [
        VerticalNavTabItem(
          icon: Icons.fact_check_outlined,
          titleAr: 'متابعة الكشف والتثمين والتفتيش الجمركي',
          titleEn: 'Customs Clearance Follow-up',
        ),
        VerticalNavTabItem(
          icon: Icons.science_outlined,
          titleAr: 'سحب العينات وتحديد عجز البضائع',
          titleEn: 'Drawing Samples & Shortage Tracking',
        ),
        VerticalNavTabItem(
          icon: Icons.report_problem_outlined,
          titleAr: 'إثبات الفاقد والتلف الجمركي ومحاضر النقص',
          titleEn: 'Discrepancy & Damage Registry',
        ),
        VerticalNavTabItem(
          icon: Icons.receipt_long_outlined,
          titleAr: 'سداد الرسوم والضرائب الجمركية النهائية',
          titleEn: 'Final Customs Duty Payment & Release',
        ),
      ],
      body: clearanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('خطأ في جلب بيانات التخليص الجمركي: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (records) {
          switch (_selectedTab) {
            case 0:
              return _buildClearanceFollowUpView(records);
            case 1:
              return _buildDrawingSamplesAndShortageView(records);
            case 2:
              return _buildDiscrepancyAndDamageView(records);
            case 3:
              return _buildFinalDutyPaymentView(records);
            default:
              return _buildClearanceFollowUpView(records);
          }
        },
      ),
    );
  }

  // ===========================================================================
  // SUB-VIEW 0: CUSTOMS CLEARANCE FOLLOW-UP (متابعة الكشف والتثمين)
  // ===========================================================================
  Widget _buildClearanceFollowUpView(List<CustomsClearanceModel> records) {
    final filtered = records.where((r) {
      if (_selectedStatusFilter != 'All' && r.status != _selectedStatusFilter) return false;
      if (_searchController.text.trim().isEmpty) return true;
      final q = _searchController.text.trim().toLowerCase();
      return r.clearanceCode.toLowerCase().contains(q) ||
          (r.declaration46No ?? '').toLowerCase().contains(q) ||
          (r.deliveryOrderNumber ?? '').toLowerCase().contains(q) ||
          r.customsOfficeName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Filter & Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'بحث بكود التخليص، رقم 46 ك.م، إذن التسليم...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
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
                    if (val != null) setState(() => _selectedStatusFilter = val);
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
                  onPressed: _refreshData,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // List of Cards
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('لا توجد سجلات تخليص جمركي مطابقة للبحث حالياً.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final record = filtered[index];
                    return _buildClearanceCard(record);
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SUB-VIEW 1: DRAWING SAMPLES & SHORTAGE TRACKING (سحب العينات وعجز البضائع)
  // ===========================================================================
  Widget _buildDrawingSamplesAndShortageView(List<CustomsClearanceModel> records) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.science, color: AppTheme.cobalt, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'منظومة سحب العينات وتتبع الفحص المعملي وتحديد عجز البضائع (Drawing Samples & Shortage)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'توثيق إيصالات المعامل الرقابية (GOEIC, NFSA, Chemistry, Radiation) ومتابعة المهلة القانونية لنتائج التحليل ومطابقة الأوزان والطرود الفعلية.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('تسجيل سحب عينة'),
                  onPressed: _showAddSampleDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Drawn Samples Table
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.biotech, color: AppTheme.cobalt, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('سجل العينات المسحوبة للفحص والتحليل المعملي (Laboratory Drawn Samples)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const Divider(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('كود العينة', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الجهة الرقابية / المعمل', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('تاريخ السحب', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('رقم الإيصال', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('نوع الفحص والتحليل', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('نتيجة الفحص', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _drawnSamples.map((s) {
                        final isPassed = s['status'] == 'PASSED';
                        return DataRow(cells: [
                          DataCell(Text(s['sample_id'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                          DataCell(Text(s['authority'], style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(s['drawing_date'])),
                          DataCell(Text(s['receipt_no'], style: const TextStyle(fontFamily: 'monospace'))),
                          DataCell(Text(s['test_type'])),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isPassed ? Colors.green : Colors.orange).shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: (isPassed ? Colors.green : Colors.orange).shade300),
                              ),
                              child: Text(
                                isPassed ? 'مطابقة للمواصفات ✅' : 'قيد الفحص المعملي ⏳',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPassed ? Colors.green.shade900 : Colors.orange.shade900),
                              ),
                            ),
                          ),
                          DataCell(Text(s['notes'] ?? '-')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUB-VIEW 2: DISCREPANCY & DAMAGE REGISTRY (إثبات الفاقد والتلف الجمركي)
  // ===========================================================================
  Widget _buildDiscrepancyAndDamageView(List<CustomsClearanceModel> records) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.report_problem, color: AppTheme.crimson, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سجل إثبات الفاقد والتلف الجمركي ومحاضر المعاينة المشتركة (Discrepancy & Damage Protocols)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'توثيق محاضر كسر الحاويات والبلل والنقص مع مندوب التوكيل الملاحي والجمارك والتأمين البحري لتحصيل التعويضات.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('تحرير محضر مشترك'),
                  onPressed: _showAddDamageDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Discrepancy Table
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: AppTheme.crimson, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('محاضر المعاينة المشتركة والمطالبات التأمينية (Joint Inspection Protocols)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const Divider(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('رقم المحضر', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الإقرار الجمركي (46 ك.م)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('رقم الحاوية', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('طبيعة الضرر / التلف', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الكمية التالفة', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الخسارة المقدرة (جنيه)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الجهة المتسببة', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('حالة المطالبة', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _discrepancyProtocols.map((p) {
                        return DataRow(cells: [
                          DataCell(Text(p['protocol_no'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson))),
                          DataCell(Text(p['declaration_no'])),
                          DataCell(Text(p['container_no'], style: const TextStyle(fontFamily: 'monospace'))),
                          DataCell(Text(p['damage_type'], style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(p['damaged_qty'])),
                          DataCell(Text('${(p['estimated_loss_egp'] as num).toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.crimson))),
                          DataCell(Text(p['responsible_party'])),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade300),
                              ),
                              child: Text(
                                p['insurance_claim_status'] == 'APPROVED' ? 'معتمدة للتعويض ✅' : 'مقدمة لشركة التأمين 📋',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                              ),
                            ),
                          ),
                          DataCell(Text(p['date'])),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUB-VIEW 3: FINAL CUSTOMS PAYMENT & RELEASE (سداد الرسوم والإفراج النهائي)
  // ===========================================================================
  Widget _buildFinalDutyPaymentView(List<CustomsClearanceModel> records) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_long, color: AppTheme.emerald, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'منظومة سداد الرسوم والضرائب الجمركية وإذن الإفراج النهائي (Final Duty Payment & Gate Pass)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'مطابقة إذن سداد نافذة وتوثيق إيصالات السداد البنكي وحفظ الفروق المالية واعتماد إذن الإفراج وتصريح خروج البوابة.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Duty Ledger & Payment Actions Table
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payments_outlined, color: AppTheme.emerald, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('سجل أذون سداد نافذة المعتمدة ومطابقة الرسوم (Nafeza Duty Assessment & Ledger)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const Divider(height: 20),
                  if (records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('لا توجد مطالبات سداد مسجلة حالياً.')),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('كود التخليص', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الإقرار (46 ك.م)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الجمرك المختص', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الرسوم الفعلية (نافذة)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الرسوم التقديرية', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('الفارق (Variance)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('حالة السداد', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('إجراءات السداد والإفراج', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: records.map((r) {
                          final isPaid = r.paymentStatus == 'Paid & Verified';
                          return DataRow(cells: [
                            DataCell(Text(r.clearanceCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt))),
                            DataCell(Text(r.declaration46No ?? '-')),
                            DataCell(Text(r.customsOfficeName)),
                            DataCell(Text('${(r.actualDutyTotal > 0 ? r.actualDutyTotal : r.totalDutyPayable).toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald))),
                            DataCell(Text('${r.estimatedDutyTotal.toStringAsFixed(2)} EGP')),
                            DataCell(Text('${r.dutyVarianceAmount >= 0 ? "+" : ""}${r.dutyVarianceAmount.toStringAsFixed(2)} EGP (${r.dutyVariancePercentage}%)', style: TextStyle(fontWeight: FontWeight.bold, color: r.dutyVarianceAmount.abs() > 500 ? AppTheme.orange : Colors.grey.shade700))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isPaid ? Colors.green : Colors.orange).shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: (isPaid ? Colors.green : Colors.orange).shade300),
                                ),
                                child: Text(
                                  isPaid ? 'تم السداد والتحقق ✅' : 'مطلوب السداد ⚠️',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPaid ? Colors.green.shade900 : Colors.orange.shade900),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPaid ? Colors.indigo : AppTheme.emerald,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: Icon(isPaid ? Icons.verified : Icons.payment, size: 14),
                                    label: Text(isPaid ? 'تفاصيل السداد' : 'سداد ومطابقة', style: const TextStyle(fontSize: 11)),
                                    onPressed: () => _showDutyPaymentDialog(r),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.cobalt,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.assignment_turned_in, size: 14),
                                    label: const Text('الإفراج النهائي', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _showFinalReleaseDialog(r),
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                      if (record.declaration46No != null && record.declaration46No!.isNotEmpty)
                        Text('46 ك.م: ${record.declaration46No}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt)),
                      if (record.deliveryOrderNumber != null && record.deliveryOrderNumber!.isNotEmpty)
                        Text('إذن التسليم: ${record.deliveryOrderNumber}', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                    ],
                  ),
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
                        decoration: const InputDecoration(labelText: 'ضريبة الوارد', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _vatCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'القيمة المضافة (VAT)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _scheduleTaxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ضريبة الجدول', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _whtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'أ.ت.ص (WHT 1%)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _labFeesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'رسوم معملية وخدمات', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _estimatedDutyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'التقديري من النظام', border: OutlineInputBorder()),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isLoading = true);

                  final duty = double.tryParse(_dutyCtrl.text) ?? 0.0;
                  final vat = double.tryParse(_vatCtrl.text) ?? 0.0;
                  final sched = double.tryParse(_scheduleTaxCtrl.text) ?? 0.0;
                  final wht = double.tryParse(_whtCtrl.text) ?? 0.0;
                  final lab = double.tryParse(_labFeesCtrl.text) ?? 0.0;
                  final total = duty + vat + sched + wht + lab;

                  final payload = {
                    'import_file_id': _selectedImportFileId,
                    'declaration_46_no': _decl46Ctrl.text.trim().isNotEmpty ? _decl46Ctrl.text.trim() : null,
                    'customs_office_name': _officeCtrl.text.trim(),
                    'channel_type': _channelType,
                    'delivery_order_number': _doNumberCtrl.text.trim().isNotEmpty ? _doNumberCtrl.text.trim() : null,
                    'free_days_allowed': int.tryParse(_freeDaysCtrl.text) ?? 14,
                    'import_duty_amount': duty,
                    'vat_amount': vat,
                    'schedule_tax_amount': sched,
                    'wht_amount': wht,
                    'lab_service_fees': lab,
                    'total_duty_payable': total,
                    'estimated_duty_total': double.tryParse(_estimatedDutyCtrl.text) ?? 0.0,
                  };

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await ref.read(customsClearanceProvider.notifier).createRecord(payload);
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('✔ تم حفظ معاملة التخليص بنجاح'), backgroundColor: AppTheme.emerald),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppTheme.crimson),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('حفظ المعاملة', style: TextStyle(color: Colors.white)),
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
  final TextEditingController _receiptCtrl = TextEditingController();
  final TextEditingController _actualPaidCtrl = TextEditingController();
  final TextEditingController _varianceReasonCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _actualPaidCtrl.text = (widget.record.actualDutyTotal > 0 ? widget.record.actualDutyTotal : widget.record.totalDutyPayable).toString();
    _receiptCtrl.text = widget.record.bankReceiptNo ?? '';
    _varianceReasonCtrl.text = widget.record.dutyVarianceReason ?? '';
  }

  void _applyExtractedPayment(Map<String, dynamic> ext) {
    setState(() {
      if (ext['receipt_number'] != null) _receiptCtrl.text = ext['receipt_number'].toString();
      if (ext['actual_paid_amount'] != null) _actualPaidCtrl.text = ext['actual_paid_amount'].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final est = widget.record.estimatedDutyTotal;
    final act = double.tryParse(_actualPaidCtrl.text) ?? widget.record.totalDutyPayable;
    final diff = act - est;
    final diffPercent = est > 0 ? ((diff / est) * 100).toStringAsFixed(1) : '0.0';

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('سداد ومطابقة رسوم الجمارك (${widget.record.clearanceCode})'),
          SmartUploadButton(
            module: SmartUploadModule.customsClearance,
            compact: true,
            label: 'استخلاص إيصال السداد',
            onDataExtracted: (res) => _applyExtractedPayment(res.extractedFields),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Variance Comparison Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (diff.abs() > 500 ? AppTheme.orange : AppTheme.emerald).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: diff.abs() > 500 ? AppTheme.orange : AppTheme.emerald),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الرسوم التقديرية (Estimator): ${est.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('المطلوب بطلب سداد نافذة: ${act.toStringAsFixed(2)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('فارق التباين الضريبي (Variance):', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(2)} EGP ($diffPercent%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: diff.abs() > 500 ? AppTheme.crimson : AppTheme.emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _actualPaidCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'إجمالي المبلغ الفعلي المسدد (EGP) *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _receiptCtrl,
                decoration: const InputDecoration(labelText: 'رقم إيصال السداد البنكي / التحويل *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _varianceReasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'أسباب الفارق إن وجدت (تسويات معملية، بنود جديدة...)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isLoading = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await ref.read(customsClearanceProvider.notifier).submitDutyPayment(
                          widget.record.customsClearanceId,
                          {
                            'bank_receipt_no': _receiptCtrl.text.trim(),
                            'actual_duty_total': double.tryParse(_actualPaidCtrl.text) ?? widget.record.totalDutyPayable,
                            'duty_variance_reason': _varianceReasonCtrl.text.trim().isNotEmpty ? _varianceReasonCtrl.text.trim() : null,
                          },
                        );
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('✔ تم توثيق سداد الرسوم الجمركية ومطابقة نافذة بنجاح'), backgroundColor: AppTheme.emerald),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('خطأ أثناء توثيق السداد: $e'), backgroundColor: AppTheme.crimson),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('تأكيد السداد والترحيل', style: TextStyle(color: Colors.white)),
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
  final TextEditingController _releaseNoCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _releaseNoCtrl.text = widget.record.releasePermitNo ?? 'REL-${widget.record.clearanceCode}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.verified_user, color: Colors.indigo),
          SizedBox(width: 8),
          Text('إصدار تصريح الإفراج الجمركي النهائي'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('سيتم تغيير حالة المعاملة إلى (Final Release Granted) وجاهزية خروج الحاويات من الميناء.'),
            const SizedBox(height: 14),
            TextFormField(
              controller: _releaseNoCtrl,
              decoration: const InputDecoration(labelText: 'رقم تصريح الإفراج الجمركي / البوابة *', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await ref.read(customsClearanceProvider.notifier).completeRelease(
                          widget.record.customsClearanceId,
                          {
                            'release_permit_no': _releaseNoCtrl.text.trim(),
                          },
                        );
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('✔ تم منح الإفراج الجمركي النهائي بنجاح!'), backgroundColor: AppTheme.emerald),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('خطأ أثناء منح الإفراج: $e'), backgroundColor: AppTheme.crimson),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('اعتماد الإفراج النهائي', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
