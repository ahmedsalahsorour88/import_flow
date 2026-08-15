import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../customs_tariff/providers/customs_tariff_provider.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/import_requirement_model.dart';
import '../providers/import_requirements_provider.dart';

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
    });
  }

  void _showCreateEditDialog([ImportRequirementModel? requirement]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ImportRequirementFormDialog(requirement: requirement),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Obtained':
      case 'Completed':
      case 'Approved':
      case 'Cleared':
      case 'تم الاستلام والتحقق':
      case 'تم الفحص واجتياز المطابقة':
      case 'تمت الموافقة والاعتماد':
      case 'معتمد ومصرح للشحن':
        return AppTheme.emerald;
      case 'Pending':
      case 'In Progress':
      case 'Applied':
      case 'Scheduled':
      case 'مطلوبة':
      case 'قيد الاستيفاء':
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
        return AppTheme.emerald;
      case 'Medium':
      case 'متوسط':
        return AppTheme.orange;
      case 'High':
      case 'مرتفع':
        return AppTheme.crimson;
      default:
        return Colors.grey;
    }
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
            Icon(Icons.rule_folder_outlined, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'تقييم متطلبات ومستندات الاستيراد والموافقات التنظيمية (BP-011)',
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
                        hintText: 'بحث برقم التقييم، البند الجمركي HS Code، المورد، أو الوصف...',
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
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedFileFilter = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateEditDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('إضافة تقييم استيراد جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

            // 5 Pillars Overview Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.charcoal.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.charcoal.withOpacity(0.1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PillarHeaderItem(icon: Icons.factory_outlined, title: 'المحور 1: قرار 43 وتسجيل المصانع'),
                  _PillarHeaderItem(icon: Icons.public_outlined, title: 'المحور 2: شهادة المنشأ والاتفاقيات'),
                  _PillarHeaderItem(icon: Icons.verified_outlined, title: 'المحور 3: فحص ما قبل الشحن'),
                  _PillarHeaderItem(icon: Icons.account_balance_outlined, title: 'المحور 4: موافقات جهات العرض'),
                  _PillarHeaderItem(icon: Icons.science_outlined, title: 'المحور 5: شهادات فنية (MSDS/Halal)'),
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
                            label: const Text('إضافة أول تقييم استيراد', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.55,
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
                      const SizedBox(width: 8),
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
                            content: Text('طباعة تقرير استيفاء المتطلبات الاستيرادية (5 محاور): ${req.assessmentCode} (HS: ${req.hsCode ?? "-"})'),
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
                      viewTooltip: 'عرض تفاصيل التقييم والمحاور',
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
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
            const Divider(height: 14),

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
                  'بلد المنشأ: ${req.countryOfOrigin ?? "غير محدد"} | القيمة: \$${req.shipmentValueUsd.toStringAsFixed(0)}',
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

  // Extracted invoice items from the linked file
  List<Map<String, dynamic>> _fileInvoiceItems = [];

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
  String _overallStatus = 'مسودة (Draft)';
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
    _overallStatus = req?.overallStatus ?? 'مسودة (Draft)';
    _riskLevel = req?.riskLevel ?? 'منخفض (Low)';
    _assessedByCtrl = TextEditingController(text: req?.assessedBy ?? 'Kamal');
    _assessmentNotesCtrl = TextEditingController(text: req?.assessmentNotes);

    // Initial extraction if file already linked
    if (_selectedFileId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _extractDataFromLinkedFile(_selectedFileId);
      });
    }
  }

  void _extractDataFromLinkedFile(int? fileId) {
    if (fileId == null) {
      setState(() {
        _fileInvoiceItems = [];
      });
      return;
    }

    final importFiles = ref.read(importFilesProvider).value ?? [];
    final file = importFiles.where((f) => f.importFileId == fileId).firstOrNull;
    if (file == null) return;

    final items = <Map<String, dynamic>>[];
    String fileCurr = 'USD';
    double totalInvoiceAmount = 0.0;

    if (file.invoicesData.isNotEmpty) {
      fileCurr = file.invoicesData.first.currency;
      for (var inv in file.invoicesData) {
        totalInvoiceAmount += inv.amount;
        items.add({
          'invoice_no': inv.invoiceNo,
          'invoice_type': inv.invoiceType,
          'amount': inv.amount,
          'currency': inv.currency,
          'hs_code': null, // In case invoice has sub-items
          'description': 'فاتورة رقم: ${inv.invoiceNo} (${inv.amount} ${inv.currency})',
        });
      }
    }

    setState(() {
      _selectedFileCode = file.importFileCode;
      _selectedCurrency = fileCurr;
      _fileInvoiceItems = items;

      if (_valCtrl.text == '0' || _valCtrl.text.isEmpty) {
        _valCtrl.text = totalInvoiceAmount > 0 ? totalInvoiceAmount.toString() : '0';
      }

      if (file.supplierId != null) {
        _onSupplierChanged(file.supplierId);
      }
    });
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
      'shipment_value_usd': shipmentVal, // Stored for backward compatibility

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
                ? '✅ تم إنشاء تقييم المتطلبات الاستيرادية بنجاح!'
                : '✅ تم تحديث تقييم المتطلبات الاستيرادية بنجاح!'),
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
        width: 950,
        height: 750,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.rule_folder, color: AppTheme.cobalt, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        widget.requirement == null
                            ? 'إضافة تقييم متطلبات استيرادية شامل (BP-011)'
                            : 'تعديل تقييم المتطلبات الاستيرادية (${widget.requirement!.assessmentCode})',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // General Section: Import File, HS Code, Supplier
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
                            labelText: 'ملف الشحنة المربوط (Import File)',
                            items: [
                              const SearchableDropdownItem<int?>(value: null, label: 'بدون ربط بملف محدد'),
                              ...importFiles.map(
                                (f) => SearchableDropdownItem<int?>(
                                  value: f.importFileId,
                                  label: '${f.importFileCode} - ${f.supplierName}',
                                  subtitle: f.invoicesData.isNotEmpty
                                      ? 'عملة الفواتير: ${f.invoicesData.first.currency} | عدد الفواتير: ${f.invoicesData.length}'
                                      : 'بدون فواتير مسجلة',
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedFileId = val;
                              });
                              _extractDataFromLinkedFile(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SearchableDropdownField<String?>(
                            value: _selectedHsCode,
                            labelText: 'بند التعريفة الجمركية (HS Code MD-008) *',
                            isRequired: true,
                            items: [
                              ...tariffs.map(
                                (t) => SearchableDropdownItem<String?>(
                                  value: t.hsCode,
                                  label: '${t.hsCode} - ${t.hsDescription}',
                                  subtitle: 'وارد: ${t.customsDutyRate}% | ق.م: ${t.vatRate}%',
                                ),
                              ),
                            ],
                            onChanged: _onHsCodeChanged,
                            validator: (v) => v == null || v.isEmpty ? 'يرجى اختيار البند الجمركي' : null,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedFileId != null && _fileInvoiceItems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long, size: 16, color: AppTheme.cobalt),
                            const SizedBox(width: 6),
                            Text(
                              'تم استدعاء بيانات الفواتير المرتبطة: عملة الملف الموحدة ($_selectedCurrency) — إجمالي فواتير الشحنة: ${_valCtrl.text} $_selectedCurrency',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SearchableDropdownField<int?>(
                            value: _selectedSupplierId,
                            labelText: 'المورد الخارجي / المصنع (Foreign Supplier MD-002)',
                            items: [
                              const SearchableDropdownItem<int?>(value: null, label: 'بدون تحديد مورد'),
                              ...suppliers.map(
                                (s) => SearchableDropdownItem<int?>(
                                  value: s.supplierId,
                                  label: '${s.companyName} (${s.foreignExporterCountry})',
                                  subtitle: 'كود المصدر: ${s.foreignExporterId}',
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
                              border: const OutlineInputBorder(),
                              prefixText: '$_selectedCurrency ',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'وصف السلعة / الصنف التجاري *',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 5 Pillars Tab Bar
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.cobalt,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppTheme.cobalt,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(icon: Icon(Icons.factory_outlined, size: 18), text: '1. قرار 43 وتسجيل المصانع'),
                  Tab(icon: Icon(Icons.public_outlined, size: 18), text: '2. شهادة المنشأ والاتفاقيات'),
                  Tab(icon: Icon(Icons.verified_outlined, size: 18), text: '3. فحص ما قبل الشحن'),
                  Tab(icon: Icon(Icons.account_balance_outlined, size: 18), text: '4. موافقات جهات العرض'),
                  Tab(icon: Icon(Icons.science_outlined, size: 18), text: '5. شهادات خاصة وملخص'),
                ],
              ),
              const SizedBox(height: 8),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Decree 43 & Foreign Suppliers
                    _buildPillar1Decree43Tab(),

                    // Tab 2: COO & Trade Agreements
                    _buildPillar2CooTab(),

                    // Tab 3: Pre-Shipment Inspection
                    _buildPillar3InspectionTab(),

                    // Tab 4: Prior Regulatory Approvals
                    _buildPillar4RegulatoryPermitsTab(),

                    // Tab 5: Technical Certs & Summary
                    _buildPillar5SpecialAndSummaryTab(),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          'الحالة: $_overallStatus | المخاطر: $_riskLevel',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          _isSaving ? 'جاري الحفظ...' : 'حفظ التقييم الاستيرادي',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  // ==========================================
  // Pillar 1: Decree 43 & Foreign Suppliers
  // ==========================================
  Widget _buildPillar1Decree43Tab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'القرار الوزاري رقم 43 لسنة 2016 يلزم تسجيل المصانع والشركات المالكة للعلامات التجارية المؤهلة للتصدير لجمهورية مصر العربية بالهيئة العامة للرقابة على الصادرات والواردات (GOEIC) للإفراج عن السلع المحددة.',
                    style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.charcoal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('هل يخضع الصنف للقرار 43 لسنة 2016؟ (تسجيل المصانع المؤهلة للتصدير)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('يشترط للافراج عن الصنف وارد اتجار أن يكون إنتاج مصانع مسجلة بالهيئة'),
            value: _decree43,
            onChanged: (v) => setState(() => _decree43 = v),
          ),
          if (_decree43) ...[
            const Divider(),
            SwitchListTile(
              title: const Text('اشتراط القيد بالقائمة البيضاء (White List Required)'),
              subtitle: const Text('التحقق من وجود المورد/المصنع ضمن قائمة المصانع المعتمدة للتصدير لمصر'),
              value: _whiteList,
              onChanged: (v) => setState(() => _whiteList = v),
            ),
            SwitchListTile(
              title: const Text('تم التحقق والتأكد من قيد المصنع بالهيئة هـ.ع.ص.و'),
              subtitle: const Text('المورد والمصنع مستوفي القيد وساري المفعول'),
              value: _whiteListVerified,
              onChanged: (v) => setState(() => _whiteListVerified = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _factoryRegCtrl,
              decoration: const InputDecoration(
                labelText: 'رقم وتاريخ قرار القيد بالهيئة هـ.ع.ص.و / كود المصنع المسجل',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.numbers, color: AppTheme.cobalt),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // Pillar 2: Certificate of Origin (COO)
  // ==========================================
  Widget _buildPillar2CooTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('هل شهادة المنشأ مطلوبة للاستفادة من الاتفاقيات التفضيلية؟', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('تخفيض أو إعفاء كامل من ضريبة الوارد الجمركية بناءً على شهادة المنشأ المعتمدة'),
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
                    decoration: const InputDecoration(
                      labelText: 'نوع شهادة المنشأ التفضيلية',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      'EUR.1 (الشراكة الأوروبية / إفتا / تركيا)',
                      'شهادة الميركسور (Mercosur - البرازيل/الأرجنتين)',
                      'شهادة جامعة الدول العربية (GAFTA)',
                      'شهادة اتفاقية صربيا',
                      'شهادة الكوميسا (COMESA)',
                      'شهادة المملكة المتحدة (UK Partnership)',
                      'شهادة عادية (Form A / Chamber of Commerce)',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => _cooType = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _cooStatus,
                    decoration: const InputDecoration(
                      labelText: 'حالة شهادة المنشأ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['مطلوبة', 'تم الاستلام والتحقق', 'تم الإعفاء', 'مرفوضة']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (v) => setState(() => _cooStatus = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cooNotesCtrl,
              decoration: const InputDecoration(
                labelText: 'ملاحظات الاتفاقية التفضيلية ونسبة التخفيض الجمركي (ر...)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // Pillar 3: Pre-Shipment Inspection Certificate
  // ==========================================
  Widget _buildPillar3InspectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('هل يتطلب الصنف شهادة فحص ومطابقة مسبقة قبل الشحن؟', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('شهادة فحص صادرة من جهات التفتيش الدولية المعتمدة لمطابقة المواصفات القياسية المصرية (ES)'),
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
                    decoration: const InputDecoration(
                      labelText: 'جهة الفحص الدولية المعتمدة',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      'SGS',
                      'Bureau Veritas (BV)',
                      'TÜV Rheinland',
                      'QIMA',
                      'Intertek',
                      'Cotecna',
                      'مختبرات فحص معتمدة أخرى',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => _inspBody = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _inspStatus,
                    decoration: const InputDecoration(
                      labelText: 'حالة شهادة الفحص',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['مطلوب', 'تم التكليف والتنسيق', 'تم الفحص واجتياز المطابقة', 'مرفوض']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (v) => setState(() => _inspStatus = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _inspReportNoCtrl,
              decoration: const InputDecoration(
                labelText: 'رقم تقرير / شهادة الفحص الدولية (Inspection Certificate No)',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.assignment_turned_in, color: AppTheme.cobalt),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _inspNotesCtrl,
              decoration: const InputDecoration(
                labelText: 'ملاحظات الفحص واشتراطات المواصفات القياسية',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // Pillar 4: Prior Regulatory Approvals & Permits
  // ==========================================
  Widget _buildPillar4RegulatoryPermitsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('هل يتطلب إذن استيراد أو موافقة جهة رقابية مسبقة؟ (Permits / Approvals)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('موافقات مسبقة من أجهزة البيئة أو الدواء أو الاتصالات أو سلامة الغذاء قبل الشحن'),
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
                    decoration: const InputDecoration(
                      labelText: 'الجهة الرقابية المختصة',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      'جهاز شئون البيئة (EEAA)',
                      'هيئة الدواء المصرية (EDA)',
                      'الهيئة القومية لسلامة الغذاء (NFSA)',
                      'الجهاز القومي لتنظيم الاتصالات (NTRA)',
                      'الهيئة العامة للرقابة على الصادرات والواردات (GOEIC)',
                      'الهيئة العامة للخدمات البيطرية / الحجر الزراعي',
                      'هيئة الطاقة الذرية / الأمن العام',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => _permitAuth = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _permitStatus,
                    decoration: const InputDecoration(
                      labelText: 'حالة إذن / موافقة الاستيراد',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['مطلوب', 'تم تقديم الطلب', 'تمت الموافقة والاعتماد', 'مرفوض']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (v) => setState(() => _permitStatus = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _permitNoCtrl,
              decoration: const InputDecoration(
                labelText: 'رقم وتاريخ تصريح / إذن الاستيراد المسبق',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.gavel, color: AppTheme.cobalt),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _permitNotesCtrl,
              decoration: const InputDecoration(
                labelText: 'اشتراطات وقرارات الموافقة المسبقة (ق...)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // Pillar 5: Technical Certs & Overall Summary
  // ==========================================
  Widget _buildPillar5SpecialAndSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الشهادات الفنية والخاصة:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('شهادة سلامة المواد (MSDS)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  value: _msdsRequired,
                  onChanged: (v) => setState(() => _msdsRequired = v ?? false),
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('شهادة الذبح الحلال (Halal)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
          const Divider(),
          const Text('ملخص التقييم والاعتماد الشامل:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _overallStatus,
                  decoration: const InputDecoration(
                    labelText: 'حالة التقييم العامة',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    'مسودة (Draft)',
                    'قيد الاستيفاء (In Progress)',
                    'مكتمل ومطابق (Complete)',
                    'معتمد ومصرح للشحن (Cleared)',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => _overallStatus = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _riskLevel,
                  decoration: const InputDecoration(
                    labelText: 'مستوى المخاطر الاستيرادية (Risk Level)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    'منخفض (Low)',
                    'متوسط (Medium)',
                    'مرتفع (High)',
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => setState(() => _riskLevel = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _assessedByCtrl,
                  decoration: const InputDecoration(
                    labelText: 'المراجع المسؤول',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _assessmentNotesCtrl,
            decoration: const InputDecoration(
              labelText: 'ملاحظات التقييم الختامية وتوصيات إدارة الاستيراد',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
