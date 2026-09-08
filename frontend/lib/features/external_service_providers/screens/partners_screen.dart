import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/widgets/custom_text_field.dart';

import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/universal_entity_extractor_dialog.dart';
import '../models/partner_model.dart';
import '../providers/partners_provider.dart';
import '../widgets/partner_details_dialog.dart';
import '../widgets/partner_statement_of_account_dialog.dart';
import '../widgets/partner_scorecard_dialog.dart';
import '../../../core/services/master_data_export_service.dart';
import '../../../core/widgets/copyable_data_helper.dart';

class PartnersScreen extends ConsumerStatefulWidget {
  const PartnersScreen({super.key});

  @override
  ConsumerState<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends ConsumerState<PartnersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Bank',
    'Shipping Line',
    'Customs Broker',
    'Freight Forwarder',
    'Inland Transport',
    'Inspection Agency',
    'Insurance Company',
  ];

  String _getCategoryLabel(BuildContext context, String cat) {
    final l10n = context.l10n;
    switch (cat) {
      case 'All':
        return l10n.partnerCatAll;
      case 'Bank':
        return l10n.partnerCatBank;
      case 'Shipping Line':
        return l10n.partnerCatShippingLine;
      case 'Customs Broker':
        return l10n.partnerCatCustomsBroker;
      case 'Freight Forwarder':
        return l10n.partnerCatFreightForwarder;
      case 'Inland Transport':
        return l10n.partnerCatInlandTransport;
      case 'Inspection Agency':
        return l10n.partnerCatInspectionAgency;
      case 'Insurance Company':
        return l10n.partnerCatInsuranceCompany;
      default:
        return cat;
    }
  }

  void _copyPartnersTsv(BuildContext context, List<PartnerModel> partners) {
    final l10n = context.l10n;
    final headers = [
      l10n.partnersTsvHeaderCode,
      l10n.partnersTsvHeaderName,
      l10n.partnersTsvHeaderCategories,
      l10n.partnersTsvHeaderCountry,
      l10n.partnersTsvHeaderAddress,
      l10n.partnersTsvHeaderPhone,
      l10n.partnersTsvHeaderMobile,
      l10n.partnersTsvHeaderFax,
      l10n.partnersTsvHeaderEmail,
      l10n.partnersTsvHeaderSecondaryEmail,
      l10n.partnersTsvHeaderWebsite,
      l10n.partnersTsvHeaderSwift,
      l10n.partnersTsvHeaderScac,
      l10n.partnersTsvHeaderLicense,
      l10n.partnersTsvHeaderCommercialReg,
      l10n.partnersTsvHeaderTaxId,
      l10n.partnersTsvHeaderStatus,
      l10n.partnersTsvHeaderNotes,
    ];
    final rows = partners.map((p) => [
      p.partnerCode,
      p.partnerName,
      p.partnerType,
      p.country,
      p.address ?? '',
      p.phone ?? '',
      p.mobile ?? '',
      p.fax ?? '',
      p.email ?? '',
      p.secondaryEmail ?? '',
      p.website ?? '',
      p.swiftCode ?? '',
      p.scacCode ?? '',
      p.clearanceLicenseNumber ?? '',
      p.commercialRegister ?? '',
      p.taxId ?? '',
      p.isActive ? l10n.statusActive : l10n.statusInactive,
      p.notes ?? '',
    ]);
    final tsv = [
      headers.join('\t'),
      ...rows.map((r) => r.map((c) => c.toString().replaceAll('\t', ' ').replaceAll('\n', ' ')).join('\t')),
    ].join('\n');
    CopyHelper.copy(context, tsv, customMessage: l10n.partnersExportTsvSuccess);
  }

  String _buildPartnerSummary(BuildContext context, PartnerModel p) {
    final l10n = context.l10n;
    final b = StringBuffer();
    b.writeln('📋 ${l10n.partnerProfileTitle}');
    b.writeln('${l10n.partnerCodeBadgeLabel}${p.partnerCode}');
    b.writeln('${l10n.partnerNameLabel}: ${p.partnerName}');
    b.writeln('${l10n.partnerCategoriesLabel}: ${p.partnerType}');
    b.writeln('${l10n.countryDetailLabel}: ${p.country}');
    if (p.address != null && p.address!.isNotEmpty) b.writeln('${l10n.fullAddressDetailLabel}: ${p.address}');
    if (p.phone != null && p.phone!.isNotEmpty) b.writeln('${l10n.partnerPhoneLabel}: ${p.phone}');
    if (p.mobile != null && p.mobile!.isNotEmpty) b.writeln('${l10n.partnerMobileLabel}: ${p.mobile}');
    if (p.email != null && p.email!.isNotEmpty) b.writeln('${l10n.emailDetailLabel}: ${p.email}');
    if (p.website != null && p.website!.isNotEmpty) b.writeln('${l10n.websiteDetailLabel}: ${p.website}');
    if (p.swiftCode != null && p.swiftCode!.isNotEmpty) b.writeln('${l10n.partnerSwiftCodeDetailLabel}: ${p.swiftCode}');
    if (p.scacCode != null && p.scacCode!.isNotEmpty) b.writeln('${l10n.partnerScacCodeDetailLabel}: ${p.scacCode}');
    if (p.clearanceLicenseNumber != null && p.clearanceLicenseNumber!.isNotEmpty) b.writeln('${l10n.clearanceLicenseDetailLabel}: ${p.clearanceLicenseNumber}');
    if (p.commercialRegister != null && p.commercialRegister!.isNotEmpty) b.writeln('${l10n.commercialRegDetailLabel}: ${p.commercialRegister}');
    if (p.taxId != null && p.taxId!.isNotEmpty) b.writeln('${l10n.taxIdDetailLabel}: ${p.taxId}');
    b.writeln('${l10n.partnerStatusCol}: ${p.isActive ? l10n.statusActive : l10n.statusInactive}');
    if (p.notes != null && p.notes!.isNotEmpty) b.writeln('${l10n.additionalNotesSection}: ${p.notes}');
    return b.toString().trim();
  }

  void _openExtractorForCategory(BuildContext context, String category) {
    void onDone() {
      ref.read(partnersProvider.notifier).fetchPartners();
      ref.read(allPartnersProvider.notifier).fetchPartners();
      ref.invalidate(partnersProvider);
      ref.invalidate(allPartnersProvider);
    }

    switch (category) {
      case 'Shipping Line':
        UniversalEntityExtractorDialog.showShippingLineExtractor(
          context,
          onSaved: onDone,
        );
        break;
      case 'Customs Broker':
        UniversalEntityExtractorDialog.showCustomsBrokerExtractor(
          context,
          onSaved: onDone,
        );
        break;
      case 'Freight Forwarder':
        UniversalEntityExtractorDialog.showFreightForwarderExtractor(
          context,
          onSaved: onDone,
        );
        break;
      case 'Inland Transport':
        UniversalEntityExtractorDialog.showInlandTransportExtractor(
          context,
          onSaved: onDone,
        );
        break;
      case 'Inspection Agency':
        UniversalEntityExtractorDialog.showInspectionAgencyExtractor(
          context,
          onSaved: onDone,
        );
        break;
      case 'Insurance Company':
        UniversalEntityExtractorDialog.showInsuranceCompanyExtractor(
          context,
          onSaved: onDone,
        );
        break;
      case 'Bank':
        UniversalEntityExtractorDialog.showBankExtractor(
          context,
          onSaved: onDone,
        );
        break;
      default:
        UniversalEntityExtractorDialog.show(
          context,
          initialTarget: EntityTarget.customsBroker,
          onSaved: onDone,
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    if (!ref.read(partnersProvider).isLoading) {
      Future.microtask(() => ref.read(partnersProvider.notifier).fetchPartners());
    }
    if (!ref.read(allPartnersProvider).isLoading) {
      Future.microtask(() => ref.read(allPartnersProvider.notifier).fetchPartners());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final partnersAsync = ref.watch(partnersProvider);
    final selectedCategory = ref.watch(selectedPartnerCategoryProvider);
    final showInactive = ref.watch(showInactivePartnersProvider);
    final partnerList = partnersAsync.asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      body: SelectionArea(
        child: Padding(
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
                        l10n.partnersScreenTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.partnersScreenSubtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const BackToDashboardButton(),
                    const SizedBox(width: 10),
                    if (partnerList.isNotEmpty) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.table_chart_outlined, size: 18),
                        label: Text(l10n.partnersExportTsvBtn),
                        onPressed: () => _copyPartnersTsv(context, partnerList),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cobalt,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        selectedCategory == 'All'
                            ? l10n.aiCodePartnerBtn
                            : l10n.aiCodeCategoryPartner(_getCategoryLabel(context, selectedCategory)),
                      ),
                      onPressed: () => _openExtractorForCategory(context, selectedCategory),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addExternalPartnerBtn),
                      onPressed: () => _showPartnerDialog(context),
                    ),
                  ],
                ),

              ],
            ),
            const SizedBox(height: 16),

            // Master Data Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'external-service-providers',
              title: 'Partners_Banks',
              onRefreshNeeded: () => ref.refresh(partnersProvider.notifier).fetchPartners(),
            ),

            const SizedBox(height: 16),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        _getCategoryLabel(context, cat),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.charcoal,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.cobalt,
                      backgroundColor: Colors.white,
                      onSelected: (val) {
                        if (val) {
                          ref.read(selectedPartnerCategoryProvider.notifier).state = cat;
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar & Filter Switch
            Row(
              children: [
                Expanded(
                  child: Container(
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
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (_, val, __) => TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, color: AppTheme.charcoal),
                          hintText: l10n.searchPartnersHint,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.cobalt, width: 2),
                          ),
                          suffixIcon: val.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _searchQuery = v.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Show Inactive Toggle Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  child: Row(
                    children: [
                      Text(
                        l10n.showInactivePartnersLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                      Switch(
                        value: showInactive,
                        activeColor: AppTheme.cobalt,
                        onChanged: (val) {
                          ref.read(showInactivePartnersProvider.notifier).state = val;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Data Table Content
            Expanded(
              child: partnersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cobalt)),
                error: (err, stack) => Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.crimson),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            l10n.partnersFetchError.replaceAll('\$error', err.toString()),
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
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
                            ref.read(partnersProvider.notifier).fetchPartners();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                data: (partners) {
                  final filtered = partners.where((p) {
                    final q = _searchQuery;
                    return q.isEmpty ||
                        p.partnerName.toLowerCase().contains(q) ||
                        p.partnerCode.toLowerCase().contains(q) ||
                        (p.swiftCode?.toLowerCase().contains(q) ?? false) ||
                        (p.clearanceLicenseNumber?.toLowerCase().contains(q) ?? false) ||
                        (p.taxId?.toLowerCase().contains(q) ?? false) ||
                        p.country.toLowerCase().contains(q);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(l10n.noPartnersFound, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final tableWidth = constraints.maxWidth < 1100 ? 1100.0 : constraints.maxWidth;

                      return Container(
                        width: double.infinity,
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Table(
                                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                  columnWidths: const {
                                    0: FixedColumnWidth(140),
                                    1: FlexColumnWidth(3.0),
                                    2: FlexColumnWidth(2.6),
                                    3: FlexColumnWidth(2.2),
                                    4: FixedColumnWidth(95),
                                    5: FixedColumnWidth(215),
                                  },
                                  children: [
                                    // Table Header
                                    TableRow(
                                      decoration: const BoxDecoration(color: AppTheme.charcoal),
                                      children: [
                                        l10n.partnerCodeCol,
                                        l10n.partnerNameAndCategoryCol,
                                        l10n.registrationAndLicenseCol,
                                        l10n.contactDetailsCol,
                                        l10n.partnerStatusCol,
                                        l10n.partnerActionsCol,
                                      ]
                                          .map((h) => Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                                child: Text(
                                                  h,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),

                                    // Table Data Rows
                                    ...filtered.asMap().entries.map((entry) {
                                      final partner = entry.value;
                                      final isEven = entry.key % 2 == 0;
                                      final isActive = partner.isActive;
                                      final categories = partner.categoriesList;

                                      return TableRow(
                                        decoration: BoxDecoration(
                                          color: isEven ? Colors.white : Colors.grey.shade50,
                                        ),
                                        children: [
                                          // Code
                                          _cell(
                                            child: Tooltip(
                                              message: '${l10n.partnerCodeBadgeLabel}${partner.partnerCode} (${l10n.partnersCopyFieldTooltip})',
                                              child: InkWell(
                                                onTap: () => CopyHelper.copy(
                                                  context,
                                                  partner.partnerCode,
                                                  customMessage: l10n.copiedToClipboard(partner.partnerCode),
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.charcoal.withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: AppTheme.charcoal.withOpacity(0.15)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        partner.partnerCode,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                          letterSpacing: 0.3,
                                                          color: AppTheme.charcoal,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Icon(Icons.copy_rounded, size: 11, color: AppTheme.charcoal),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Partner Name & Categories
                                          _cell(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        partner.partnerName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                          color: isActive ? AppTheme.charcoal : Colors.grey.shade700,
                                                          decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Tooltip(
                                                      message: l10n.partnersCopyFieldTooltip,
                                                      child: InkWell(
                                                        onTap: () => CopyHelper.copy(
                                                          context,
                                                          partner.partnerName,
                                                          customMessage: l10n.copiedToClipboard(partner.partnerName),
                                                        ),
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: const Padding(
                                                          padding: EdgeInsets.all(2.0),
                                                          child: Icon(Icons.copy_rounded, size: 13, color: Colors.grey),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 5),
                                                Wrap(
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children: categories.map((cat) => _buildCategoryBadge(context, cat)).toList(),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Registration & Identifiers
                                          _cell(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (partner.swiftCode != null && partner.swiftCode!.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 2),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.account_balance_outlined, size: 12, color: AppTheme.cobalt),
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            l10n.partnerSwiftLabel(partner.swiftCode!),
                                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (partner.scacCode != null && partner.scacCode!.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 2),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.directions_boat_outlined, size: 12, color: AppTheme.cobalt),
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            l10n.partnerScacLabel(partner.scacCode!),
                                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (partner.clearanceLicenseNumber != null && partner.clearanceLicenseNumber!.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 2),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.badge_outlined, size: 12, color: AppTheme.orange),
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            l10n.partnerLicenseLabel(partner.clearanceLicenseNumber!),
                                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.orange),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (partner.commercialRegister != null && partner.commercialRegister!.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 2),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.description_outlined, size: 12, color: AppTheme.charcoal),
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            l10n.partnerRegLabel(partner.commercialRegister!),
                                                            style: const TextStyle(fontSize: 11, color: AppTheme.charcoal),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.public, size: 12, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        l10n.partnerCountryLabel(partner.country),
                                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Contact Details
                                          _cell(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (partner.email != null && partner.email!.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 3),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.email_outlined, size: 12, color: AppTheme.cobalt),
                                                        const SizedBox(width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            partner.email!,
                                                            style: const TextStyle(fontSize: 11, color: AppTheme.charcoal),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                else
                                                  Text(l10n.noEmailLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                if (partner.phone != null && partner.phone!.isNotEmpty)
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.phone_outlined, size: 12, color: Colors.grey),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          partner.phone!,
                                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                else
                                                  Text(l10n.noPhoneLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              ],
                                            ),
                                          ),

                                          // Status
                                          _cell(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: (isActive ? AppTheme.emerald : AppTheme.crimson).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: (isActive ? AppTheme.emerald : AppTheme.crimson).withOpacity(0.3),
                                                  width: 0.8,
                                                ),
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
                                          ),

                                          // Actions: View, Edit, Print, Delete, Statement of Account
                                          _cell(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Tooltip(
                                                  message: l10n.partnerStatementOfAccountTooltip,
                                                  child: InkWell(
                                                    onTap: () => PartnerStatementOfAccountDialog.show(context, partner),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                      margin: const EdgeInsets.only(right: 6),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.cobalt.withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.receipt_long, size: 14, color: AppTheme.cobalt),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            l10n.partnerStatementOfAccountBtn,
                                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (partner.providerId != null) ...[
                                                    const SizedBox(width: 6),
                                                    Tooltip(
                                                      message: l10n.partnerScorecardTooltip,
                                                      child: InkWell(
                                                        onTap: () => showPartnerScorecardDialog(
                                                          context,
                                                          ref,
                                                          providerId: partner.providerId!,
                                                          providerName: partner.partnerName,
                                                          providerType: partner.partnerType,
                                                        ),
                                                        borderRadius: BorderRadius.circular(6),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                          decoration: BoxDecoration(
                                                            color: Colors.amber.shade50,
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(color: Colors.amber.shade600),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.workspace_premium_outlined, size: 14, color: Colors.amber.shade800),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                l10n.partnerScorecardBtn,
                                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                  ],
                                                  Tooltip(
                                                    message: l10n.partnerCopySummaryBtn,
                                                    child: InkWell(
                                                      onTap: () => CopyHelper.copy(
                                                        context,
                                                        _buildPartnerSummary(context, partner),
                                                        customMessage: l10n.partnerCopySummarySuccess,
                                                      ),
                                                      borderRadius: BorderRadius.circular(6),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                        margin: const EdgeInsets.only(right: 6),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.emerald.withOpacity(0.12),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.copy_all_rounded, size: 14, color: AppTheme.emerald),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              l10n.partnerCopySummaryBtn,
                                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  RowActionsPill(
                                                  onView: () => PartnerDetailsDialog.show(
                                                    context,
                                                    partner,
                                                    onEdit: () => _showPartnerDialog(context, partner),
                                                  ),
                                                  onEdit: () => _showPartnerDialog(context, partner),
                                                  onPrint: () => MasterDataExportService.printOrSavePartnerPdf(partner),
                                                  onDelete: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: Text(l10n.confirmActionTitle),
                                                        content: Text(isActive
                                                            ? l10n.confirmDeactivatePartner(partner.partnerName)
                                                            : l10n.confirmActivatePartner(partner.partnerName)),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.closeBtn)),
                                                          ElevatedButton(
                                                            onPressed: () => Navigator.pop(ctx, true),
                                                            style: ElevatedButton.styleFrom(backgroundColor: isActive ? AppTheme.crimson : AppTheme.emerald),
                                                            child: Text(isActive ? l10n.deactivateBtn : l10n.activateBtn, style: const TextStyle(color: Colors.white)),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true && partner.providerId != null) {
                                                      ref.read(partnersProvider.notifier).toggleActiveStatus(partner.providerId!, isActive);
                                                    }
                                                  },
                                                  deleteTooltip: isActive ? l10n.deactivatePartnerTooltip : l10n.activatePartnerTooltip,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }

  Widget _cell({required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );

  Widget _buildCategoryBadge(BuildContext context, String cat) {
    Color color;
    switch (cat) {
      case 'Bank':
        color = AppTheme.emerald;
        break;
      case 'Shipping Line':
        color = AppTheme.cobalt;
        break;
      case 'Customs Broker':
        color = AppTheme.orange;
        break;
      case 'Freight Forwarder':
        color = AppTheme.charcoal;
        break;
      default:
        color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        _getCategoryLabel(context, cat),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }



  void _showPartnerDialog(BuildContext context, [PartnerModel? partnerToEdit]) {
    final l10n = context.l10n;
    final isEditing = partnerToEdit != null;
    final formKey = GlobalKey<FormState>();

    final availableCategories = [
      'Bank',
      'Shipping Line',
      'Customs Broker',
      'Freight Forwarder',
      'Inland Transport',
      'Inspection Agency',
    ];

    final Set<String> selectedCategories = partnerToEdit != null
        ? partnerToEdit.categoriesList.toSet()
        : {'Customs Broker'};

    final nameCtrl = TextEditingController(text: partnerToEdit?.partnerName ?? '');
    final taxIdCtrl = TextEditingController(text: partnerToEdit?.taxId ?? '');
    final regCtrl = TextEditingController(text: partnerToEdit?.commercialRegister ?? '');
    final licenseCtrl = TextEditingController(text: partnerToEdit?.clearanceLicenseNumber ?? '');
    final scacCtrl = TextEditingController(text: partnerToEdit?.scacCode ?? '');
    final trackingCtrl = TextEditingController(text: partnerToEdit?.trackingUrl ?? '');
    final swiftCtrl = TextEditingController(text: partnerToEdit?.swiftCode ?? '');
    final bankCodeCtrl = TextEditingController(text: partnerToEdit?.bankCode ?? '');
    final branchCtrl = TextEditingController(text: partnerToEdit?.branchName ?? '');
    final phoneCtrl = TextEditingController(text: partnerToEdit?.phone ?? '');
    final mobileCtrl = TextEditingController(text: partnerToEdit?.mobile ?? '');
    final faxCtrl = TextEditingController(text: partnerToEdit?.fax ?? '');
    final emailCtrl = TextEditingController(text: partnerToEdit?.email ?? '');
    final secondaryEmailCtrl = TextEditingController(text: partnerToEdit?.secondaryEmail ?? '');
    final websiteCtrl = TextEditingController(text: partnerToEdit?.website ?? '');
    final addressCtrl = TextEditingController(text: partnerToEdit?.address ?? '');
    final countryCtrl = TextEditingController(text: partnerToEdit?.country ?? 'Egypt');

    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isBank = selectedCategories.contains('Bank');
            final isShippingLine = selectedCategories.contains('Shipping Line');
            final isCustomsBroker = selectedCategories.contains('Customs Broker');

            Widget buildCopySuffix(TextEditingController ctrl) {
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: ctrl,
                builder: (ctx, val, _) {
                  if (val.text.trim().isEmpty) return const SizedBox.shrink();
                  return Tooltip(
                    message: l10n.partnersCopyFieldTooltip,
                    child: InkWell(
                      onTap: () => CopyHelper.copy(
                        context,
                        val.text.trim(),
                        customMessage: l10n.copiedToClipboard(val.text.trim()),
                      ),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.copy_rounded, size: 15, color: Colors.grey),
                      ),
                    ),
                  );
                },
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SelectionArea(
                child: SizedBox(
                  width: 640,
                  height: MediaQuery.of(context).size.height * 0.85,
                  child: Column(
                  children: [
                    // Banner
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
                                isEditing ? l10n.editPartnerDialogTitle : l10n.addPartnerDialogTitle,
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

                    // Scrollable Form Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Multi-Select Partner Categories
                              Row(
                                children: [
                                  Text(
                                    l10n.partnerCategoriesLabel,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.charcoal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: availableCategories.map((cat) {
                                  final isChecked = selectedCategories.contains(cat);
                                  return FilterChip(
                                    label: Text(_getCategoryLabel(context, cat)),
                                    selected: isChecked,
                                    selectedColor: AppTheme.cobalt.withOpacity(0.2),
                                    checkmarkColor: AppTheme.cobalt,
                                    labelStyle: TextStyle(
                                      color: isChecked ? AppTheme.cobalt : AppTheme.charcoal,
                                      fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (bool selected) {
                                      setDialogState(() {
                                        if (selected) {
                                          selectedCategories.add(cat);
                                        } else {
                                          if (selectedCategories.length > 1) {
                                            selectedCategories.remove(cat);
                                          }
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                controller: nameCtrl,
suffixIcon: buildCopySuffix(nameCtrl),
                                label: l10n.partnerNameLabel,
                                icon: Icons.business,
                                isRequired: true,
                                hint: l10n.partnerNameHint,
                              ),
                              const SizedBox(height: 16),

                              // Dynamic Category Fields
                              if (isBank) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emerald.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.emerald.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('🏦 ${l10n.bankingDetailsHeader}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: swiftCtrl,
suffixIcon: buildCopySuffix(swiftCtrl),
                                              label: l10n.bankSwiftCodeLabel,
                                              icon: Icons.code,
                                              isRequired: true,
                                              hint: l10n.bankSwiftCodeHint,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: CustomTextField(
                                              controller: bankCodeCtrl,
suffixIcon: buildCopySuffix(bankCodeCtrl),
                                              label: l10n.bankCodeLabel,
                                              icon: Icons.account_balance,
                                              hint: l10n.bankCodeHint,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      CustomTextField(
                                        controller: branchCtrl,
suffixIcon: buildCopySuffix(branchCtrl),
                                        label: l10n.branchNameLabel,
                                        icon: Icons.location_city,
                                        hint: l10n.branchNameHint,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (isShippingLine) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cobalt.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.cobalt.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('🚢 ${l10n.shippingLineDetailsHeader}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: scacCtrl,
suffixIcon: buildCopySuffix(scacCtrl),
                                              label: l10n.scacCarrierCodeLabel,
                                              icon: Icons.code,
                                              isRequired: true,
                                              hint: l10n.scacCarrierCodeHint,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: CustomTextField(
                                              controller: trackingCtrl,
suffixIcon: buildCopySuffix(trackingCtrl),
                                              label: l10n.trackingWebUrlLabel,
                                              icon: Icons.link,
                                              hint: l10n.trackingWebUrlHint,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (isCustomsBroker) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.orange.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.orange.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('🛂 ${l10n.customsBrokerLicenseHeader}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.orange)),
                                      const SizedBox(height: 10),
                                      CustomTextField(
                                        controller: licenseCtrl,
suffixIcon: buildCopySuffix(licenseCtrl),
                                        label: l10n.customsClearanceLicenseNumLabel,
                                        icon: Icons.assignment_ind,
                                        isRequired: true,
                                        hint: l10n.customsClearanceLicenseNumHint,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: taxIdCtrl,
suffixIcon: buildCopySuffix(taxIdCtrl),
                                      label: l10n.partnerTaxIdLabel,
                                      icon: Icons.receipt_long,
                                      hint: l10n.partnerTaxIdHint,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: regCtrl,
suffixIcon: buildCopySuffix(regCtrl),
                                      label: l10n.partnerCommercialRegLabel,
                                      icon: Icons.app_registration,
                                      hint: l10n.partnerCommercialRegHint,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: emailCtrl,
suffixIcon: buildCopySuffix(emailCtrl),
                                      label: l10n.partnerPrimaryEmailLabel,
                                      icon: Icons.email,
                                      hint: l10n.partnerPrimaryEmailHint,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: secondaryEmailCtrl,
suffixIcon: buildCopySuffix(secondaryEmailCtrl),
                                      label: l10n.partnerSecondaryEmailLabel,
                                      icon: Icons.mark_email_read_outlined,
                                      hint: l10n.partnerSecondaryEmailHint,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: phoneCtrl,
suffixIcon: buildCopySuffix(phoneCtrl),
                                      label: l10n.partnerPhoneLabel,
                                      icon: Icons.phone,
                                      hint: l10n.partnerPhoneHint,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: mobileCtrl,
suffixIcon: buildCopySuffix(mobileCtrl),
                                      label: l10n.partnerMobileLabel,
                                      icon: Icons.smartphone,
                                      hint: l10n.partnerMobileHint,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: faxCtrl,
suffixIcon: buildCopySuffix(faxCtrl),
                                      label: l10n.partnerFaxLabel,
                                      icon: Icons.print,
                                      hint: l10n.partnerFaxHint,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                controller: websiteCtrl,
suffixIcon: buildCopySuffix(websiteCtrl),
                                label: l10n.partnerWebsiteUrlLabel,
                                icon: Icons.language,
                                hint: l10n.partnerWebsiteUrlHint,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: addressCtrl,
suffixIcon: buildCopySuffix(addressCtrl),
                                      label: l10n.partnerAddressLabel,
                                      icon: Icons.location_on,
                                      hint: l10n.partnerAddressHint,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: countryCtrl,
suffixIcon: buildCopySuffix(countryCtrl),
                                      label: l10n.partnerCountryLabelField,
                                      icon: Icons.flag,
                                      isRequired: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Actions
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
                            onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                            icon: const Icon(Icons.close, size: 16, color: AppTheme.crimson),
                            label: Text(l10n.cancelAndCloseBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: isSubmitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check, size: 18),
                            label: Text(isSubmitting ? l10n.savingChanges : (isEditing ? l10n.updatePartnerBtn : l10n.savePartnerBtn)),
                            onPressed: isSubmitting ? null : () async {
                              if (!formKey.currentState!.validate() || selectedCategories.isEmpty) {
                                return;
                              }

                              setDialogState(() {
                                isSubmitting = true;
                              });

                              final partnerTypeJoined = selectedCategories.join(', ');

                              final partner = PartnerModel(
                                providerId: partnerToEdit?.providerId,
                                partnerCode: partnerToEdit?.partnerCode ?? '',
                                partnerName: nameCtrl.text.trim(),
                                partnerType: partnerTypeJoined,
                                taxId: taxIdCtrl.text.trim().isEmpty ? null : taxIdCtrl.text.trim(),
                                commercialRegister: regCtrl.text.trim().isEmpty ? null : regCtrl.text.trim(),
                                clearanceLicenseNumber: licenseCtrl.text.trim().isEmpty ? null : licenseCtrl.text.trim(),
                                scacCode: scacCtrl.text.trim().isEmpty ? null : scacCtrl.text.trim(),
                                trackingUrl: trackingCtrl.text.trim().isEmpty ? null : trackingCtrl.text.trim(),
                                swiftCode: swiftCtrl.text.trim().isEmpty ? null : swiftCtrl.text.trim(),
                                bankCode: bankCodeCtrl.text.trim().isEmpty ? null : bankCodeCtrl.text.trim(),
                                branchName: branchCtrl.text.trim().isEmpty ? null : branchCtrl.text.trim(),
                                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                                secondaryEmail: secondaryEmailCtrl.text.trim().isEmpty ? null : secondaryEmailCtrl.text.trim(),
                                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                mobile: mobileCtrl.text.trim().isEmpty ? null : mobileCtrl.text.trim(),
                                fax: faxCtrl.text.trim().isEmpty ? null : faxCtrl.text.trim(),
                                website: websiteCtrl.text.trim().isEmpty ? null : websiteCtrl.text.trim(),
                                address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                                country: countryCtrl.text.trim(),
                                isActive: partnerToEdit?.isActive ?? true,
                              );

                              String? errorMessage;
                              if (isEditing && partnerToEdit.providerId != null) {
                                final List<FieldChangeItem> changes = [];
                                if (FieldChangeItem.isDifferent(partnerToEdit.partnerName, partner.partnerName)) {
                                  changes.add(FieldChangeItem(fieldName: l10n.diffPartnerName, oldValue: partnerToEdit.partnerName, newValue: partner.partnerName));
                                }
                                if (FieldChangeItem.isDifferent(partnerToEdit.partnerType, partner.partnerType)) {
                                  changes.add(FieldChangeItem(fieldName: l10n.diffPartnerType, oldValue: partnerToEdit.partnerType, newValue: partner.partnerType));
                                }
                                if (FieldChangeItem.isDifferent(partnerToEdit.email, partner.email)) {
                                  changes.add(FieldChangeItem(fieldName: l10n.diffPartnerEmail, oldValue: partnerToEdit.email, newValue: partner.email));
                                }
                                if (FieldChangeItem.isDifferent(partnerToEdit.phone, partner.phone)) {
                                  changes.add(FieldChangeItem(fieldName: l10n.diffPartnerPhone, oldValue: partnerToEdit.phone, newValue: partner.phone));
                                }
                                if (FieldChangeItem.isDifferent(partnerToEdit.address, partner.address)) {
                                  changes.add(FieldChangeItem(fieldName: l10n.diffPartnerAddress, oldValue: partnerToEdit.address, newValue: partner.address));
                                }
                                if (FieldChangeItem.isDifferent(partnerToEdit.country, partner.country)) {
                                  changes.add(FieldChangeItem(fieldName: l10n.diffPartnerCountry, oldValue: partnerToEdit.country, newValue: partner.country));
                                }

                                if (changes.isNotEmpty) {
                                  final confirmed = await showChangeDiffConfirmationDialog(
                                    context,
                                    title: l10n.diffConfirmPartnerTitle,
                                    itemReference: '${partnerToEdit.partnerCode} (${partnerToEdit.partnerName})',
                                    changes: changes,
                                  );
                                  if (!confirmed) {
                                    setDialogState(() => isSubmitting = false);
                                    return;
                                  }
                                }

                                errorMessage = await ref.read(partnersProvider.notifier).updatePartner(partnerToEdit.providerId!, partner);
                              } else {
                                errorMessage = await ref.read(partnersProvider.notifier).createPartner(partner);
                              }

                              if (errorMessage == null) {
                                if (context.mounted) {
                                  Navigator.pop(dialogCtx);
                                }
                              } else {
                                setDialogState(() {
                                  isSubmitting = false;
                                });
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
            ),
          );
        },
      );
      },
    ).then((_) {
      nameCtrl.dispose();
      taxIdCtrl.dispose();
      regCtrl.dispose();
      licenseCtrl.dispose();
      scacCtrl.dispose();
      trackingCtrl.dispose();
      swiftCtrl.dispose();
      bankCodeCtrl.dispose();
      branchCtrl.dispose();
      phoneCtrl.dispose();
      mobileCtrl.dispose();
      faxCtrl.dispose();
      emailCtrl.dispose();
      secondaryEmailCtrl.dispose();
      websiteCtrl.dispose();
      addressCtrl.dispose();
      countryCtrl.dispose();
    });
  }
}
