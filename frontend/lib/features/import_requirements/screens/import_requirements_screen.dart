import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../customs_consultation/providers/customs_consultation_provider.dart';
import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/import_requirement_model.dart';
import '../providers/import_requirements_provider.dart';

Color _getStatusColor(String status) {
  switch (status) {
    case 'Obtained':
    case 'Completed':
    case 'Approved':
    case 'Cleared':
    case 'Confirmed':
    case 'تم الاستلام والتحقق':
    case 'تم الفحص واجتياز المطابقة':
    case 'تمت الموافقة والاعتماد':
    case 'معتمد ومصرح للشحن':
    case 'مؤكد ومصرح للشحن':
      return AppTheme.emerald;
    case 'Pending':
    case 'In Progress':
    case 'Applied':
    case 'Scheduled':
    case 'مطلوبة':
    case 'قيد الاستيفاء':
    case 'قيد الاستيفاء والتأكيد':
    case 'تم تقديم الطلب':
    case 'تم التكليف والتنسيق':
      return AppTheme.orange;
    case 'Rejected':
    case 'مرفوض':
    case 'مرفوضة':
      return AppTheme.crimson;
    case 'Waived':
    case 'تم الإعفاء':
      return AppTheme.cobalt;
    default:
      return Colors.grey.shade600;
  }
}

Color _getRiskLevelColor(String risk) {
  switch (risk) {
    case 'Low':
    case 'منخفض':
    case 'منخفض (Low)':
      return AppTheme.emerald;
    case 'Medium':
    case 'متوسط':
    case 'متوسط (Medium)':
      return AppTheme.orange;
    case 'High':
    case 'مرتفع':
    case 'مرتفع (High)':
      return AppTheme.crimson;
    default:
      return Colors.grey;
  }
}

Widget _buildPillChip({required String label, required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

class ImportRequirementsScreen extends ConsumerStatefulWidget {
  const ImportRequirementsScreen({super.key});

  @override
  ConsumerState<ImportRequirementsScreen> createState() => _ImportRequirementsScreenState();
}

class _ImportRequirementsScreenState extends ConsumerState<ImportRequirementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedFileFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importRequirementsProvider.notifier).refreshData();
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      ref.read(suppliersProvider.notifier).fetchSuppliers();
      ref.read(customsTariffProvider.notifier).fetchTariffs();
      ref.read(customsConsultationsProvider.notifier).fetchConsultations();
    });
  }

  void _showCreateEditDialog([ImportRequirementModel? requirement]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportRequirementFormDialog(requirement: requirement),
    );
  }


  @override
  Widget build(BuildContext context) {
    final asyncRequirements = ref.watch(importRequirementsProvider);
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.verified_outlined, color: AppTheme.cobalt, size: 24),
            SizedBox(width: 10),
            Text(
              'تقييم متطلبات ومستندات الاستيراد والموافقات التنظيمية (BP-011 التأكيد اللاحق للـ ACID)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppTheme.charcoal,
        actions: [
          const BackToDashboardButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'إعادة تحميل حية',
            onPressed: () {
              ref.read(importRequirementsProvider.notifier).refreshData();
              ref.read(importFilesProvider.notifier).fetchImportFiles();
              ref.read(suppliersProvider.notifier).fetchSuppliers();
              ref.read(customsTariffProvider.notifier).fetchTariffs();
              ref.read(customsConsultationsProvider.notifier).fetchConsultations();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Data Actions Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'import-requirements',
              title: 'Import_Requirements',
              onRefreshNeeded: () => ref.read(importRequirementsProvider.notifier).refreshData(),
            ),
            const SizedBox(height: 12),

            // Top Filter & Action Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'بحث برقم التقييم، البند الجمركي HS Code، رقم الـ ACID، المورد، أو الوصف...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.cobalt),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SearchableDropdownField<int?>(
                      value: _selectedFileFilter,
                      labelText: 'تصفية بملف الشحنة',
                      items: [
                        const SearchableDropdownItem<int?>(value: null, label: 'جميع ملفات الشحنات'),
                        ...importFiles.map(
                          (f) => SearchableDropdownItem<int?>(
                            value: f.importFileId,
                            label: '${f.importFileCode} - ${f.supplierName}',
                            subtitle: 'ACID: ${f.acidNumber ?? "Pending"}',
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedFileFilter = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateEditDialog(),
                    icon: const Icon(Icons.add_task, color: Colors.white),
                    label: const Text('إضافة تأكيد استيرادي شامل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5 Pillars Overview Banner with ACID Confirmation Reminder
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cobalt.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cobalt.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PillarHeaderItem(icon: Icons.factory_outlined, title: 'المحور 1: قرار 43 وتسجيل المصانع'),
                  _PillarHeaderItem(icon: Icons.public_outlined, title: 'المحور 2: شهادة المنشأ والاتفاقيات'),
                  _PillarHeaderItem(icon: Icons.verified_outlined, title: 'المحور 3: فحص ما قبل الشحن'),
                  _PillarHeaderItem(icon: Icons.account_balance_outlined, title: 'المحور 4: موافقات جهات العرض'),
                  _PillarHeaderItem(icon: Icons.science_outlined, title: 'المحور 5: شهادات خاصة (MSDS/Halal/COA)'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Main Grid View
            Expanded(
              child: asyncRequirements.when(
                data: (requirements) {
                  var filtered = requirements.where((r) {
                    final query = _searchController.text.toLowerCase();
                    final matchesQuery = r.assessmentCode.toLowerCase().contains(query) ||
                        (r.hsCode?.toLowerCase().contains(query) ?? false) ||
                        (r.supplierName?.toLowerCase().contains(query) ?? false) ||
                        (r.acidNumber?.toLowerCase().contains(query) ?? false) ||
                        (r.commodityDescription?.toLowerCase().contains(query) ?? false);
                    final matchesFile = _selectedFileFilter == null || r.importFileId == _selectedFileFilter;
                    return matchesQuery && matchesFile;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rule_folder_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('لا توجد تقييمات استيرادية مطابقة للبحث.', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateEditDialog(),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('إضافة أول تأكيد استيرادي', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final req = filtered[index];
                      return _buildAssessmentCard(req);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('خطأ: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(ImportRequirementModel req) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.charcoal,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        req.assessmentCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                      ),
                    ),
                    if (req.importFileCode != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.cobalt.withOpacity(0.4)),
                        ),
                        child: Text(
                          'ملف: ${req.importFileCode}',
                          style: const TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                    if (req.acidNumber != null && req.acidNumber!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'ACID: ${req.acidNumber}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    _buildPillChip(
                      label: req.overallStatus,
                      color: _getStatusColor(req.overallStatus),
                    ),
                    const SizedBox(width: 6),
                    _buildPillChip(
                      label: 'مخاطر: ${req.riskLevel}',
                      color: _getRiskLevelColor(req.riskLevel),
                    ),
                    const SizedBox(width: 6),
                    RowActionsPill(
                      onView: () => _showCreateEditDialog(req),
                      onEdit: () => _showCreateEditDialog(req),
                      onPrint: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('طباعة تقرير استيفاء المتطلبات الاستيرادية (5 محاور): ${req.assessmentCode} (ACID: ${req.acidNumber ?? "-"})'),
                            backgroundColor: AppTheme.charcoal,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('حذف تقييم الاستيراد'),
                            content: Text('هل أنت متأكد من حذف التقييم الاستيرادي (${req.assessmentCode})؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && req.assessmentId != null) {
                          ref.read(importRequirementsProvider.notifier).deleteRequirement(req.assessmentId!);
                        }
                      },
                      viewTooltip: 'عرض تفاصيل التقييم والتأكيد',
                      editTooltip: 'تعديل التقييم الاستيرادي',
                      printTooltip: 'طباعة تقرير المتطلبات',
                      deleteTooltip: 'حذف التقييم الاستيرادي',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // HS Code & Commodity
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HS Code: ${req.hsCode ?? "غير محدد"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                      ),
                      Text(
                        req.commodityDescription ?? 'بدون وصف للصنف',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (req.supplierName != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.business, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          req.supplierName!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 12),

            // The 5 Pillars Visual Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 5,
                childAspectRatio: 2.2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPillarBadge(
                    icon: Icons.factory_outlined,
                    pillarNum: '1',
                    name: 'قرار 43',
                    status: req.decree43Applicable
                        ? (req.whiteListVerified ? 'مسجل بالهيئة' : 'مطلوب التسجيل')
                        : 'غير خاضع',
                    isActive: req.decree43Applicable,
                    isOk: req.decree43Applicable ? req.whiteListVerified : true,
                  ),
                  _buildPillarBadge(
                    icon: Icons.public_outlined,
                    pillarNum: '2',
                    name: 'المنشأ ${req.cooType ?? ""}',
                    status: req.cooRequired ? req.cooStatus : 'غير مطلوبة',
                    isActive: req.cooRequired,
                    isOk: !req.cooRequired || req.cooStatus == 'Obtained' || req.cooStatus == 'تم الاستلام والتحقق',
                  ),
                  _buildPillarBadge(
                    icon: Icons.verified_outlined,
                    pillarNum: '3',
                    name: 'الفحص ${req.inspectionBody ?? ""}',
                    status: req.inspectionRequired ? req.inspectionStatus : 'غير مطلوب',
                    isActive: req.inspectionRequired,
                    isOk: !req.inspectionRequired || req.inspectionStatus == 'Completed' || req.inspectionStatus == 'تم الفحص واجتياز المطابقة',
                  ),
                  _buildPillarBadge(
                    icon: Icons.account_balance_outlined,
                    pillarNum: '4',
                    name: 'العرض ${req.permitIssuingAuthority ?? ""}',
                    status: req.importPermitRequired ? req.permitStatus : 'لا يتطلب',
                    isActive: req.importPermitRequired,
                    isOk: !req.importPermitRequired || req.permitStatus == 'Approved' || req.permitStatus == 'تمت الموافقة والاعتماد',
                  ),
                  _buildPillarBadge(
                    icon: Icons.science_outlined,
                    pillarNum: '5',
                    name: 'شهادات خاصة',
                    status: (req.msdsRequired || req.halalCertRequired || req.coaRequired) ? 'مطلوبة' : 'لا توجد',
                    isActive: req.msdsRequired || req.halalCertRequired || req.coaRequired,
                    isOk: true,
                  ),
                ],
              ),
            ),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'بلد المنشأ: ${req.countryOfOrigin ?? "غير محدد"} | القيمة: ${req.shipmentValue.toStringAsFixed(0)} ${req.currency}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  'المراجع: ${req.assessedBy}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarBadge({
    required IconData icon,
    required String pillarNum,
    required String name,
    required String status,
    required bool isActive,
    required bool isOk,
  }) {
    final bgColor = !isActive
        ? Colors.grey.shade50
        : isOk
            ? AppTheme.emerald.withOpacity(0.08)
            : AppTheme.orange.withOpacity(0.1);
    final borderColor = !isActive
        ? Colors.grey.shade300
        : isOk
            ? AppTheme.emerald.withOpacity(0.5)
            : AppTheme.orange.withOpacity(0.5);
    final textColor = !isActive
        ? Colors.grey.shade600
        : isOk
            ? AppTheme.emerald
            : AppTheme.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: textColor),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
            ],
          ),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 8, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _PillarHeaderItem extends StatelessWidget {
  final IconData icon;
  final String title;
  const _PillarHeaderItem({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.cobalt),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
        ),
      ],
    );
  }
}

class _ImportRequirementFormDialog extends ConsumerStatefulWidget {
  final ImportRequirementModel? requirement;
  const _ImportRequirementFormDialog({this.requirement});

  @override
  ConsumerState<_ImportRequirementFormDialog> createState() => _ImportRequirementFormDialogState();
}

class _ImportRequirementFormDialogState extends ConsumerState<_ImportRequirementFormDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // General & Master Linkage
  int? _selectedFileId;
  String? _selectedFileCode;
  String? _selectedHsCode;
  int? _selectedSupplierId;
  String? _selectedSupplierName;
  String _selectedCurrency = 'USD';
  late TextEditingController _descCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _valCtrl;

  // Post-ACID & Consultation Linkage Info
  String? _acidNumber;
  int? _consultationId;
  String? _consultationCode;
  String? _brokerName;
  String? _consultationStatus;
  double _readinessPercentage = 0.0;
  bool _isPrefilling = false;

  // Pillar 1: Decree 43 & Foreign Suppliers
  bool _decree43 = false;
  bool _whiteList = false;
  bool _whiteListVerified = false;
  late TextEditingController _factoryRegCtrl;

  // Pillar 2: Certificate of Origin (COO)
  bool _cooRequired = false;
  String _cooType = 'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)';
  String _cooStatus = 'مطلوبة';
  late TextEditingController _cooNotesCtrl;

  // Pillar 3: Pre-Shipment Inspection Certificate
  bool _inspRequired = false;
  String _inspBody = 'SGS';
  String _inspStatus = 'مطلوب';
  late TextEditingController _inspReportNoCtrl;
  late TextEditingController _inspNotesCtrl;

  // Pillar 4: Prior Import Permit & Regulatory Authority
  bool _permitRequired = false;
  String _permitAuth = 'جهاز شئون البيئة (EEAA)';
  String _permitStatus = 'مطلوب';
  late TextEditingController _permitNoCtrl;
  late TextEditingController _permitNotesCtrl;

  // Pillar 5: Technical & Special Certificates
  bool _msdsRequired = false;
  String _msdsStatus = 'مطلوبة';
  bool _halalRequired = false;
  String _halalStatus = 'مطلوبة';
  bool _coaRequired = false;
  String _coaStatus = 'مطلوبة';
  late TextEditingController _specialNotesCtrl;

  // Summary & Risk
  String _overallStatus = 'قيد الاستيفاء والتأكيد';
  String _riskLevel = 'منخفض (Low)';
  late TextEditingController _assessedByCtrl;
  late TextEditingController _assessmentNotesCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    final req = widget.requirement;
    _selectedFileId = req?.importFileId;
    _selectedFileCode = req?.importFileCode;
    _selectedHsCode = req?.hsCode;
    _selectedSupplierId = req?.supplierId;
    _selectedSupplierName = req?.supplierName;
    _selectedCurrency = req?.currency ?? 'USD';
    _acidNumber = req?.acidNumber;
    _consultationId = req?.consultationId;
    _consultationCode = req?.consultationCode;

    _descCtrl = TextEditingController(text: req?.commodityDescription);
    _countryCtrl = TextEditingController(text: req?.countryOfOrigin);
    _valCtrl = TextEditingController(
        text: (req?.shipmentValue != null && req!.shipmentValue > 0)
            ? req.shipmentValue.toString()
            : (req?.shipmentValueUsd.toString() ?? '0'));

    // Pillar 1
    _decree43 = req?.decree43Applicable ?? false;
    _whiteList = req?.whiteListRequired ?? false;
    _whiteListVerified = req?.whiteListVerified ?? false;
    _factoryRegCtrl = TextEditingController(text: req?.factoryRegistrationNo);

    // Pillar 2
    _cooRequired = req?.cooRequired ?? false;
    _cooType = req?.cooType ?? 'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)';
    _cooStatus = req?.cooStatus ?? 'مطلوبة';
    _cooNotesCtrl = TextEditingController(text: req?.cooNotes);

    // Pillar 3
    _inspRequired = req?.inspectionRequired ?? false;
    _inspBody = req?.inspectionBody ?? 'SGS';
    _inspStatus = req?.inspectionStatus ?? 'مطلوب';
    _inspReportNoCtrl = TextEditingController(text: req?.inspectionReportNo);
    _inspNotesCtrl = TextEditingController(text: req?.inspectionNotes);

    // Pillar 4
    _permitRequired = req?.importPermitRequired ?? false;
    _permitAuth = req?.permitIssuingAuthority ?? 'جهاز شئون البيئة (EEAA)';
    _permitStatus = req?.permitStatus ?? 'مطلوب';
    _permitNoCtrl = TextEditingController(text: req?.permitNumber);
    _permitNotesCtrl = TextEditingController(text: req?.permitNotes);

    // Pillar 5
    _msdsRequired = req?.msdsRequired ?? false;
    _msdsStatus = req?.msdsStatus ?? 'مطلوبة';
    _halalRequired = req?.halalCertRequired ?? false;
    _halalStatus = req?.halalCertStatus ?? 'مطلوبة';
    _coaRequired = req?.coaRequired ?? false;
    _coaStatus = req?.coaStatus ?? 'مطلوبة';
    _specialNotesCtrl = TextEditingController(text: req?.coaNotes ?? req?.msdsNotes ?? req?.halalCertNotes);

    // Summary
    _overallStatus = req?.overallStatus ?? 'قيد الاستيفاء والتأكيد';
    _riskLevel = req?.riskLevel ?? 'منخفض (Low)';
    _assessedByCtrl = TextEditingController(text: req?.assessedBy ?? 'Kamal');
    _assessmentNotesCtrl = TextEditingController(text: req?.assessmentNotes);

    // If already editing with a file linked, run auto-prefill once if fields are empty
    if (_selectedFileId != null && widget.requirement == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerAutoPrefillFromLinkedFile(_selectedFileId);
      });
    }
  }

  Future<void> _triggerAutoPrefillFromLinkedFile(int? fileId) async {
    if (fileId == null) {
      setState(() {
        _acidNumber = null;
        _consultationId = null;
        _consultationCode = null;
        _brokerName = null;
        _consultationStatus = null;
        _readinessPercentage = 0.0;
      });
      return;
    }

    setState(() => _isPrefilling = true);

    try {
      final prefill = await ref.read(importRequirementsProvider.notifier).fetchPrefillData(fileId);
      if (prefill != null) {
        setState(() {
          _selectedFileCode = prefill.importFileCode;
          _selectedSupplierId = prefill.supplierId;
          _selectedSupplierName = prefill.supplierName;
          _countryCtrl.text = prefill.countryOfOrigin ?? 'China';
          _selectedCurrency = prefill.currency;
          _valCtrl.text = prefill.shipmentValue > 0 ? prefill.shipmentValue.toString() : _valCtrl.text;
          _acidNumber = prefill.acidNumber;

          _consultationId = prefill.consultationId;
          _consultationCode = prefill.consultationCode;
          _brokerName = prefill.brokerName;
          _consultationStatus = prefill.consultationStatus;
          _readinessPercentage = prefill.readinessPercentage;

          if (prefill.hsCode != null && prefill.hsCode!.isNotEmpty) {
            _selectedHsCode = prefill.hsCode;
          }
          if (prefill.commodityDescription != null && prefill.commodityDescription!.isNotEmpty) {
            _descCtrl.text = prefill.commodityDescription!;
          }

          // 5 Pillars Auto Extraction from Customs Consultation & Tariff
          _decree43 = prefill.decree43Applicable;
          _whiteList = prefill.whiteListRequired;
          _whiteListVerified = prefill.whiteListVerified;
          _factoryRegCtrl.text = prefill.factoryRegistrationNo ?? '';

          _cooRequired = prefill.cooRequired;
          if (prefill.cooType != null) _cooType = prefill.cooType!;
          _cooStatus = prefill.cooStatus;
          _cooNotesCtrl.text = prefill.cooNotes ?? '';

          _inspRequired = prefill.inspectionRequired;
          if (prefill.inspectionBody != null) _inspBody = prefill.inspectionBody!;
          _inspStatus = prefill.inspectionStatus;
          _inspNotesCtrl.text = prefill.inspectionNotes ?? '';

          _permitRequired = prefill.importPermitRequired;
          if (prefill.permitIssuingAuthority != null) _permitAuth = prefill.permitIssuingAuthority!;
          _permitStatus = prefill.permitStatus;
          _permitNotesCtrl.text = prefill.permitNotes ?? '';

          _msdsRequired = prefill.msdsRequired;
          _msdsStatus = prefill.msdsStatus;
          _halalRequired = prefill.halalCertRequired;
          _halalStatus = prefill.halalCertStatus;
          _coaRequired = prefill.coaRequired;
          _coaStatus = prefill.coaStatus;
          _specialNotesCtrl.text = prefill.specialNotes ?? '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _consultationCode != null
                    ? '✨ تم استدعاء بيانات الشحنة والـ ACID ودراسة الاستشارة الجمركية (${_consultationCode!}) بنجاح!'
                    : '✨ تم استدعاء بيانات الشحنة والمورد والـ ACID بنجاح!',
              ),
              backgroundColor: AppTheme.cobalt,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Fallback: local lookup in loaded providers
        _fallbackLocalExtraction(fileId);
      }
    } catch (_) {
      _fallbackLocalExtraction(fileId);
    } finally {
      if (mounted) setState(() => _isPrefilling = false);
    }
  }

  void _fallbackLocalExtraction(int fileId) {
    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    final consultations = ref.read(customsConsultationsProvider).value ?? [];
    final consult = consultations.where((c) => c.importFileId == fileId).firstOrNull;

    setState(() {
      _selectedFileCode = file.importFileCode;
      _selectedSupplierId = file.supplierId;
      _selectedSupplierName = file.supplierName;
      _acidNumber = file.acidNumber;

      if (file.invoicesData.isNotEmpty) {
        _selectedCurrency = file.invoicesData.first.currency;
        double total = 0;
        for (var inv in file.invoicesData) {
          total += inv.amount;
        }
        _valCtrl.text = total.toString();
      }

      if (consult != null) {
        _consultationId = consult.consultationId;
        _consultationCode = consult.consultationCode;
        _brokerName = consult.brokerName;
        _consultationStatus = consult.overallStatus;
        _readinessPercentage = consult.readinessPercentage;
      }
    });
  }

  void _confirmAndApproveAllPillars() {
    setState(() {
      if (_decree43) _whiteListVerified = true;
      if (_cooRequired) _cooStatus = 'تم الاستلام والتحقق';
      if (_inspRequired) _inspStatus = 'تم الفحص واجتياز المطابقة';
      if (_permitRequired) _permitStatus = 'تمت الموافقة والاعتماد';
      if (_msdsRequired) _msdsStatus = 'تم الاستلام والتحقق';
      if (_halalRequired) _halalStatus = 'تم الاستلام والتحقق';
      if (_coaRequired) _coaStatus = 'تم الاستلام والتحقق';
      _overallStatus = 'مؤكد ومصرح للشحن';
      _riskLevel = 'منخفض (Low)';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم تأكيد واستيفاء كافة المحاور التنظيمية وتصريح الشحن بنجاح!'),
        backgroundColor: AppTheme.emerald,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descCtrl.dispose();
    _countryCtrl.dispose();
    _valCtrl.dispose();
    _factoryRegCtrl.dispose();
    _cooNotesCtrl.dispose();
    _inspReportNoCtrl.dispose();
    _inspNotesCtrl.dispose();
    _permitNoCtrl.dispose();
    _permitNotesCtrl.dispose();
    _specialNotesCtrl.dispose();
    _assessedByCtrl.dispose();
    _assessmentNotesCtrl.dispose();
    super.dispose();
  }

  void _onHsCodeChanged(String? hsCode) {
    setState(() {
      _selectedHsCode = hsCode;
    });

    if (hsCode != null && hsCode.isNotEmpty) {
      final tariffs = ref.read(customsTariffProvider).value ?? [];
      final match = tariffs.where((t) => t.hsCode == hsCode).firstOrNull;
      if (match != null) {
        setState(() {
          if (_descCtrl.text.isEmpty || widget.requirement == null) {
            _descCtrl.text = match.hsDescription;
          }
          if (match.requiresCoo) {
            _cooRequired = true;
          }
          if (match.requiresInspection) {
            _inspRequired = true;
          }
          if (match.regulatoryAuthority != null && match.regulatoryAuthority!.isNotEmpty) {
            _permitRequired = true;
            _permitAuth = match.regulatoryAuthority!;
          }
          if (match.priorApprovalNote != null && match.priorApprovalNote!.isNotEmpty) {
            _permitNotesCtrl.text = match.priorApprovalNote!;
            if (match.priorApprovalNote!.contains('43') ||
                match.priorApprovalNote!.contains('مصانع مسجلة') ||
                match.priorApprovalNote!.contains('هـ.ع.ص.و')) {
              _decree43 = true;
              _whiteList = true;
            }
          }
        });
      }
    }
  }

  void _onSupplierChanged(int? supplierId) {
    setState(() {
      _selectedSupplierId = supplierId;
    });

    if (supplierId != null) {
      final suppliers = ref.read(suppliersProvider).value ?? [];
      final match = suppliers.where((s) => s.supplierId == supplierId).firstOrNull;
      if (match != null) {
        setState(() {
          _selectedSupplierName = match.companyName;
          if (_countryCtrl.text.isEmpty || widget.requirement == null) {
            _countryCtrl.text = match.foreignExporterCountry;
          }
          if (_factoryRegCtrl.text.isEmpty) {
            _factoryRegCtrl.text = match.foreignExporterId;
          }
        });
      }
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final shipmentVal = double.tryParse(_valCtrl.text.trim()) ?? 0.0;

    final data = {
      'import_file_id': _selectedFileId,
      'import_file_code': _selectedFileCode,
      'hs_code': _selectedHsCode,
      'commodity_description': _descCtrl.text.trim(),
      'country_of_origin': _countryCtrl.text.trim(),
      'currency': _selectedCurrency,
      'shipment_value': shipmentVal,
      'shipment_value_usd': shipmentVal,
      'acid_number': _acidNumber,
      'consultation_id': _consultationId,
      'consultation_code': _consultationCode,
      'confirmation_status': _overallStatus == 'مؤكد ومصرح للشحن' ? 'Confirmed & Cleared' : 'In Progress',
      'is_post_acid_confirmed': _overallStatus == 'مؤكد ومصرح للشحن',
      'confirmed_by': 'Kamal (Lead Import Auditor)',

      // Pillar 1
      'supplier_id': _selectedSupplierId,
      'supplier_name': _selectedSupplierName,
      'decree_43_applicable': _decree43,
      'white_list_required': _whiteList,
      'white_list_verified': _whiteListVerified,
      'factory_registration_no': _factoryRegCtrl.text.trim().isEmpty ? null : _factoryRegCtrl.text.trim(),

      // Pillar 2
      'coo_required': _cooRequired,
      'coo_type': _cooRequired ? _cooType : null,
      'coo_status': _cooRequired ? _cooStatus : 'Not Required',
      'coo_notes': _cooNotesCtrl.text.trim().isEmpty ? null : _cooNotesCtrl.text.trim(),

      // Pillar 3
      'inspection_required': _inspRequired,
      'inspection_body': _inspRequired ? _inspBody : null,
      'inspection_status': _inspRequired ? _inspStatus : 'Not Required',
      'inspection_report_no': _inspReportNoCtrl.text.trim().isEmpty ? null : _inspReportNoCtrl.text.trim(),
      'inspection_notes': _inspNotesCtrl.text.trim().isEmpty ? null : _inspNotesCtrl.text.trim(),

      // Pillar 4
      'import_permit_required': _permitRequired,
      'permit_issuing_authority': _permitRequired ? _permitAuth : null,
      'permit_number': _permitNoCtrl.text.trim().isEmpty ? null : _permitNoCtrl.text.trim(),
      'permit_status': _permitRequired ? _permitStatus : 'Not Required',
      'permit_notes': _permitNotesCtrl.text.trim().isEmpty ? null : _permitNotesCtrl.text.trim(),

      // Pillar 5
      'msds_required': _msdsRequired,
      'msds_status': _msdsRequired ? _msdsStatus : 'Not Required',
      'msds_notes': _specialNotesCtrl.text.trim().isEmpty ? null : _specialNotesCtrl.text.trim(),
      'halal_cert_required': _halalRequired,
      'halal_cert_status': _halalRequired ? _halalStatus : 'Not Required',
      'halal_cert_notes': _specialNotesCtrl.text.trim().isEmpty ? null : _specialNotesCtrl.text.trim(),
      'coa_required': _coaRequired,
      'coa_status': _coaRequired ? _coaStatus : 'Not Required',
      'coa_notes': _specialNotesCtrl.text.trim().isEmpty ? null : _specialNotesCtrl.text.trim(),

      // Summary
      'overall_status': _overallStatus,
      'risk_level': _riskLevel,
      'assessed_by': _assessedByCtrl.text.trim().isEmpty ? 'System' : _assessedByCtrl.text.trim(),
      'assessment_notes': _assessmentNotesCtrl.text.trim().isEmpty ? null : _assessmentNotesCtrl.text.trim(),
    };

    try {
      if (widget.requirement == null) {
        await ref.read(importRequirementsProvider.notifier).addRequirement(data);
      } else {
        await ref.read(importRequirementsProvider.notifier).updateRequirement(widget.requirement!.assessmentId!, data);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.requirement == null
                ? '✅ تم حفظ واعتماد تقييم المتطلبات الاستيرادية التأكيدي بنجاح!'
                : '✅ تم تحديث التقييم الاستيرادي التأكيدي بنجاح!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppTheme.crimson),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final importFiles = ref.watch(importFilesProvider).value ?? [];
    final suppliers = ref.watch(suppliersProvider).value ?? [];
    final tariffs = ref.watch(customsTariffProvider).value ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 1000,
        height: 790,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header with Post-ACID Verification Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppTheme.cobalt, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        widget.requirement == null
                            ? 'المرحلة التأكيدية بعد إصدار ACID — تقييم ومطابقة المتطلبات التنظيمية (BP-011)'
                            : 'تحديث ومطابقة المتطلبات التأكيدية (${widget.requirement!.assessmentCode})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 12),

              // Post-ACID Confirmation Banner & Consultation Linkage Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _acidNumber != null && _acidNumber!.isNotEmpty ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _acidNumber != null && _acidNumber!.isNotEmpty ? Colors.green.shade300 : Colors.amber.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _acidNumber != null && _acidNumber!.isNotEmpty ? Icons.verified : Icons.warning_amber_rounded,
                      color: _acidNumber != null && _acidNumber!.isNotEmpty ? Colors.green : Colors.amber.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _acidNumber != null && _acidNumber!.isNotEmpty
                            ? 'رقم القيد الجمركي المسبق الصادر (ACID: $_acidNumber) | حالة التأكيد: مرحلة الفحص النهائي والمطابقة الخماسية قبل الإفراج الجمركي.'
                            : '⚠️ لم يتم ربط أو إصدار رقم ACID بعد لهذا الملف — سيتم السحب الأولي لمطابقة الاشتراطات الرقابية.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _acidNumber != null && _acidNumber!.isNotEmpty ? Colors.green.shade900 : Colors.brown,
                        ),
                      ),
                    ),
                    if (_consultationCode != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.cobalt, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          'نتائج الاستشارة: $_consultationCode (${_brokerName ?? "المخلص الجمركي"}) - ${_consultationStatus ?? "جاهز"} (${_readinessPercentage.toStringAsFixed(0)}%)',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isPrefilling) ...[
                const SizedBox(height: 4),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 10),

              // General Section: Import File (Auto Pull Trigger), HS Code, Supplier
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SearchableDropdownField<int?>(
                            value: _selectedFileId,
                            labelText: 'ملف الشحنة المربوط (Import File) *',
                            searchHintText: 'ابحث برقم الملف، المورد أو ACID...',
                            items: [
                              const SearchableDropdownItem<int?>(value: null, label: '-- اختر ملف الشحنة للسحب التلقائي الشامل --'),
                              ...importFiles.map(
                                (f) => SearchableDropdownItem<int?>(
                                  value: f.importFileId,
                                  label: '[${f.importFileCode}] ${f.supplierName}',
                                  subtitle: 'ACID: ${f.acidNumber ?? "Pending"} | العملة: ${f.invoicesData.isNotEmpty ? f.invoicesData.first.currency : "USD"}',
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedFileId = val;
                              });
                              _triggerAutoPrefillFromLinkedFile(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SearchableDropdownField<String?>(
                            value: _selectedHsCode,
                            labelText: 'بند التعريفة الجمركية (HS Code MD-008) *',
                            isRequired: true,
                            searchHintText: 'ابحث برقم البند أو الوصف...',
                            items: [
                              ...tariffs.map(
                                (t) => SearchableDropdownItem<String?>(
                                  value: t.hsCode,
                                  label: '${t.hsCode} - ${t.hsDescription}',
                                  subtitle: 'وارد: ${t.customsDutyRate}% | ق.م: ${t.vatRate}% | جهة العرض: ${t.regulatoryAuthority ?? "لا توجد"}',
                                ),
                              ),
                            ],
                            onChanged: _onHsCodeChanged,
                            validator: (v) => v == null || v.isEmpty ? 'يرجى اختيار البند الجمركي' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SearchableDropdownField<int?>(
                            value: _selectedSupplierId,
                            labelText: 'المورد الخارجي / المصنع (Foreign Supplier MD-002)',
                            searchHintText: 'ابحث عن المورد الخارجي...',
                            items: [
                              const SearchableDropdownItem<int?>(value: null, label: 'بدون تحديد مورد'),
                              ...suppliers.map(
                                (s) => SearchableDropdownItem<int?>(
                                  value: s.supplierId,
                                  label: '${s.companyName} (${s.foreignExporterCountry})',
                                  subtitle: 'كود المصدر: ${s.foreignExporterId} | قرار 43: ${s.registeredDecree43 ? "مسجل ✔" : "غير مسجل"}',
                                ),
                              ),
                            ],
                            onChanged: _onSupplierChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _countryCtrl,
                            decoration: const InputDecoration(
                              labelText: 'بلد المنشأ والتصدير (Country of Origin) *',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _valCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'قيمة الشحنة بالعملة ($_selectedCurrency) *',
                              isDense: true,
                              prefixText: '$_selectedCurrency ',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || double.tryParse(v.trim()) == null ? 'قيمة غير صحيحة' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'وصف السلعة / الصنف التجاري *',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'وصف الصنف مطلوب' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 5 Pillars Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.cobalt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.charcoal,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(icon: Icon(Icons.factory, size: 16), text: 'قرار 43 وتسجيل المصانع .1'),
                    Tab(icon: Icon(Icons.public, size: 16), text: 'شهادة المنشأ والاتفاقيات .2'),
                    Tab(icon: Icon(Icons.verified, size: 16), text: 'فحص ما قبل الشحن .3'),
                    Tab(icon: Icon(Icons.account_balance, size: 16), text: 'موافقات جهات العرض .4'),
                    Tab(icon: Icon(Icons.science, size: 16), text: 'شهادات خاصة وملخص .5'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPillar1Tab(),
                    _buildPillar2Tab(),
                    _buildPillar3Tab(),
                    _buildPillar4Tab(),
                    _buildPillar5Tab(),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Bottom Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildPillChip(
                        label: 'الحالة: $_overallStatus',
                        color: _getStatusColor(_overallStatus),
                      ),
                      const SizedBox(width: 8),
                      _buildPillChip(
                        label: 'المخاطر: $_riskLevel',
                        color: _getRiskLevelColor(_riskLevel),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.cobalt),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        icon: const Icon(Icons.auto_fix_high, color: AppTheme.cobalt, size: 16),
                        label: const Text('⚡ استيفاء وتأكيد كافة المحاور', style: TextStyle(color: AppTheme.cobalt, fontWeight: FontWeight.bold)),
                        onPressed: _confirmAndApproveAllPillars,
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: Text(
                          _isSaving ? 'جاري الحفظ...' : 'حفظ واعتماد التقييم التأكيدي',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- PILLAR 1: DECREE 43 & FACTORY REGISTRATION ---
  Widget _buildPillar1Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'القرار الوزاري رقم 43 لسنة 2016 يلزم تسجيل المصانع والشركات المالكة للعلامات التجارية المؤهلة للتصدير بالهيئة العامة للرقابة على الصادرات والواردات (GOEIC) للإفراج عن السلع المحددة.',
                    style: TextStyle(fontSize: 12, color: AppTheme.charcoal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('هل يخضع الصنف للقرار 43 لسنة 2016؟ (تسجيل المصانع المؤهلة للتصدير)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('يشترط للإفراج عن الصنف وارد اتجار أن يكون إنتاج مصانع مسجلة بالهيئة'),
            value: _decree43,
            onChanged: (v) => setState(() => _decree43 = v),
          ),
          if (_decree43) ...[
            const Divider(),
            CheckboxListTile(
              title: const Text('المصنع / الشركة مسجلة بالقائمة البيضاء (White List Verified)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('تم التحقق من صدور القرار الوزاري بقيد المصنع أو العلامة التجارية بسجلات الهيئة'),
              value: _whiteListVerified,
              onChanged: (v) => setState(() => _whiteListVerified = v ?? false),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _factoryRegCtrl,
              decoration: const InputDecoration(
                labelText: 'رقم قيد المصنع أو قرار القيد بالهيئة (Factory Registration / Decree No)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- PILLAR 2: CERTIFICATE OF ORIGIN & TRADE AGREEMENTS ---
  Widget _buildPillar2Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('شهادة المنشأ الرسمية والاتفاقيات التفضيلية (Certificate of Origin / FTA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('ضرورية للاستفادة من الإعفاءات والتخفيضات الجمركية (EUR.1 / Agadir / GAFTA / Mercosur)'),
            value: _cooRequired,
            onChanged: (v) => setState(() => _cooRequired = v),
          ),
          if (_cooRequired) ...[
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _cooType,
                    decoration: const InputDecoration(labelText: 'نوع شهادة المنشأ / الاتفاقية', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)', child: Text('EUR.1 (الشراكة الأوروبية / إفتا / تركيا)')),
                      DropdownMenuItem(value: 'Agadir (اتفاقية أغادير)', child: Text('Agadir (اتفاقية أغادير)')),
                      DropdownMenuItem(value: 'Arab League GAFTA (التيسير العربية)', child: Text('Arab League GAFTA (التيسير العربية)')),
                      DropdownMenuItem(value: 'Mercosur (اتفاقية الميركسور)', child: Text('Mercosur (اتفاقية الميركسور)')),
                      DropdownMenuItem(value: 'COMESA (الكوميسا)', child: Text('COMESA (الكوميسا)')),
                      DropdownMenuItem(value: 'General Certificate of Origin (عادية)', child: Text('General COO (شهادة منشأ عامة)')),
                    ],
                    onChanged: (v) => setState(() => _cooType = v ?? _cooType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _cooStatus,
                    decoration: const InputDecoration(labelText: 'حالة الاستيفاء والمطابقة', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'مطلوبة', child: Text('مطلوبة (قيد الانتظار)')),
                      DropdownMenuItem(value: 'تم الاستلام والتحقق', child: Text('تم الاستلام والتحقق (Obtained & Verified)')),
                      DropdownMenuItem(value: 'تم الإعفاء', child: Text('تم الإعفاء (Waived)')),
                    ],
                    onChanged: (v) => setState(() => _cooStatus = v ?? 'مطلوبة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _cooNotesCtrl,
              decoration: const InputDecoration(
                labelText: 'ملاحظات الاتفاقية التفضيلية ونسبة التخفيض الجمركي المستفادة',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- PILLAR 3: PRE-SHIPMENT INSPECTION CERTIFICATE ---
  Widget _buildPillar3Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('شهادة الفحص والمطابقة المسبقة قبل الشحن (Pre-Shipment Inspection Certificate)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('إلزامية للبضائع الخاضعة للفحص الظاهري والمخبري للتأكد من مطابقة المواصفات القياسية المصرية (ES)'),
            value: _inspRequired,
            onChanged: (v) => setState(() => _inspRequired = v),
          ),
          if (_inspRequired) ...[
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _inspBody,
                    decoration: const InputDecoration(labelText: 'شركة الفحص الدولية المعتمدة (ILAC Inspection Body)', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'SGS', child: Text('SGS (سوسيتيه جنرال دي سرفيانس)')),
                      DropdownMenuItem(value: 'Bureau Veritas', child: Text('Bureau Veritas (بيرو فيريتاس)')),
                      DropdownMenuItem(value: 'TÜV Rheinland', child: Text('TÜV Rheinland / TÜV SÜD')),
                      DropdownMenuItem(value: 'Intertek', child: Text('Intertek (إنترتك)')),
                      DropdownMenuItem(value: 'QIMA', child: Text('QIMA Inspection')),
                      DropdownMenuItem(value: 'Other Accredited Lab', child: Text('معمل آخر معتمد دولياً')),
                    ],
                    onChanged: (v) => setState(() => _inspBody = v ?? _inspBody),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _inspStatus,
                    decoration: const InputDecoration(labelText: 'حالة شهادة الفحص', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'مطلوب', child: Text('مطلوب (Pending)')),
                      DropdownMenuItem(value: 'تم التكليف والتنسيق', child: Text('تم التكليف والتنسيق (Scheduled)')),
                      DropdownMenuItem(value: 'تم الفحص واجتياز المطابقة', child: Text('تم الفحص واجتياز المطابقة (Completed & Passed)')),
                      DropdownMenuItem(value: 'مرفوض', child: Text('مرفوض (Failed Inspection)')),
                    ],
                    onChanged: (v) => setState(() => _inspStatus = v ?? 'مطلوب'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _inspReportNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رقم تقرير / شهادة الفحص (Inspection Certificate No)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _inspNotesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'المواصفة القياسية ورقم العينة (Egyptian Standard ES Compliance)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- PILLAR 4: PRIOR IMPORT PERMIT & REGULATORY AUTHORITIES ---
  Widget _buildPillar4Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('موافقات وتصاريح جهات العرض المسبقة (Prior Regulatory Approvals & Permits)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('الجهات المختصة بمراجعة السلع وإصدار أذون الإفراج المسبقة أو المشروطة'),
            value: _permitRequired,
            onChanged: (v) => setState(() => _permitRequired = v),
          ),
          if (_permitRequired) ...[
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _permitAuth,
                    decoration: const InputDecoration(labelText: 'جهة العرض والرقابة المختصة (Regulatory Authority)', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'جهاز شئون البيئة (EEAA)', child: Text('جهاز شئون البيئة (EEAA)')),
                      DropdownMenuItem(value: 'هيئة الدواء المصرية (EDA)', child: Text('هيئة الدواء المصرية (EDA)')),
                      DropdownMenuItem(value: 'الهيئة القومية لسلامة الغذاء (NFSA)', child: Text('الهيئة القومية لسلامة الغذاء (NFSA)')),
                      DropdownMenuItem(value: 'الجهاز القومي لتنظيم الاتصالات (NTRA)', child: Text('الجهاز القومي لتنظيم الاتصالات (NTRA)')),
                      DropdownMenuItem(value: 'هيئة الطاقة الذرية (EAEA)', child: Text('هيئة الطاقة الذرية (EAEA)')),
                      DropdownMenuItem(value: 'مصلحة الكيمياء', child: Text('مصلحة الكيمياء')),
                      DropdownMenuItem(value: 'الهيئة العامة للخدمات البيطرية', child: Text('الهيئة العامة للخدمات البيطرية')),
                    ],
                    onChanged: (v) => setState(() => _permitAuth = v ?? _permitAuth),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _permitStatus,
                    decoration: const InputDecoration(labelText: 'حالة التصريح / الموافقة', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'مطلوب', child: Text('مطلوب (Pending)')),
                      DropdownMenuItem(value: 'تم تقديم الطلب', child: Text('تم تقديم الطلب (Applied)')),
                      DropdownMenuItem(value: 'تمت الموافقة والاعتماد', child: Text('تمت الموافقة والاعتماد (Approved)')),
                      DropdownMenuItem(value: 'مرفوضة', child: Text('مرفوضة (Rejected)')),
                    ],
                    onChanged: (v) => setState(() => _permitStatus = v ?? 'مطلوب'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _permitNoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رقم التصريح أو إذن الاستيراد المسبق (Permit / Approval No)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _permitNotesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'شروط الإفراج والقرار الوزاري المطبق',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- PILLAR 5: TECHNICAL CERTIFICATES & FINAL ASSESSMENT SUMMARY ---
  Widget _buildPillar5Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الشهادات الفنية والخاصة الإلزامية (Technical & Special Certificates):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('شهادة صحيفة بيانات الأمان (MSDS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  value: _msdsRequired,
                  onChanged: (v) => setState(() => _msdsRequired = v ?? false),
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('شهادة الذبح الحلال (Halal Certificate)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  value: _halalRequired,
                  onChanged: (v) => setState(() => _halalRequired = v ?? false),
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('شهادة التحليل المخبري (COA)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  value: _coaRequired,
                  onChanged: (v) => setState(() => _coaRequired = v ?? false),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _overallStatus,
                  decoration: const InputDecoration(labelText: 'الحالة العامة للاستيفاء التأكيدي *', border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'مسودة (Draft)', child: Text('مسودة (Draft)')),
                    DropdownMenuItem(value: 'قيد الاستيفاء والتأكيد', child: Text('قيد الاستيفاء والتأكيد (In Progress)')),
                    DropdownMenuItem(value: 'مؤكد ومصرح للشحن', child: Text('مؤكد ومصرح للشحن (Confirmed & Cleared)')),
                  ],
                  onChanged: (v) => setState(() => _overallStatus = v ?? _overallStatus),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _riskLevel,
                  decoration: const InputDecoration(labelText: 'مستوى المخاطر الجمركية *', border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'منخفض (Low)', child: Text('منخفض (Low Risk)')),
                    DropdownMenuItem(value: 'متوسط (Medium)', child: Text('متوسط (Medium Risk)')),
                    DropdownMenuItem(value: 'مرتفع (High)', child: Text('مرتفع (High Risk)')),
                  ],
                  onChanged: (v) => setState(() => _riskLevel = v ?? _riskLevel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _assessedByCtrl,
                  decoration: const InputDecoration(
                    labelText: 'مسؤول المراجعة والاعتماد *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _assessmentNotesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'ملاحظات وتوصيات بوابة المطابقة والتأكيد النهائي (Confirmation Notes)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
