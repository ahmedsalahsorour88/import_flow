import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../models/cargo_insurance_model.dart';
import '../providers/cargo_insurance_provider.dart';

class CargoInsuranceScreen extends ConsumerStatefulWidget {
  final int? initialImportFileId;
  final bool isEmbedded;

  const CargoInsuranceScreen({
    super.key,
    this.initialImportFileId,
    this.isEmbedded = false,
  });

  static void showCreateDialog(BuildContext context, {int? initialImportFileId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CargoInsuranceFormDialog(
        initialImportFileId: initialImportFileId,
      ),
    );
  }

  @override
  ConsumerState<CargoInsuranceScreen> createState() => _CargoInsuranceScreenState();
}

class _CargoInsuranceScreenState extends ConsumerState<CargoInsuranceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _refreshData();
    });
  }

  void _refreshData() {
    ref.read(cargoInsuranceProvider.notifier).fetchCertificates();
    ref.read(importFilesProvider.notifier).fetchImportFiles();
    ref.read(partnersProvider.notifier).fetchPartners();
    ref.read(importCompaniesProvider.notifier).fetchCompanies();
    ref.read(currenciesProvider.notifier).fetchCurrencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditCertificateDialog([CargoInsuranceModel? certificateToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CargoInsuranceFormDialog(
        certificateToEdit: certificateToEdit,
        initialImportFileId: widget.initialImportFileId,
      ),
    );
  }

  void _showViewCertificateDialog(CargoInsuranceModel certificate) {
    showDialog(
      context: context,
      builder: (context) => _CargoInsuranceDetailsDialog(certificate: certificate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final certificatesAsync = ref.watch(cargoInsuranceProvider);

    if (widget.isEmbedded) {
      return _buildMainContent(isArabic, certificatesAsync);
    }

    final tabs = [
      VerticalNavTabItem(
        icon: Icons.shield_rounded,
        titleEn: 'Certificates Registry',
        titleAr: isArabic ? 'سجل شهادات التأمين' : 'Certificates Registry',
      ),
      VerticalNavTabItem(
        icon: Icons.add_moderator_rounded,
        titleEn: 'New Certificate',
        titleAr: isArabic ? 'إصدار وثيقة جديدة' : 'New Certificate',
      ),
    ];

    return VerticalStageScaffold(
      stageCode: 'PHASE-3-INS',
      titleEn: 'Marine & Cargo Insurance Engine',
      titleAr: 'شهادات التأمين على البضائع المشحونة',
      headerIcon: Icons.security_rounded,
      headerColor: AppTheme.cobalt,
      tabs: tabs,
      selectedIndex: 0,
      onTabSelected: (index) {
        if (index == 1) {
          _showAddEditCertificateDialog();
        }
      },
      headerActions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: isArabic ? 'تحديث البيانات' : 'Refresh',
          onPressed: _refreshData,
        ),
      ],
      body: _buildMainContent(isArabic, certificatesAsync),
    );
  }

  Widget _buildMainContent(bool isArabic, AsyncValue<List<CargoInsuranceModel>> certificatesAsync) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
            // Filter and Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'بحث برقم الوثيقة، الشحنة، المستورد، الناقل...'
                            : 'Search certificate code, file, insured, carrier...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (val) {
                        ref.read(cargoInsuranceProvider.notifier).fetchCertificates(
                              search: val,
                              status: _selectedStatusFilter,
                            );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatusFilter,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('الكل / All Statuses')),
                        DropdownMenuItem(value: 'DRAFT', child: Text('مسودة (Draft)')),
                        DropdownMenuItem(value: 'ISSUED', child: Text('معتمدة (Issued)')),
                        DropdownMenuItem(value: 'CANCELLED', child: Text('ملغاة (Cancelled)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatusFilter = val);
                          ref.read(cargoInsuranceProvider.notifier).fetchCertificates(
                                status: val,
                                search: _searchController.text,
                              );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cobalt,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_moderator_rounded, size: 18),
                    label: Text(
                      isArabic ? 'إصدار وثيقة تأمين' : 'New Certificate',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showAddEditCertificateDialog(),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: certificatesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.crimson),
                      const SizedBox(height: 12),
                      Text(
                        isArabic ? 'حدث خطأ أثناء جلب وثائق التأمين: $err' : 'Error loading certificates: $err',
                        style: const TextStyle(color: AppTheme.crimson),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                        onPressed: _refreshData,
                      ),
                    ],
                  ),
                ),
                data: (certificates) {
                  if (certificates.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا توجد شهادات أو وثائق تأمين مسجلة حالياً'
                                : 'No Cargo Insurance Certificates found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isArabic
                                ? 'اضغط على "إصدار وثيقة تأمين" لحساب وتوليد شهادة التأمين البحري/الجوي للشحنة'
                                : 'Click "New Certificate" to calculate and issue marine/air cargo insurance.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
                            icon: const Icon(Icons.add_moderator_rounded),
                            label: Text(isArabic ? 'إصدار وثيقة تأمين جديدة' : 'Create Insurance Certificate'),
                            onPressed: () => _showAddEditCertificateDialog(),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.security_rounded, color: AppTheme.cobalt, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      isArabic ? 'سجل شهادات ووثائق التأمين البحري والجوي' : 'Marine & Cargo Insurance Registry',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cobalt.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isArabic ? '${certificates.length} وثيقة' : '${certificates.length} Certificates',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                                columns: [
                                  DataColumn(label: Text(isArabic ? 'كود الوثيقة' : 'Cert Code', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isArabic ? 'رقم البوليصة' : 'Policy No', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isArabic ? 'المؤمن له (المستورد)' : 'Insured Entity', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isArabic ? 'وسيلة والناقل' : 'Transport / Carrier', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isArabic ? 'خط السير (شحن -> تفريغ)' : 'Route (POL -> POD)', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isArabic ? 'القيمة المؤمنة (110%)' : 'Insured Value (110%)', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isArabic ? 'قسط التأمين الإجمالي' : 'Gross Premium', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isArabic ? 'بند التغطية' : 'Coverage Clause', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isArabic ? 'الحالة' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text(isArabic ? 'الإجراءات' : 'Actions', style: const TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: certificates.map((cert) {
                                  final isIssued = cert.status == 'ISSUED';
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          cert.certificateCode,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                        ),
                                      ),
                                      DataCell(Text(cert.policyNumber ?? '-')),
                                      DataCell(
                                        SizedBox(
                                          width: 140,
                                          child: Text(
                                            cert.insuredEntityName,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${cert.transportMode} • ${cert.carrierName ?? cert.vesselOrFlightNo ?? "-"}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${cert.portOfLoading} ➔ ${cert.portOfDischarge}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${cert.insuredValue.toStringAsFixed(2)} ${cert.currency}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${cert.totalPayablePremium.toStringAsFixed(2)} ${cert.currency}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.blueGrey.shade300),
                                          ),
                                          child: Text(
                                            cert.coverageClause,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (isIssued ? Colors.green : Colors.orange).shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: (isIssued ? Colors.green : Colors.orange).shade300),
                                          ),
                                          child: Text(
                                            isIssued ? '✅ ${isArabic ? "معتمدة" : "Issued"}' : '⏳ ${isArabic ? "مسودة" : "Draft"}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isIssued ? Colors.green.shade900 : Colors.orange.shade900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility_rounded, color: AppTheme.cobalt, size: 18),
                                              tooltip: isArabic ? 'عرض وثيقة التأمين' : 'View Certificate',
                                              onPressed: () => _showViewCertificateDialog(cert),
                                            ),
                                            if (!isIssued) ...[
                                              IconButton(
                                                icon: const Icon(Icons.edit_rounded, color: AppTheme.charcoal, size: 18),
                                                tooltip: isArabic ? 'تعديل' : 'Edit',
                                                onPressed: () => _showAddEditCertificateDialog(cert),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.verified_rounded, color: AppTheme.emerald, size: 18),
                                                tooltip: isArabic ? 'اعتماد وإصدار الوثيقة' : 'Issue Certificate',
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: Text(isArabic ? 'اعتماد وثيقة التأمين' : 'Issue Certificate'),
                                                      content: Text(
                                                        isArabic
                                                            ? 'هل أنت متأكد من اعتماد وإصدار وثيقة التأمين ${cert.certificateCode} رسمياً؟'
                                                            : 'Are you sure you want to officially issue certificate ${cert.certificateCode}?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(ctx, false),
                                                          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
                                                          onPressed: () => Navigator.pop(ctx, true),
                                                          child: Text(isArabic ? 'تأكيد الاعتماد' : 'Confirm Issue', style: const TextStyle(color: Colors.white)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) {
                                                    await ref.read(cargoInsuranceProvider.notifier).issueCertificate(cert.certificateId);
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(isArabic ? '✅ تم اعتماد وإصدار الوثيقة بنجاح!' : 'Certificate issued successfully!'),
                                                          backgroundColor: AppTheme.emerald,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                                              tooltip: isArabic ? 'حذف' : 'Delete',
                                              onPressed: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: Text(isArabic ? 'حذف الوثيقة' : 'Delete Certificate'),
                                                    content: Text(isArabic ? 'هل تريد حذف هذا السجل؟' : 'Delete this record?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                                                        onPressed: () => Navigator.pop(ctx, true),
                                                        child: Text(isArabic ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await ref.read(cargoInsuranceProvider.notifier).deleteCertificate(cert.certificateId);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
  }
}

// =============================================================================
// Form Dialog: Add / Edit & Calculate Insurance Certificate
// =============================================================================
class _CargoInsuranceFormDialog extends ConsumerStatefulWidget {
  final CargoInsuranceModel? certificateToEdit;
  final int? initialImportFileId;
  const _CargoInsuranceFormDialog({this.certificateToEdit, this.initialImportFileId});

  @override
  ConsumerState<_CargoInsuranceFormDialog> createState() => _CargoInsuranceFormDialogState();
}

class _CargoInsuranceFormDialogState extends ConsumerState<_CargoInsuranceFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedImportFileId;
  String _policyType = 'SPECIFIC';
  final TextEditingController _insuredEntityCtrl = TextEditingController();
  final TextEditingController _insuranceCompanyCtrl = TextEditingController(text: 'Misr Insurance Co.');
  final TextEditingController _policyNoCtrl = TextEditingController();

  String _transportMode = 'OCEAN';
  final TextEditingController _carrierCtrl = TextEditingController();
  final TextEditingController _vesselFlightCtrl = TextEditingController();
  final TextEditingController _voyageNoCtrl = TextEditingController();
  final TextEditingController _trackingRefCtrl = TextEditingController();
  final TextEditingController _polCtrl = TextEditingController();
  final TextEditingController _podCtrl = TextEditingController();
  final TextEditingController _finalDestCtrl = TextEditingController(text: 'Cairo / Alexandria, Egypt');

  String _currency = 'USD';
  final TextEditingController _exchangeRateCtrl = TextEditingController(text: '48.50');
  final TextEditingController _invoiceValueCtrl = TextEditingController(text: '0.0');
  final TextEditingController _freightCostCtrl = TextEditingController(text: '0.0');
  final TextEditingController _otherCostsCtrl = TextEditingController(text: '0.0');
  final TextEditingController _markupCtrl = TextEditingController(text: '0.10');

  String _coverageClause = 'ICC_A';
  bool _includeWarAndStrikes = true;
  final TextEditingController _minPremiumCtrl = TextEditingController(text: '30.0');
  final TextEditingController _issuanceFeeCtrl = TextEditingController(text: '15.0');
  final TextEditingController _taxRateCtrl = TextEditingController(text: '0.05');

  final TextEditingController _goodsDescCtrl = TextEditingController();
  final TextEditingController _packageCountCtrl = TextEditingController();
  final TextEditingController _packageTypeCtrl = TextEditingController(text: 'Cartons / Pallets');
  final TextEditingController _grossWeightCtrl = TextEditingController();
  final TextEditingController _surveyAgentCtrl = TextEditingController(text: 'Lloyd\'s Agency Alexandria / Port Said');
  final TextEditingController _claimsPayableAtCtrl = TextEditingController(text: 'Cairo, Egypt');
  final TextEditingController _remarksCtrl = TextEditingController();

  bool _isSaving = false;
  InsuranceCalculationResultModel? _calculationPreview;

  @override
  void initState() {
    super.initState();
    if (widget.certificateToEdit != null) {
      final c = widget.certificateToEdit!;
      _selectedImportFileId = c.importFileId;
      _policyType = c.policyType;
      _insuredEntityCtrl.text = c.insuredEntityName;
      _insuranceCompanyCtrl.text = c.insuranceCompanyName ?? '';
      _policyNoCtrl.text = c.policyNumber ?? '';
      _transportMode = c.transportMode;
      _carrierCtrl.text = c.carrierName ?? '';
      _vesselFlightCtrl.text = c.vesselOrFlightNo ?? '';
      _voyageNoCtrl.text = c.voyageNumber ?? '';
      _trackingRefCtrl.text = c.trackingReference ?? '';
      _polCtrl.text = c.portOfLoading;
      _podCtrl.text = c.portOfDischarge;
      _finalDestCtrl.text = c.finalDestination ?? 'Cairo, Egypt';
      _currency = c.currency;
      _exchangeRateCtrl.text = c.exchangeRate.toString();
      _invoiceValueCtrl.text = c.invoiceValue.toString();
      _freightCostCtrl.text = c.freightCost.toString();
      _otherCostsCtrl.text = c.otherLogisticsCosts.toString();
      _markupCtrl.text = c.markupPercentage.toString();
      _coverageClause = c.coverageClause;
      _includeWarAndStrikes = c.includeWarAndStrikes;
      _minPremiumCtrl.text = c.minimumPremium.toString();
      _issuanceFeeCtrl.text = c.issuanceFee.toString();
      _taxRateCtrl.text = c.taxRate.toString();
      _goodsDescCtrl.text = c.goodsDescription ?? '';
      _packageCountCtrl.text = c.packageCount?.toString() ?? '';
      _packageTypeCtrl.text = c.packageType ?? '';
      _grossWeightCtrl.text = c.grossWeightKg?.toString() ?? '';
      _surveyAgentCtrl.text = c.surveyAgentInDestination ?? '';
      _claimsPayableAtCtrl.text = c.claimsPayableAt ?? 'Cairo, Egypt';
      _remarksCtrl.text = c.remarks ?? '';
    } else if (widget.initialImportFileId != null) {
      _selectedImportFileId = widget.initialImportFileId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoFillFromImportFile(widget.initialImportFileId!);
      });
    }
    _runLiveCalculation();
  }

  void _autoFillFromImportFile(int fileId) {
    final files = ref.read(importFilesProvider).value ?? [];
    final file = files.where((f) => f.importFileId == fileId).firstOrNull;
    if (file != null) {
      _onImportFileSelected(file);
    }
  }

  void _runLiveCalculation() {
    final inv = double.tryParse(_invoiceValueCtrl.text) ?? 0.0;
    final frt = double.tryParse(_freightCostCtrl.text) ?? 0.0;
    final oth = double.tryParse(_otherCostsCtrl.text) ?? 0.0;
    final markup = double.tryParse(_markupCtrl.text) ?? 0.10;
    final minPrem = double.tryParse(_minPremiumCtrl.text) ?? 30.0;
    final fee = double.tryParse(_issuanceFeeCtrl.text) ?? 15.0;
    final tax = double.tryParse(_taxRateCtrl.text) ?? 0.05;

    final cif = inv + frt + oth;
    final insured = cif * (1.0 + markup);

    double baseRate = 0.0025;
    if (_coverageClause == 'AIR_ALL_RISKS') baseRate = 0.0020;
    if (_coverageClause == 'ICC_B') baseRate = 0.0015;
    if (_coverageClause == 'ICC_C') baseRate = 0.0010;

    final basePrem = insured * baseRate;
    final warRate = _includeWarAndStrikes ? 0.0005 : 0.0;
    final warPrem = insured * warRate;
    final netPrem = (basePrem + warPrem) > minPrem ? (basePrem + warPrem) : minPrem;
    final taxAmt = (netPrem + fee) * tax;
    final totalPayable = netPrem + fee + taxAmt;

    setState(() {
      _calculationPreview = InsuranceCalculationResultModel(
        cifValue: cif,
        markupPercentage: markup,
        insuredValue: insured,
        coverageClause: _coverageClause,
        baseRate: baseRate,
        basePremium: basePrem,
        warRate: warRate,
        warStrikesPremium: warPrem,
        netPremium: netPrem,
        issuanceFee: fee,
        taxRate: tax,
        taxAmount: taxAmt,
        totalPayablePremium: totalPayable,
        currency: _currency,
      );
    });
  }

  void _onImportFileSelected(ImportFileModel? file) {
    if (file == null) return;
    setState(() {
      _selectedImportFileId = file.importFileId;
      _insuredEntityCtrl.text = file.companyName;
      if (file.portOfLoading != null && file.portOfLoading!.isNotEmpty) {
        _polCtrl.text = file.portOfLoading!;
      }
      if (file.portOfDischarge != null && file.portOfDischarge!.isNotEmpty) {
        _podCtrl.text = file.portOfDischarge!;
      }
      if (file.estimatedCostCurrency.isNotEmpty) {
        _currency = file.estimatedCostCurrency;
      }
      if (file.invoicesData.isNotEmpty) {
        final totalInv = file.invoicesData.fold<double>(0.0, (sum, item) => sum + item.amount);
        _invoiceValueCtrl.text = totalInv.toStringAsFixed(2);
      }
    });
    _runLiveCalculation();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final importFiles = ref.watch(importFilesProvider).asData?.value ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 1050,
        height: 760,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.charcoal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppTheme.cobalt, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.certificateToEdit == null
                              ? (isArabic ? 'إصدار شهادة تأمين بضائع مشحونة (Cargo Insurance Certificate)' : 'New Cargo Insurance Certificate')
                              : (isArabic ? 'تعديل وثيقة التأمين ${widget.certificateToEdit!.certificateCode}' : 'Edit Certificate ${widget.certificateToEdit!.certificateCode}'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          isArabic
                              ? 'حساب القيمة المؤمنة (110% CIF) وقسط التأمين طبقاً لشروط معهد المكتتبين بلندن (ICC Clauses)'
                              : '110% CIF Insured Value & Gross Premium Engine (London Institute Cargo Clauses)',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Workspace
            Expanded(
              child: Form(
                key: _formKey,
                child: Row(
                  children: [
                    // Left Column: Inputs & Clauses
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Linked Import File
                            SearchableDropdownField<int>(
                              value: _selectedImportFileId,
                              labelText: isArabic ? 'ربط ملف الشحنة الاستيرادية *' : 'Link Import File *',
                              hintText: isArabic ? 'اختر ملف الشحنة...' : 'Select Import File...',
                              items: importFiles
                                  .map((f) => SearchableDropdownItem(
                                        value: f.importFileId,
                                        label: '${f.importFileCode} - ${f.companyName} (${f.incotermCode})',
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                final selected = importFiles.firstWhere((f) => f.importFileId == val);
                                _onImportFileSelected(selected);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 2. Insured Entity & Policy Type
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _insuredEntityCtrl,
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'المؤمن له (المستورد / Consignee) *' : 'Insured Entity *',
                                      prefixIcon: const Icon(Icons.person_pin_rounded, size: 18),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? (isArabic ? 'اسم المستورد مطلوب' : 'Required') : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: _policyType,
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'نوع الوثيقة' : 'Policy Type',
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'SPECIFIC', child: Text('محددة لشحنة (Specific)')),
                                      DropdownMenuItem(value: 'OPEN_DECLARATION', child: Text('وثيقة مفتوحة (Open Policy)')),
                                    ],
                                    onChanged: (v) => setState(() => _policyType = v ?? 'SPECIFIC'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 3. Insurance Provider & Policy Number
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _insuranceCompanyCtrl,
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'شركة التأمين المصدرة' : 'Insurance Company',
                                      prefixIcon: const Icon(Icons.assured_workload_rounded, size: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _policyNoCtrl,
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'رقم وثيقة / بوليصة التأمين' : 'Policy / Cert Number',
                                      prefixIcon: const Icon(Icons.confirmation_number_rounded, size: 18),
                                      hintText: 'e.g. POL-2026-98124',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // 4. Voyage & Transport Details
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic ? 'بيانات الشحن والرحلة وخط السير' : 'Voyage & Transport Details',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.cobalt),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _transportMode,
                                          decoration: InputDecoration(
                                            labelText: isArabic ? 'وسيلة النقل' : 'Transport Mode',
                                            isDense: true,
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'OCEAN', child: Text('🚢 بحري (Ocean)')),
                                            DropdownMenuItem(value: 'AIR', child: Text('✈️ جوي (Air)')),
                                            DropdownMenuItem(value: 'ROAD', child: Text('🚛 بري (Road)')),
                                          ],
                                          onChanged: (v) {
                                            setState(() {
                                              _transportMode = v ?? 'OCEAN';
                                              if (_transportMode == 'AIR') _coverageClause = 'AIR_ALL_RISKS';
                                              if (_transportMode == 'OCEAN' && _coverageClause == 'AIR_ALL_RISKS') _coverageClause = 'ICC_A';
                                            });
                                            _runLiveCalculation();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _carrierCtrl,
                                          decoration: InputDecoration(
                                            labelText: isArabic ? 'الخط الملاحي / الناقل' : 'Carrier',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _vesselFlightCtrl,
                                          decoration: InputDecoration(
                                            labelText: isArabic ? 'اسم السفينة / الرحلة' : 'Vessel / Flight No',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _polCtrl,
                                          decoration: InputDecoration(
                                            labelText: isArabic ? 'ميناء الشحن (POL) *' : 'Port of Loading *',
                                            isDense: true,
                                          ),
                                          validator: (v) => v == null || v.trim().isEmpty ? (isArabic ? 'مطلوب' : 'Required') : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _podCtrl,
                                          decoration: InputDecoration(
                                            labelText: isArabic ? 'ميناء الوصول (POD) *' : 'Port of Discharge *',
                                            isDense: true,
                                          ),
                                          validator: (v) => v == null || v.trim().isEmpty ? (isArabic ? 'مطلوب' : 'Required') : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _trackingRefCtrl,
                                          decoration: InputDecoration(
                                            labelText: isArabic ? 'رقم بوليصة الشحن (B/L)' : 'B/L / AWB No',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 5. Financial Inputs (Invoice + Freight + Markup)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _invoiceValueCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'قيمة الفاتورة (FOB) *' : 'Invoice Value (FOB) *',
                                      prefixIcon: const Icon(Icons.receipt_rounded, size: 18),
                                    ),
                                    onChanged: (_) => _runLiveCalculation(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _freightCostCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'تكلفة النولون / الشحن' : 'Freight Cost',
                                      prefixIcon: const Icon(Icons.directions_boat_rounded, size: 18),
                                    ),
                                    onChanged: (_) => _runLiveCalculation(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _currency,
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'العملة' : 'Currency',
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'USD', child: Text('USD - دولار أمريكي')),
                                      DropdownMenuItem(value: 'EUR', child: Text('EUR - يورو أوروبي')),
                                      DropdownMenuItem(value: 'EGP', child: Text('EGP - جنيه مصري')),
                                      DropdownMenuItem(value: 'CNY', child: Text('CNY - يوان صيني')),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _currency = v ?? 'USD');
                                      _runLiveCalculation();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 6. Coverage Clauses & War/Strikes Toggle
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic ? 'شروط التغطية التأمينية وملاحق المخاطر الإضافية' : 'Coverage Clauses & Risk Extensions',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.emerald),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _coverageClause,
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'بند التغطية (Institute Cargo Clauses)' : 'Coverage Clause',
                                      isDense: true,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'ICC_A',
                                        child: Text('ICC (A) - All Risks (شاملة - أعلى تغطية 0.25%)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'AIR_ALL_RISKS',
                                        child: Text('Institute Cargo Clauses (Air) - جوي شامل (0.20%)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'ICC_B',
                                        child: Text('ICC (B) - Intermediate (تغطية متوسطة 0.15%)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'ICC_C',
                                        child: Text('ICC (C) - Minimum (الحد الأدنى - حوادث جسيمة 0.10%)'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _coverageClause = v ?? 'ICC_A');
                                      _runLiveCalculation();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      isArabic
                                          ? 'تغطية مخاطر الحروب والإضرابات (War & Strikes Clauses +0.05%)'
                                          : 'Include War & Strikes Clauses (+0.05%)',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      isArabic
                                          ? 'ملحق إلزامي للاعتمادات المستندية والتخليص الجمركي للشحنات البحرية'
                                          : 'Mandatory add-on for Letter of Credit (L/C) compliance',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    value: _includeWarAndStrikes,
                                    activeColor: AppTheme.emerald,
                                    onChanged: (v) {
                                      setState(() => _includeWarAndStrikes = v ?? true);
                                      _runLiveCalculation();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Column: Live Calculation Matrix & Cargo Details
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.cloudWhite.withOpacity(0.5),
                          border: Border(left: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? '📊 محاكاة وحساب قسط التأمين الفوري' : '📊 Real-Time Premium Breakdown',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
                              ),
                              const SizedBox(height: 12),

                              if (_calculationPreview != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _buildBreakdownRow(
                                        isArabic ? 'قيمة البضاعة (CIF Base):' : 'CIF Base Value:',
                                        '${_calculationPreview!.cifValue.toStringAsFixed(2)} $_currency',
                                        isBold: false,
                                      ),
                                      const Divider(height: 10),
                                      _buildBreakdownRow(
                                        isArabic ? 'القيمة المؤمنة (110% CIF):' : 'Insured Value (110%):',
                                        '${_calculationPreview!.insuredValue.toStringAsFixed(2)} $_currency',
                                        isBold: true,
                                        valueColor: AppTheme.cobalt,
                                      ),
                                      const Divider(height: 10),
                                      _buildBreakdownRow(
                                        isArabic ? 'قسط التأمين الأساسي (${(_calculationPreview!.baseRate * 100).toStringAsFixed(2)}%):' : 'Base Premium:',
                                        '${_calculationPreview!.basePremium.toStringAsFixed(2)} $_currency',
                                        isBold: false,
                                      ),
                                      if (_includeWarAndStrikes) ...[
                                        const SizedBox(height: 4),
                                        _buildBreakdownRow(
                                          isArabic ? 'ملحق الحرب والإضرابات (0.05%):' : 'War & Strikes Add-on:',
                                          '+ ${_calculationPreview!.warStrikesPremium.toStringAsFixed(2)} $_currency',
                                          isBold: false,
                                          valueColor: Colors.deepOrange,
                                        ),
                                      ],
                                      const Divider(height: 10),
                                      _buildBreakdownRow(
                                        isArabic ? 'صافي القسط بعد الحد الأدنى:' : 'Net Premium (Min Floor):',
                                        '${_calculationPreview!.netPremium.toStringAsFixed(2)} $_currency',
                                        isBold: false,
                                      ),
                                      const SizedBox(height: 4),
                                      _buildBreakdownRow(
                                        isArabic ? 'رسوم إصدار ودمغات إدارية:' : 'Issuance Fee:',
                                        '+ ${_calculationPreview!.issuanceFee.toStringAsFixed(2)} $_currency',
                                        isBold: false,
                                      ),
                                      const SizedBox(height: 4),
                                      _buildBreakdownRow(
                                        isArabic ? 'الضرائب والدمغات (5%):' : 'Taxes / Stamp Duty (5%):',
                                        '+ ${_calculationPreview!.taxAmount.toStringAsFixed(2)} $_currency',
                                        isBold: false,
                                      ),
                                      const Divider(height: 14, thickness: 1.5),
                                      _buildBreakdownRow(
                                        isArabic ? 'إجمالي قسط التأمين المستحق:' : 'Total Payable Premium:',
                                        '${_calculationPreview!.totalPayablePremium.toStringAsFixed(2)} $_currency',
                                        isBold: true,
                                        valueColor: AppTheme.emerald,
                                        fontSize: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Cargo Specifications
                              Text(
                                isArabic ? 'وصف البضاعة والطرود' : 'Cargo Description & Packages',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _goodsDescCtrl,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: isArabic ? 'الوصف الدقيق للبضاعة' : 'Goods Description',
                                  hintText: isArabic ? 'مثال: قطع غيار ماكينات صناعية...' : 'e.g. Industrial machinery parts',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _packageCountCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: isArabic ? 'عدد الطرود' : 'Packages',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _grossWeightCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: isArabic ? 'الوزن القائم (كجم)' : 'Gross Wt (KG)',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Action Buttons
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.emerald,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: _isSaving
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.check_circle_rounded),
                                  label: Text(
                                    _isSaving
                                        ? (isArabic ? 'جاري حفظ الوثيقة...' : 'Saving...')
                                        : (isArabic ? 'حفظ وإصدار مسودة الوثيقة' : 'Save Certificate Draft'),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: _isSaving ? null : _saveCertificate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isBold = false, Color? valueColor, double fontSize = 12}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.charcoal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppTheme.charcoal,
          ),
        ),
      ],
    );
  }

  Future<void> _saveCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final payload = {
      'import_file_id': _selectedImportFileId,
      'policy_type': _policyType,
      'insured_entity_name': _insuredEntityCtrl.text.trim(),
      'insurance_company_name': _insuranceCompanyCtrl.text.trim(),
      'policy_number': _policyNoCtrl.text.trim().isNotEmpty ? _policyNoCtrl.text.trim() : null,
      'transport_mode': _transportMode,
      'carrier_name': _carrierCtrl.text.trim().isNotEmpty ? _carrierCtrl.text.trim() : null,
      'vessel_or_flight_no': _vesselFlightCtrl.text.trim().isNotEmpty ? _vesselFlightCtrl.text.trim() : null,
      'voyage_number': _voyageNoCtrl.text.trim().isNotEmpty ? _voyageNoCtrl.text.trim() : null,
      'tracking_reference': _trackingRefCtrl.text.trim().isNotEmpty ? _trackingRefCtrl.text.trim() : null,
      'port_of_loading': _polCtrl.text.trim(),
      'port_of_discharge': _podCtrl.text.trim(),
      'final_destination': _finalDestCtrl.text.trim(),
      'currency': _currency,
      'exchange_rate': double.tryParse(_exchangeRateCtrl.text) ?? 1.0,
      'invoice_value': double.tryParse(_invoiceValueCtrl.text) ?? 0.0,
      'freight_cost': double.tryParse(_freightCostCtrl.text) ?? 0.0,
      'other_logistics_costs': double.tryParse(_otherCostsCtrl.text) ?? 0.0,
      'markup_percentage': double.tryParse(_markupCtrl.text) ?? 0.10,
      'coverage_clause': _coverageClause,
      'include_war_and_strikes': _includeWarAndStrikes,
      'minimum_premium': double.tryParse(_minPremiumCtrl.text) ?? 30.0,
      'issuance_fee': double.tryParse(_issuanceFeeCtrl.text) ?? 15.0,
      'tax_rate': double.tryParse(_taxRateCtrl.text) ?? 0.05,
      'goods_description': _goodsDescCtrl.text.trim().isNotEmpty ? _goodsDescCtrl.text.trim() : null,
      'package_count': int.tryParse(_packageCountCtrl.text),
      'package_type': _packageTypeCtrl.text.trim().isNotEmpty ? _packageTypeCtrl.text.trim() : null,
      'gross_weight_kg': double.tryParse(_grossWeightCtrl.text),
      'survey_agent_in_destination': _surveyAgentCtrl.text.trim().isNotEmpty ? _surveyAgentCtrl.text.trim() : null,
      'claims_payable_at': _claimsPayableAtCtrl.text.trim().isNotEmpty ? _claimsPayableAtCtrl.text.trim() : null,
      'remarks': _remarksCtrl.text.trim().isNotEmpty ? _remarksCtrl.text.trim() : null,
    };

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (widget.certificateToEdit == null) {
        await ref.read(cargoInsuranceProvider.notifier).createCertificate(payload);
        messenger.showSnackBar(
          SnackBar(
            content: Text(isArabic ? '✅ تم إنشاء وثيقة التأمين بنجاح!' : 'Insurance Certificate created!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      } else {
        await ref.read(cargoInsuranceProvider.notifier).updateCertificate(widget.certificateToEdit!.certificateId, payload);
        messenger.showSnackBar(
          SnackBar(
            content: Text(isArabic ? '✅ تم تحديث وثيقة التأمين بنجاح!' : 'Insurance Certificate updated!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(isArabic ? '❌ فشل حفظ الوثيقة: $e' : 'Failed to save certificate: $e'),
          backgroundColor: AppTheme.crimson,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// =============================================================================
// Details Dialog: Official Printable Marine Insurance Certificate Preview
// =============================================================================
class _CargoInsuranceDetailsDialog extends StatelessWidget {
  final CargoInsuranceModel certificate;
  const _CargoInsuranceDetailsDialog({required this.certificate});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        height: 780,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Official Certificate Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cobalt.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppTheme.cobalt, size: 32),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CERTIFICATE OF CARGO INSURANCE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1, color: AppTheme.charcoal),
                        ),
                        Text(
                          'شهادة التأمين الرسمية على البضائع المشحونة • ${certificate.certificateCode}',
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: certificate.status == 'ISSUED' ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: certificate.status == 'ISSUED' ? Colors.green : Colors.orange),
                  ),
                  child: Text(
                    certificate.status == 'ISSUED' ? 'OFFICIALLY ISSUED' : 'DRAFT CERTIFICATE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: certificate.status == 'ISSUED' ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1.5),

            // Certificate Body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid Section: Parties & Transport
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            title: '1. INSURED & POLICY DETAILS / بيانات المؤمن له',
                            items: [
                              MapEntry('Insured (Consignee):', certificate.insuredEntityName),
                              MapEntry('Insurance Company:', certificate.insuranceCompanyName ?? 'Misr Insurance'),
                              MapEntry('Policy Number:', certificate.policyNumber ?? '-'),
                              MapEntry('Policy Type:', certificate.policyType),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            title: '2. VOYAGE & ROUTE / خط السير والناقل',
                            items: [
                              MapEntry('Transport Mode:', certificate.transportMode),
                              MapEntry('Vessel / Flight:', '${certificate.vesselOrFlightNo ?? "-"} (Voyage: ${certificate.voyageNumber ?? "-"})'),
                              MapEntry('Port of Loading (POL):', certificate.portOfLoading),
                              MapEntry('Port of Discharge (POD):', certificate.portOfDischarge),
                              MapEntry('Tracking / B/L Ref:', certificate.trackingReference ?? '-'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Grid Section: Valuation & Premium
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            title: '3. VALUATION & INSURED SUM / القيمة التأمينية',
                            items: [
                              MapEntry('Commercial Invoice (FOB):', '${certificate.invoiceValue.toStringAsFixed(2)} ${certificate.currency}'),
                              MapEntry('Freight & Logistics:', '${certificate.freightCost.toStringAsFixed(2)} ${certificate.currency}'),
                              MapEntry('CIF Base Value:', '${certificate.cifValue.toStringAsFixed(2)} ${certificate.currency}'),
                              MapEntry('Insured Sum (110% CIF):', '${certificate.insuredValue.toStringAsFixed(2)} ${certificate.currency}'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            title: '4. PREMIUM BREAKDOWN / تفاصيل القسط',
                            items: [
                              MapEntry('Coverage Clause:', certificate.coverageClause),
                              MapEntry('Base Premium:', '${certificate.basePremium.toStringAsFixed(2)} ${certificate.currency}'),
                              MapEntry('War & Strikes Add-on:', '${certificate.warStrikesPremium.toStringAsFixed(2)} ${certificate.currency}'),
                              MapEntry('Issuance Fee & Taxes:', '${(certificate.issuanceFee + certificate.taxAmount).toStringAsFixed(2)} ${certificate.currency}'),
                              MapEntry('Total Payable Gross Premium:', '${certificate.totalPayablePremium.toStringAsFixed(2)} ${certificate.currency}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Cargo Specs & Legal Clauses
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '5. CARGO SPECIFICATIONS & CLAUSES / تفاصيل البضاعة والشروط القانونية',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.charcoal),
                          ),
                          const SizedBox(height: 6),
                          Text('• Description: ${certificate.goodsDescription ?? "General Commercial Cargo"}', style: const TextStyle(fontSize: 12)),
                          Text('• Packages & Weight: ${certificate.packageCount ?? "-"} ${certificate.packageType ?? "Packages"} • Gross Wt: ${certificate.grossWeightKg ?? "-"} KG', style: const TextStyle(fontSize: 12)),
                          Text("• Survey / Claims Settling Agent: ${certificate.surveyAgentInDestination ?? "Local Lloyd's Agent / Egypt"}", style: const TextStyle(fontSize: 12)),
                          Text('• Claims Payable At: ${certificate.claimsPayableAt ?? "Cairo, Egypt"} in currency ${certificate.currency}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 16),

            // Modal Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'وثيقة رسمية معتمدة للتخليص الجمركي والاعتمادات المستندية' : 'Official Document for Customs Clearance & Bank Form 4',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoal, foregroundColor: Colors.white),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: Text(isArabic ? 'طباعة / تصدير PDF' : 'Print / Export PDF'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isArabic ? '🖨️ جاهز للإرسال والطباعة الرسمية' : 'Ready for printing / PDF generation'),
                        backgroundColor: AppTheme.cobalt,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<MapEntry<String, String>> items}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.cobalt),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.key, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  Text(item.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
