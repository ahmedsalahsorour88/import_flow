import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../../core/widgets/smart_upload_button.dart';
import '../../../core/widgets/vertical_stage_scaffold.dart';
import '../../cargo_shipping/providers/cargo_shipping_provider.dart';
import '../../currencies/providers/currencies_provider.dart';
import '../../external_service_providers/providers/partners_provider.dart';
import '../../freight_booking/providers/freight_booking_provider.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../import_files/models/import_file_model.dart';
import '../../import_files/providers/import_files_provider.dart';
import '../../purchase_orders/providers/purchase_orders_provider.dart';
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
  bool _showInactive = false;

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
    ref.read(freightBookingProvider.notifier).fetchBookings();
    ref.read(cargoShippingProvider.notifier).fetchRecords();
    ref.read(purchaseOrdersProvider.notifier).fetchPurchaseOrders();
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
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final certificatesAsync = ref.watch(cargoInsuranceProvider);

    if (widget.isEmbedded) {
      return _buildMainContent(isArabic, certificatesAsync);
    }

    final tabs = [
      const VerticalNavTabItem(
        icon: Icons.shield_rounded,
        titleEn: 'Certificates Registry',
        titleAr: 'سجل شهادات التأمين',
      ),
      const VerticalNavTabItem(
        icon: Icons.add_moderator_rounded,
        titleEn: 'New Certificate',
        titleAr: 'إصدار وثيقة جديدة',
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
        SmartUploadButton(
          module: SmartUploadModule.cargoShipping,
          label: isArabic ? 'رفع واستخراج وثيقة التأمين / البوليصة الذكي' : 'Smart Upload & AI Extractor',
          onDataExtracted: (result) {
            final fields = result.extractedFields;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isArabic
                      ? '✅ تم استخراج مستند الشحن / التأمين: ${fields['bl_number'] ?? fields['policy_number'] ?? 'مكتمل'}'
                      : 'Extracted: ${fields['bl_number'] ?? fields['policy_number'] ?? 'Done'}',
                ),
                backgroundColor: AppTheme.emerald,
                duration: const Duration(seconds: 4),
              ),
            );
            _showAddEditCertificateDialog();
          },
        ),
        const SizedBox(width: 8),
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
    final l = context.l10n;

    return certificatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cobalt)),
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
        final totalCount = certificates.length;
        final issuedCount = certificates.where((c) => c.status == 'ISSUED').length;
        final totalInsuredValue = certificates.fold<double>(0.0, (sum, c) => sum + c.insuredValue);
        final totalPremiumsPaid = certificates.fold<double>(0.0, (sum, c) => sum + c.totalPayablePremium);

        final query = _searchController.text.trim().toLowerCase();
        final filteredCertificates = certificates.where((c) {
          if (!_showInactive && !c.isActive) return false;
          if (_showInactive && c.isActive) return false;
          if (_selectedStatusFilter != 'All' && c.status != _selectedStatusFilter) return false;
          if (query.isNotEmpty) {
            final code = c.certificateCode.toLowerCase();
            final pol = (c.policyNumber ?? '').toLowerCase();
            final entity = c.insuredEntityName.toLowerCase();
            final carrier = (c.carrierName ?? '').toLowerCase();
            final file = c.importFileId != null ? 'file #${c.importFileId}' : '';
            final ports = '${c.portOfLoading} ${c.portOfDischarge}'.toLowerCase();
            if (!code.contains(query) &&
                !pol.contains(query) &&
                !entity.contains(query) &&
                !carrier.contains(query) &&
                !file.contains(query) &&
                !ports.contains(query)) {
              return false;
            }
          }
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Top Charcoal Summary Bar ─────────────────────────────────────
            Container(
              color: AppTheme.charcoal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _histStatCard(
                    icon: Icons.shield_rounded,
                    label: isArabic ? 'إجمالي الوثائق' : 'Total Policies',
                    value: '$totalCount',
                    color: AppTheme.cobalt,
                  ),
                  const SizedBox(width: 10),
                  _histStatCard(
                    icon: Icons.check_circle_rounded,
                    label: isArabic ? 'وثائق معتمدة' : 'Issued & Valid',
                    value: '$issuedCount',
                    color: AppTheme.emerald,
                  ),
                  const SizedBox(width: 10),
                  _histStatCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: isArabic ? 'إجمالي القيمة المؤمنة' : 'Total Insured',
                    value: '\$${totalInsuredValue.toStringAsFixed(0)}',
                    color: Colors.orange.shade300,
                  ),
                  const SizedBox(width: 10),
                  _histStatCard(
                    icon: Icons.payments_rounded,
                    label: isArabic ? 'إجمالي الأقساط' : 'Total Premiums',
                    value: '\$${totalPremiumsPaid.toStringAsFixed(0)}',
                    color: Colors.purple.shade300,
                  ),
                  const Spacer(),
                  // Refresh button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(isArabic ? 'تحديث السجل' : 'Refresh Registry', style: const TextStyle(fontSize: 13)),
                    onPressed: _refreshData,
                  ),
                  const SizedBox(width: 10),
                  // New Certificate button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add_moderator_rounded, size: 18),
                    label: Text(
                      isArabic ? 'إصدار وثيقة تأمين جديدة' : 'New Certificate',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _showAddEditCertificateDialog(),
                  ),
                ],
              ),
            ),

            // ─── Data Actions Toolbar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: MasterDataToolbarWidget(
                moduleEndpoint: 'cargo-insurance',
                title: 'Cargo_Insurance_Certificates',
                onRefreshNeeded: _refreshData,
              ),
            ),

            // ─── Search & Filter Bar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'بحث برقم الوثيقة، رقم البوليصة، المستورد، شركة التأمين، الميناء...'
                            : 'Search certificate code, policy, insured, insurance company, port...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.cobalt),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cobalt, width: 1.5)),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Filter Chips
                  Row(
                    children: [
                      _buildStatusFilterChip('All', isArabic ? 'الكل' : 'All'),
                      const SizedBox(width: 6),
                      _buildStatusFilterChip('ISSUED', isArabic ? 'معتمدة' : 'Issued', AppTheme.emerald),
                      const SizedBox(width: 6),
                      _buildStatusFilterChip('DRAFT', isArabic ? 'مسودة' : 'Draft', Colors.orange),
                      const SizedBox(width: 6),
                      _buildStatusFilterChip('CANCELLED', isArabic ? 'ملغاة' : 'Cancelled', AppTheme.crimson),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Show Inactive Toggle
                  FilterChip(
                    avatar: Icon(
                      _showInactive ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: _showInactive ? AppTheme.crimson : Colors.grey,
                    ),
                    label: Text(
                      _showInactive ? (isArabic ? 'عرض المحذوف' : 'Deleted') : (isArabic ? 'إخفاء المحذوف' : 'Hide Deleted'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _showInactive ? AppTheme.crimson : Colors.grey.shade700,
                        fontWeight: _showInactive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: _showInactive,
                    selectedColor: AppTheme.crimson.withOpacity(0.12),
                    checkmarkColor: AppTheme.crimson,
                    onSelected: (val) => setState(() => _showInactive = val),
                  ),
                  const SizedBox(width: 10),
                  // Count chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredCertificates.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Data Table Card ──────────────────────────────────────────────
            Expanded(
              child: filteredCertificates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty || _selectedStatusFilter != 'All'
                                ? (isArabic ? 'لم يتم العثور على وثائق تطابق البحث' : l.noResultsFound)
                                : (isArabic ? 'لا توجد وثائق تأمين مسجلة حالياً' : l.noDataFound),
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isArabic
                                ? 'اضغط على "إصدار وثيقة تأمين جديدة" لحساب وتوليد شهادة التأمين البحري/الجوي'
                                : 'Click "New Certificate" to calculate and issue marine/air cargo insurance.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
                            icon: const Icon(Icons.add_moderator_rounded),
                            label: Text(isArabic ? 'إصدار وثيقة تأمين جديدة' : 'Create Insurance Certificate'),
                            onPressed: () => _showAddEditCertificateDialog(),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 48,
                            dataRowMinHeight: 52,
                            dataRowMaxHeight: 60,
                            horizontalMargin: 16,
                            columnSpacing: 18,
                            dividerThickness: 0.5,
                            headingRowColor: WidgetStateProperty.all(AppTheme.charcoal),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            columns: [
                              const DataColumn(label: Text('#')),
                              DataColumn(label: Text(isArabic ? 'كود الوثيقة' : 'Cert Code')),
                              DataColumn(label: Text(isArabic ? 'تاريخ الإصدار' : 'Issue Date')),
                              DataColumn(label: Text(isArabic ? 'رقم البوليصة / الشحنة' : 'Policy / File')),
                              DataColumn(label: Text(isArabic ? 'المؤمن له (المستورد)' : 'Insured Entity')),
                              DataColumn(label: Text(isArabic ? 'شركة التأمين' : 'Insurance Co')),
                              DataColumn(label: Text(isArabic ? 'الوسيلة وخط السير' : 'Transport / Route')),
                              DataColumn(label: Text(isArabic ? 'القيمة المؤمنة (110%)' : 'Insured Value')),
                              DataColumn(label: Text(isArabic ? 'بند التغطية' : 'Coverage Clause')),
                              DataColumn(label: Text(isArabic ? 'إجمالي القسط المستحق' : 'Gross Premium')),
                              DataColumn(label: Text(isArabic ? 'الحالة' : 'Status')),
                              DataColumn(label: Text(isArabic ? 'الإجراءات' : 'Actions')),
                            ],
                            rows: filteredCertificates.asMap().entries.map((entry) {
                              final idx = entry.key + 1;
                              final cert = entry.value;
                              final isIssued = cert.status == 'ISSUED';
                              final isCancelled = cert.status == 'CANCELLED';

                              return DataRow(
                                cells: [
                                  // 1. Index
                                  DataCell(Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),

                                  // 2. Cert Code
                                  DataCell(
                                    InkWell(
                                      onTap: () => _showViewCertificateDialog(cert),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.shield_rounded, size: 14, color: AppTheme.cobalt),
                                          const SizedBox(width: 4),
                                          Text(
                                            cert.certificateCode,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // 3. Issue Date
                                  DataCell(
                                    Text(
                                      cert.issuedAt?.substring(0, 10) ?? cert.createdAt.substring(0, 10),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),

                                  // 4. Policy / File
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          cert.policyNumber ?? '-',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        if (cert.importFileId != null)
                                          Container(
                                            margin: const EdgeInsets.only(top: 2),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppTheme.cobalt.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '📁 FILE #${cert.importFileId}',
                                              style: const TextStyle(fontSize: 10, color: AppTheme.cobalt, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // 5. Insured Entity
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        cert.insuredEntityName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                    ),
                                  ),

                                  // 6. Insurance Company
                                  DataCell(
                                    SizedBox(
                                      width: 130,
                                      child: Text(
                                        cert.insuranceCompanyName ?? 'Misr Insurance Co.',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                      ),
                                    ),
                                  ),

                                  // 7. Transport / Route
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              cert.transportMode == 'AIR' ? Icons.flight_takeoff_rounded : Icons.directions_boat_rounded,
                                              size: 13,
                                              color: AppTheme.charcoal,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(cert.transportMode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        Text(
                                          '${cert.portOfLoading} ➔ ${cert.portOfDischarge}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 8. Insured Value (110%)
                                  DataCell(
                                    Text(
                                      '${cert.insuredValue.toStringAsFixed(2)} ${cert.currency}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald, fontSize: 12),
                                    ),
                                  ),

                                  // 9. Coverage Clause
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.blueGrey.shade300),
                                      ),
                                      child: Text(
                                        cert.coverageClause,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                                      ),
                                    ),
                                  ),

                                  // 10. Total Premium
                                  DataCell(
                                    Text(
                                      '${cert.totalPayablePremium.toStringAsFixed(2)} ${cert.currency}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal, fontSize: 12),
                                    ),
                                  ),

                                  // 11. Status Badge
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isIssued
                                            ? Colors.green.shade50
                                            : (isCancelled ? Colors.red.shade50 : Colors.orange.shade50),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isIssued
                                              ? Colors.green.shade300
                                              : (isCancelled ? Colors.red.shade300 : Colors.orange.shade300),
                                        ),
                                      ),
                                      child: Text(
                                        isIssued
                                            ? (isArabic ? '✅ معتمدة' : 'Issued')
                                            : (isCancelled ? (isArabic ? '🚫 ملغاة' : 'Cancelled') : (isArabic ? '⏳ مسودة' : 'Draft')),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isIssued
                                              ? Colors.green.shade900
                                              : (isCancelled ? Colors.red.shade900 : Colors.orange.shade900),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 12. Actions
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RowActionsPill(
                                          onView: () => _showViewCertificateDialog(cert),
                                          onEdit: isIssued ? null : () => _showAddEditCertificateDialog(cert),
                                          onPrint: () => _showViewCertificateDialog(cert),
                                          onDelete: () => _confirmDeleteCertificate(cert),
                                          viewTooltip: isArabic ? 'عرض الشهادة الرسمية' : 'View Certificate',
                                          editTooltip: isArabic ? 'تعديل الوثيقة' : 'Edit',
                                          printTooltip: isArabic ? 'طباعة شهادة التأمين' : 'Print Certificate',
                                          deleteTooltip: isArabic ? 'حذف / إلغاء' : 'Delete',
                                        ),
                                        if (!isIssued && !isCancelled) ...[
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(Icons.verified_rounded, color: AppTheme.emerald, size: 18),
                                            tooltip: isArabic ? 'اعتماد وإصدار الوثيقة' : 'Issue Certificate',
                                            onPressed: () => _confirmIssueCertificate(cert),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusFilterChip(String status, String label, [Color? activeColor]) {
    final isSelected = _selectedStatusFilter == status;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppTheme.charcoal,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor ?? AppTheme.cobalt,
      checkmarkColor: Colors.white,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedStatusFilter = status);
        }
      },
    );
  }

  Widget _histStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmIssueCertificate(CargoInsuranceModel cert) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppTheme.emerald, size: 24),
            const SizedBox(width: 8),
            Text(isArabic ? 'اعتماد وثيقة التأمين' : 'Issue Certificate'),
          ],
        ),
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
  }

  Future<void> _confirmDeleteCertificate(CargoInsuranceModel cert) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 24),
            const SizedBox(width: 8),
            Text(isArabic ? 'حذف الوثيقة' : 'Delete Certificate'),
          ],
        ),
        content: Text(isArabic ? 'هل تريد حذف هذا السجل نهائياً؟' : 'Delete this record?'),
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

    final bookings = ref.read(freightBookingProvider).value ?? [];
    final linkedBooking = bookings.where((b) => b.importFileId == file.importFileId && b.isActive).firstOrNull;

    final shippingRecords = ref.read(cargoShippingProvider).value ?? [];
    final linkedShipping = shippingRecords.where((s) => s.importFileId == file.importFileId && s.isActive).firstOrNull;

    final purchaseOrders = ref.read(purchaseOrdersProvider).purchaseOrders;
    final linkedPOs = purchaseOrders.where((po) => po.importFileId == file.importFileId && po.isActive).toList();

    // 1. Transport Mode
    String mode = 'OCEAN';
    final bookingMode = (linkedBooking?.shipmentType ?? '').toLowerCase();
    final fileMode = file.shipmentMode.toLowerCase();
    if (bookingMode.contains('air') || fileMode.contains('air') || fileMode.contains('جوي')) {
      mode = 'AIR';
    } else if (bookingMode.contains('land') || bookingMode.contains('road') || fileMode.contains('land') || fileMode.contains('road') || fileMode.contains('بري')) {
      mode = 'ROAD';
    } else {
      mode = 'OCEAN';
    }

    // 2. Carrier Name
    String carrier = '';
    if (linkedBooking != null) {
      carrier = linkedBooking.shippingLineName ?? linkedBooking.freightForwarderName ?? linkedBooking.scenarioProviderName ?? '';
    }
    if (carrier.isEmpty) {
      carrier = file.brokerName ?? '';
    }

    // 3. Vessel / Flight & Voyage
    String vessel = '';
    String voyage = '';
    if (linkedBooking != null) {
      if (linkedBooking.vesselName != null && linkedBooking.vesselName!.isNotEmpty) {
        vessel = linkedBooking.vesselName!;
      }
      if (linkedBooking.voyageNumber != null && linkedBooking.voyageNumber!.isNotEmpty) {
        voyage = linkedBooking.voyageNumber!;
      }
    }

    // 4. Port of Loading (POL)
    String pol = '';
    if (linkedBooking != null && linkedBooking.polName != null && linkedBooking.polName!.isNotEmpty) {
      pol = linkedBooking.polName!;
    } else if (file.portOfLoading != null && file.portOfLoading!.isNotEmpty) {
      pol = file.portOfLoading!;
    }

    // 5. Port of Discharge (POD)
    String pod = '';
    if (linkedBooking != null && linkedBooking.podName != null && linkedBooking.podName!.isNotEmpty) {
      pod = linkedBooking.podName!;
    } else if (file.portOfDischarge != null && file.portOfDischarge!.isNotEmpty) {
      pod = file.portOfDischarge!;
    }

    // 6. B/L / AWB / Tracking Reference
    String bl = '';
    if (linkedShipping != null && linkedShipping.courierTrackingData.trackingNumber != null && linkedShipping.courierTrackingData.trackingNumber!.isNotEmpty) {
      bl = linkedShipping.courierTrackingData.trackingNumber!;
    } else if (linkedBooking != null && linkedBooking.bookingConfirmationNo != null && linkedBooking.bookingConfirmationNo!.isNotEmpty) {
      bl = linkedBooking.bookingConfirmationNo!;
    } else if (linkedBooking != null && linkedBooking.containerReleaseOrderNo != null && linkedBooking.containerReleaseOrderNo!.isNotEmpty) {
      bl = linkedBooking.containerReleaseOrderNo!;
    } else if (file.customFileNumber != null && file.customFileNumber!.isNotEmpty) {
      bl = file.customFileNumber!;
    }

    // 7. Invoice Value (FOB)
    double invVal = 0.0;
    if (file.invoicesData.isNotEmpty) {
      invVal = file.invoicesData.fold<double>(0.0, (sum, item) => sum + item.amount);
    }
    if (invVal <= 0.0 && linkedPOs.isNotEmpty) {
      invVal = linkedPOs.fold<double>(0.0, (sum, po) => sum + po.totalAmountFob);
    }
    if (invVal <= 0.0 && file.estimatedCost > 0.0) {
      invVal = file.estimatedCost;
    }

    // 8. Freight Cost
    double freightCost = 0.0;
    if (linkedBooking != null && linkedBooking.totalFreightCostUsd > 0.0) {
      freightCost = linkedBooking.totalFreightCostUsd;
    }

    // 9. Currency
    String curr = 'USD';
    if (file.invoicesData.isNotEmpty && file.invoicesData.first.currency.isNotEmpty) {
      curr = file.invoicesData.first.currency.toUpperCase();
    } else if (linkedPOs.isNotEmpty && (linkedPOs.first.currencyCode ?? '').isNotEmpty) {
      curr = linkedPOs.first.currencyCode!.toUpperCase();
    } else if (file.estimatedCostCurrency.isNotEmpty) {
      curr = file.estimatedCostCurrency.toUpperCase();
    }

    // 10. Goods Description & Packages & Weight
    int? pkgCount;
    double? grossWeight;
    String? goodsDesc;
    if (file.packingListsData.isNotEmpty) {
      final totalP = file.packingListsData.fold<int>(0, (sum, p) => sum + p.totalPackages);
      final totalW = file.packingListsData.fold<double>(0.0, (sum, p) => sum + p.grossWeightKg);
      if (totalP > 0) pkgCount = totalP;
      if (totalW > 0) grossWeight = totalW;
    }
    if (file.projectNames != null && file.projectNames!.isNotEmpty) {
      goodsDesc = file.projectNames;
    } else if (linkedPOs.isNotEmpty) {
      final descs = linkedPOs.map((po) => po.items.map((it) => it.itemDescription).where((d) => d.isNotEmpty).join(', ')).where((d) => d.isNotEmpty).join('; ');
      if (descs.isNotEmpty) goodsDesc = descs;
    }

    setState(() {
      _selectedImportFileId = file.importFileId;
      _insuredEntityCtrl.text = file.companyName;
      _transportMode = mode;
      if (mode == 'AIR') {
        _coverageClause = 'AIR_ALL_RISKS';
      } else if (_coverageClause == 'AIR_ALL_RISKS') {
        _coverageClause = 'ICC_A';
      }
      if (carrier.isNotEmpty) _carrierCtrl.text = carrier;
      if (vessel.isNotEmpty) _vesselFlightCtrl.text = vessel;
      if (voyage.isNotEmpty) _voyageNoCtrl.text = voyage;
      if (pol.isNotEmpty) _polCtrl.text = pol;
      if (pod.isNotEmpty) _podCtrl.text = pod;
      if (bl.isNotEmpty) _trackingRefCtrl.text = bl;
      _invoiceValueCtrl.text = invVal > 0.0 ? invVal.toStringAsFixed(2) : '0.0';
      _freightCostCtrl.text = freightCost > 0.0 ? freightCost.toStringAsFixed(2) : '0.0';
      _currency = curr;

      if (pkgCount != null) _packageCountCtrl.text = pkgCount.toString();
      if (grossWeight != null) _grossWeightCtrl.text = grossWeight.toStringAsFixed(1);
      if (goodsDesc != null && goodsDesc.isNotEmpty) _goodsDescCtrl.text = goodsDesc;
    });

    _runLiveCalculation();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final importFiles = ref.watch(importFilesProvider).asData?.value ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 1080,
        height: 780,
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
                              ? (isArabic ? 'إصدار شهادة تأمين البضائع المشحونة' : 'New Cargo Insurance Certificate')
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
                              hintText: isArabic ? 'اختر ملف الشحنة لاستدعاء البيانات تلقائياً...' : 'Select Import File to auto-fill...',
                              items: importFiles
                                  .map((f) => SearchableDropdownItem(
                                        value: f.importFileId,
                                        label: '${f.importFileCode} - ${f.companyName} (${f.incotermCode} - ${f.shipmentMode})',
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
                                  flex: 3,
                                  child: SearchableDropdownField<String>(
                                    value: _policyType,
                                    labelText: isArabic ? 'نوع وثيقة التأمين *' : 'Policy Type *',
                                    hintText: isArabic ? 'اختر نوع الوثيقة...' : 'Select type...',
                                    items: [
                                      SearchableDropdownItem(
                                        value: 'SPECIFIC',
                                        label: isArabic ? 'وثيقة محددة لشحنة واحدة (Specific)' : 'Specific Shipment Policy',
                                      ),
                                      SearchableDropdownItem(
                                        value: 'OPEN_DECLARATION',
                                        label: isArabic ? 'وثيقة تأمين مفتوحة سنوية (Open Policy)' : 'Open Floating Policy',
                                      ),
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
                                      hintText: 'POL-2026-XXXX',
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
                                        child: SearchableDropdownField<String>(
                                          value: _transportMode,
                                          labelText: isArabic ? 'وسيلة النقل *' : 'Transport Mode *',
                                          hintText: isArabic ? 'اختر وسيلة النقل...' : 'Select mode...',
                                          items: [
                                            SearchableDropdownItem(
                                              value: 'OCEAN',
                                              label: isArabic ? '🚢 شحن بحري (Ocean)' : 'Ocean Freight',
                                            ),
                                            SearchableDropdownItem(
                                              value: 'AIR',
                                              label: isArabic ? '✈️ شحن جوي (Air)' : 'Air Freight',
                                            ),
                                            SearchableDropdownItem(
                                              value: 'ROAD',
                                              label: isArabic ? '🚛 شحن بري (Road)' : 'Road Transport',
                                            ),
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

                            // 5. Financial Inputs (Invoice + Freight + Currency)
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _invoiceValueCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'قيمة الفاتورة (FOB) *' : 'Invoice Value (FOB) *',
                                      prefixIcon: const Icon(Icons.receipt_rounded, size: 18),
                                    ),
                                    onChanged: (_) => _runLiveCalculation(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _freightCostCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: isArabic ? 'تكلفة النولون / الشحن' : 'Freight Cost',
                                      prefixIcon: const Icon(Icons.directions_boat_rounded, size: 18),
                                    ),
                                    onChanged: (_) => _runLiveCalculation(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: SearchableDropdownField<String>(
                                    value: _currency,
                                    labelText: isArabic ? 'العملة *' : 'Currency *',
                                    hintText: isArabic ? 'اختر العملة...' : 'Select...',
                                    items: [
                                      SearchableDropdownItem(value: 'USD', label: isArabic ? 'USD - دولار أمريكي' : 'USD - US Dollar'),
                                      SearchableDropdownItem(value: 'EUR', label: isArabic ? 'EUR - يورو أوروبي' : 'EUR - Euro'),
                                      SearchableDropdownItem(value: 'EGP', label: isArabic ? 'EGP - جنيه مصري' : 'EGP - Egyptian Pound'),
                                      SearchableDropdownItem(value: 'CNY', label: isArabic ? 'CNY - يوان صيني' : 'CNY - Chinese Yuan'),
                                      SearchableDropdownItem(value: 'GBP', label: isArabic ? 'GBP - جنيه إسترليني' : 'GBP - British Pound'),
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
                                  SearchableDropdownField<String>(
                                    value: _coverageClause,
                                    labelText: isArabic ? 'بند التغطية (Institute Cargo Clauses) *' : 'Coverage Clause *',
                                    hintText: isArabic ? 'اختر بند التغطية...' : 'Select clause...',
                                    items: [
                                      SearchableDropdownItem(
                                        value: 'ICC_A',
                                        label: isArabic ? 'ICC (A) — أخطار شاملة معهد المكتتبين (أعلى تغطية - 0.25%)' : 'ICC (A) — All Risks (0.25%)',
                                      ),
                                      SearchableDropdownItem(
                                        value: 'AIR_ALL_RISKS',
                                        label: isArabic ? 'Institute Clauses (Air) — تأمين جوي شامل لكافة الأخطار (0.20%)' : 'Air Cargo All Risks (0.20%)',
                                      ),
                                      SearchableDropdownItem(
                                        value: 'ICC_B',
                                        label: isArabic ? 'ICC (B) — أخطار متوسطة محددة معهد المكتتبين (0.15%)' : 'ICC (B) — Intermediate (0.15%)',
                                      ),
                                      SearchableDropdownItem(
                                        value: 'ICC_C',
                                        label: isArabic ? 'ICC (C) — الحد الأدنى للأخطار والحوادث الجسيمة (0.10%)' : 'ICC (C) — Minimum Cargo Risks (0.10%)',
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setState(() => _coverageClause = v ?? 'ICC_A');
                                      _runLiveCalculation();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() => _includeWarAndStrikes = !_includeWarAndStrikes);
                                      _runLiveCalculation();
                                    },
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: _includeWarAndStrikes,
                                          activeColor: AppTheme.emerald,
                                          onChanged: (v) {
                                            setState(() => _includeWarAndStrikes = v ?? true);
                                            _runLiveCalculation();
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isArabic
                                                    ? 'تضمين ملحق أخطار الحروب والإضرابات (War & Strikes Clauses +0.05%)'
                                                    : 'Include War & Strikes Clauses (+0.05%)',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                isArabic
                                                    ? 'ملحق إلزامي للاعتمادات المستندية والتخليص الجمركي للشحنات'
                                                    : 'Mandatory add-on for Letter of Credit (L/C) compliance',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
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
                                isArabic ? 'وصف البضاعة والطرود المشحونة' : 'Cargo Description & Packages',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _goodsDescCtrl,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  labelText: isArabic ? 'الوصف الدقيق للبضاعة' : 'Goods Description',
                                  hintText: isArabic ? 'مثال: خطوط إنتاج وقطع غيار صناعية...' : 'e.g. Industrial equipment',
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
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.charcoal,
            ),
          ),
        ),
        const SizedBox(width: 8),
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
