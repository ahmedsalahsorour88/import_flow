import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/row_context_menu.dart';
import '../../../core/widgets/universal_entity_extractor_dialog.dart';
import '../models/import_company_model.dart';
import '../providers/import_companies_provider.dart';
import '../widgets/import_company_details_dialog.dart';
import '../../../core/services/master_data_export_service.dart';
import '../../audit_logs/widgets/row_history_dialog.dart';

class ImportCompaniesScreen extends ConsumerStatefulWidget {
  const ImportCompaniesScreen({super.key});

  @override
  ConsumerState<ImportCompaniesScreen> createState() => _ImportCompaniesScreenState();
}

class _ImportCompaniesScreenState extends ConsumerState<ImportCompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(importCompaniesProvider.notifier).fetchCompanies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final companiesAsync = ref.watch(importCompaniesProvider);
    final showInactive = ref.watch(showInactiveCompaniesProvider);

    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.importCompaniesScreenTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.importCompaniesScreenSubtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const BackToDashboardButton(),
                    const SizedBox(width: 12),
                    // Show Deactivated Filter Switch
                    Row(
                      children: [
                        Text(l10n.includeDeactivatedLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
                        const SizedBox(width: 8),
                        Switch(
                          value: showInactive,
                          activeColor: AppTheme.cobalt,
                          onChanged: (val) {
                            ref.read(showInactiveCompaniesProvider.notifier).state = val;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('تكويد الشركة بالذكاء الاصطناعي ✨'),
                      onPressed: () => UniversalEntityExtractorDialog.showImporterExtractor(
                        context,
                        onSaved: () => ref.read(importCompaniesProvider.notifier).fetchCompanies(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_business, size: 18),
                      label: Text(l10n.addImporterCompanyBtn),
                      onPressed: () => _showCompanyDialog(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Master Data Toolbar (Excel Template, Upload, Export Excel, Export PDF)
            MasterDataToolbarWidget(
              moduleEndpoint: 'import-companies',
              title: 'Import_Companies',
              onRefreshNeeded: () => ref.refresh(importCompaniesProvider.notifier).fetchCompanies(),
            ),

            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppTheme.charcoal),
                  hintText: l10n.searchImporterHint,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.cobalt, width: 2),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Data Table Content
            Expanded(
              child: companiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cobalt)),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.crimson),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          l10n.importersFetchError(err.toString()),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cobalt,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retryConnectionBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ref.read(importCompaniesProvider.notifier).fetchCompanies();
                        },
                      ),
                    ],
                  ),
                ),
                data: (companies) {
                  final filtered = companies.where((c) {
                    return c.importerName.toLowerCase().contains(_searchQuery) ||
                        c.importerId.toLowerCase().contains(_searchQuery) ||
                        c.registrationNumber.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(l10n.noImportCompaniesFound, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final company = filtered[index];
                        return _buildCompanyRow(company);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyRow(ImportCompanyModel company) {
    final l10n = context.l10n;
    final isActive = company.isActive;

    return GestureDetector(
      onSecondaryTapDown: (details) {
        RowContextMenuHelper.showContextMenu(
          context: context,
          globalPosition: details.globalPosition,
          codeToCopy: company.importerId,
          onEdit: () => _showCompanyDialog(context, company),
          onHistory: () => RowHistoryDialog.show(
            context,
            entityType: 'ImportCompany',
            entityId: company.companyId!,
            entityTitle: company.importerName,
          ),
          isActive: isActive,
          onToggleActive: () async {
            if (company.companyId != null) {
              await ref.read(importCompaniesProvider.notifier).toggleActiveStatus(company.companyId!, isActive);
            }
          },
        );
      },
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              // Icon Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isActive ? AppTheme.cobalt : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.business, color: isActive ? AppTheme.cobalt : Colors.grey),
              ),
              const SizedBox(width: 16),

              // Name & Status Badge
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          company.importerName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isActive ? AppTheme.charcoal : Colors.grey.shade700,
                            decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Active/Deactive Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isActive ? AppTheme.emerald : AppTheme.crimson).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive ? l10n.statusActive : l10n.statusInactive,
                            style: TextStyle(
                              color: isActive ? AppTheme.emerald : AppTheme.crimson,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.importerRowMeta(company.importerId, company.vatId, company.registrationNumber),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Expiry Cards
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExpiryBadge(company.daysUntilImporterIdExpiry, l10n.badgeImportId),
                    const SizedBox(height: 4),
                    _buildExpiryBadge(company.daysUntilVatExpiry, l10n.badgeVatExpiry),
                    const SizedBox(height: 4),
                    _buildExpiryBadge(company.daysUntilRegExpiry, l10n.badgeComReg),
                  ],
                ),
              ),

              // Standard 4-Action Row Pill: View, Edit, Print, Delete
              RowActionsPill(
                onView: () => ImportCompanyDetailsDialog.show(
                  context,
                  company,
                  onEdit: () => _showCompanyDialog(context, company),
                ),
                onEdit: () => _showCompanyDialog(context, company),
                onPrint: () => MasterDataExportService.printOrSaveImporterPdf(company),
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.confirmActionTitle),
                      content: Text(isActive
                          ? l10n.confirmDeactivateCompany(company.importerName)
                          : l10n.confirmActivateCompany(company.importerName)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: isActive ? AppTheme.crimson : AppTheme.emerald),
                          child: Text(isActive ? l10n.deactivateBtn : l10n.activateBtn, style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && company.companyId != null) {
                    ref.read(importCompaniesProvider.notifier).toggleActiveStatus(company.companyId!, isActive);
                  }
                },
                deleteTooltip: isActive ? l10n.deactivateCompanyTooltip : l10n.activateCompanyTooltip,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryBadge(int daysLeft, String label) {
    final l10n = context.l10n;
    Color bg;
    Color fg;
    String statusText;

    if (daysLeft < 0) {
      bg = AppTheme.crimson.withOpacity(0.15);
      fg = AppTheme.crimson;
      statusText = l10n.expiryExpired;
    } else if (daysLeft <= 30) {
      bg = AppTheme.orange.withOpacity(0.15);
      fg = AppTheme.orange;
      statusText = l10n.expiryDaysLeft(daysLeft);
    } else {
      bg = AppTheme.emerald.withOpacity(0.15);
      fg = AppTheme.emerald;
      statusText = l10n.expiryValidDays(daysLeft);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        '$label: $statusText',
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showCompanyDialog(BuildContext context, [ImportCompanyModel? companyToEdit]) {
    final l10n = context.l10n;
    final isEditing = companyToEdit != null;
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: companyToEdit?.importerName ?? '');
    final addressCtrl = TextEditingController(text: companyToEdit?.address ?? '');
    final countryCtrl = TextEditingController(text: companyToEdit?.country ?? 'Egypt');
    final impIdCtrl = TextEditingController(text: companyToEdit?.importerId ?? '');
    final vatIdCtrl = TextEditingController(text: companyToEdit?.vatId ?? '');
    final regNumCtrl = TextEditingController(text: companyToEdit?.registrationNumber ?? '');
    final phoneCtrl = TextEditingController(text: companyToEdit?.phone ?? '');

    DateTime impExpiry = companyToEdit?.importerIdExpiry ?? DateTime.now().add(const Duration(days: 365));
    DateTime vatExpiry = companyToEdit?.vatIdExpiry ?? DateTime.now().add(const Duration(days: 365));
    DateTime regExpiry = companyToEdit?.registrationExpiry ?? DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 580,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                // Dialog Header Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: AppTheme.charcoal,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(isEditing ? Icons.edit : Icons.add_business, color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            isEditing ? l10n.editImporterCompanyTitle : l10n.addImporterCompanyTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        tooltip: l10n.closeDialogTooltip,
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                ),

                // Dialog Form Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            controller: nameCtrl,
                            label: l10n.companyNameLabel,
                            icon: Icons.business,
                            isRequired: true,
                            hint: l10n.companyNameHint,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: addressCtrl,
                                  label: l10n.addressLabel,
                                  icon: Icons.location_on,
                                  isRequired: true,
                                  hint: l10n.addressHint,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  controller: countryCtrl,
                                  label: l10n.countryLabel,
                                  icon: Icons.flag,
                                  isRequired: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StatefulBuilder(
                            builder: (context, setDialogState) {
                              Future<void> pickDate(String type) async {
                                final initial = type == 'imp'
                                    ? impExpiry
                                    : type == 'vat'
                                        ? vatExpiry
                                        : regExpiry;
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2040),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    if (type == 'imp') impExpiry = picked;
                                    if (type == 'vat') vatExpiry = picked;
                                    if (type == 'reg') regExpiry = picked;
                                  });
                                }
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          controller: impIdCtrl,
                                          label: l10n.importerCardIdLabel,
                                          icon: Icons.badge,
                                          isRequired: true,
                                          hint: l10n.importerCardIdHint,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.importerCardExpiryLabel,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                                            ),
                                            const SizedBox(height: 6),
                                            InkWell(
                                              onTap: () => pickDate('imp'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade400),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.calendar_month, size: 18, color: AppTheme.cobalt),
                                                    const SizedBox(width: 8),
                                                    Text('${impExpiry.year}-${impExpiry.month.toString().padLeft(2, '0')}-${impExpiry.day.toString().padLeft(2, '0')}'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          controller: vatIdCtrl,
                                          label: l10n.vatRegIdLabel,
                                          icon: Icons.receipt_long,
                                          isRequired: true,
                                          hint: l10n.vatRegIdHint,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.vatRegExpiryLabel,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                                            ),
                                            const SizedBox(height: 6),
                                            InkWell(
                                              onTap: () => pickDate('vat'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade400),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.calendar_month, size: 18, color: AppTheme.cobalt),
                                                    const SizedBox(width: 8),
                                                    Text('${vatExpiry.year}-${vatExpiry.month.toString().padLeft(2, '0')}-${vatExpiry.day.toString().padLeft(2, '0')}'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          controller: regNumCtrl,
                                          label: l10n.commercialRegNumLabel,
                                          icon: Icons.app_registration,
                                          isRequired: true,
                                          hint: l10n.commercialRegNumHint,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.commercialRegExpiryLabel,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                                            ),
                                            const SizedBox(height: 6),
                                            InkWell(
                                              onTap: () => pickDate('reg'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade400),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.calendar_month, size: 18, color: AppTheme.cobalt),
                                                    const SizedBox(width: 8),
                                                    Text('${regExpiry.year}-${regExpiry.month.toString().padLeft(2, '0')}-${regExpiry.day.toString().padLeft(2, '0')}'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: phoneCtrl,
                                    label: l10n.phoneNumberLabel,
                                    icon: Icons.phone,
                                    hint: l10n.phoneNumberHint,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Dialog Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.crimson,
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close, size: 16, color: AppTheme.crimson),
                        label: Text(l10n.cancelAndCloseBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(isEditing ? l10n.updateCompanyBtn : l10n.saveCompanyBtn),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final company = ImportCompanyModel(
                            companyId: companyToEdit?.companyId,
                            importerName: nameCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            country: countryCtrl.text.trim(),
                            importerId: impIdCtrl.text.trim(),
                            importerIdExpiry: impExpiry,
                            vatId: vatIdCtrl.text.trim(),
                            vatIdExpiry: vatExpiry,
                            registrationNumber: regNumCtrl.text.trim(),
                            registrationExpiry: regExpiry,
                            phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                            isActive: companyToEdit?.isActive ?? true,
                          );

                          String? errorMessage;
                          if (isEditing && companyToEdit.companyId != null) {
                            final List<FieldChangeItem> changes = [];
                            if (FieldChangeItem.isDifferent(companyToEdit.importerName, company.importerName)) {
                              changes.add(FieldChangeItem(fieldName: l10n.diffCompanyName, oldValue: companyToEdit.importerName, newValue: company.importerName));
                            }
                            if (FieldChangeItem.isDifferent(companyToEdit.importerId, company.importerId)) {
                              changes.add(FieldChangeItem(fieldName: l10n.diffImporterCardId, oldValue: companyToEdit.importerId, newValue: company.importerId));
                            }
                            if (FieldChangeItem.isDifferent(companyToEdit.importerIdExpiry.toString().substring(0, 10), company.importerIdExpiry.toString().substring(0, 10))) {
                              changes.add(FieldChangeItem(fieldName: l10n.diffImporterCardExpiry, oldValue: companyToEdit.importerIdExpiry.toString().substring(0, 10), newValue: company.importerIdExpiry.toString().substring(0, 10)));
                            }
                            if (FieldChangeItem.isDifferent(companyToEdit.vatId, company.vatId)) {
                              changes.add(FieldChangeItem(fieldName: l10n.diffVatId, oldValue: companyToEdit.vatId, newValue: company.vatId));
                            }
                            if (FieldChangeItem.isDifferent(companyToEdit.registrationNumber, company.registrationNumber)) {
                              changes.add(FieldChangeItem(fieldName: l10n.diffCommercialReg, oldValue: companyToEdit.registrationNumber, newValue: company.registrationNumber));
                            }
                            if (FieldChangeItem.isDifferent(companyToEdit.address, company.address)) {
                              changes.add(FieldChangeItem(fieldName: l10n.diffAddress, oldValue: companyToEdit.address, newValue: company.address));
                            }
                            if (FieldChangeItem.isDifferent(companyToEdit.phone, company.phone)) {
                              changes.add(FieldChangeItem(fieldName: l10n.diffPhone, oldValue: companyToEdit.phone, newValue: company.phone));
                            }

                            if (changes.isNotEmpty) {
                              final confirmed = await showChangeDiffConfirmationDialog(
                                context,
                                title: l10n.diffConfirmCompanyTitle,
                                itemReference: companyToEdit.importerName,
                                changes: changes,
                              );
                              if (!confirmed) return;
                            }

                            errorMessage = await ref.read(importCompaniesProvider.notifier).updateCompany(companyToEdit.companyId!, company);
                          } else {
                            errorMessage = await ref.read(importCompaniesProvider.notifier).createCompany(company);
                          }

                          if (errorMessage == null) {
                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  backgroundColor: AppTheme.crimson,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
