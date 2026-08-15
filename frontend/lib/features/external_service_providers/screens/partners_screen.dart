import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/change_diff_dialog.dart';
import '../../../core/widgets/custom_text_field.dart';

import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../models/partner_model.dart';
import '../providers/partners_provider.dart';
import '../../audit_logs/widgets/row_history_dialog.dart';

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
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(partnersProvider.notifier).fetchPartners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(partnersProvider);
    final selectedCategory = ref.watch(selectedPartnerCategoryProvider);
    final showInactive = ref.watch(showInactivePartnersProvider);

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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'External Partners & Service Providers (MD-003)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage Commercial Banks, Shipping Lines, Customs Brokers, Freight Forwarders & Logistics Partners',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const BackToDashboardButton(),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add External Partner'),
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
                        cat,
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
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: AppTheme.charcoal),
                        hintText: 'Search by partner name, code, SWIFT, license #, tax ID, or country...',
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
                      const Text(
                        'Show Inactive:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.crimson),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'تعذر الاتصال بالسيرفر (DioException / Connection Error)\n$err',
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
                        label: const Text('إعادة المحاولة (Retry Connection)', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ref.read(partnersProvider.notifier).fetchPartners();
                        },
                      ),
                    ],
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
                    return const Center(
                      child: Text('No partners found for selected filters.', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width > 1100
                                  ? MediaQuery.of(context).size.width - 300
                                  : 950,
                            ),
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(110),
                                1: FlexColumnWidth(3),
                                2: FlexColumnWidth(2.5),
                                3: FlexColumnWidth(2),
                                4: FixedColumnWidth(85),
                                5: FixedColumnWidth(150),
                              },
                              children: [
                                // Table Header
                                TableRow(
                                  decoration: const BoxDecoration(color: AppTheme.charcoal),
                                  children: [
                                    'Code',
                                    'Partner Name & Category',
                                    'Registration & License',
                                    'Contact Details',
                                    'Status',
                                    'Actions'
                                  ]
                                      .map((h) => Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.charcoal.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            partner.partnerCode,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: AppTheme.charcoal,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Partner Name & Categories
                                      _cell(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
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
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: categories.map((cat) => _buildCategoryBadge(cat)).toList(),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Registration & Identifiers
                                      _cell(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (partner.swiftCode != null && partner.swiftCode!.isNotEmpty)
                                              Text('SWIFT: ${partner.swiftCode}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                            if (partner.scacCode != null && partner.scacCode!.isNotEmpty)
                                              Text('SCAC: ${partner.scacCode}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                            if (partner.clearanceLicenseNumber != null && partner.clearanceLicenseNumber!.isNotEmpty)
                                              Text('License: ${partner.clearanceLicenseNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.orange), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            if (partner.commercialRegister != null && partner.commercialRegister!.isNotEmpty)
                                              Text('Reg: ${partner.commercialRegister}', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text('Country: ${partner.country}', style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),

                                      // Contact Details
                                      _cell(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(partner.email ?? 'No email', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text(partner.phone ?? 'No phone', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),

                                      // Status
                                      _cell(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: (isActive ? AppTheme.emerald : AppTheme.crimson).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: isActive ? AppTheme.emerald : AppTheme.crimson,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                       // Actions: View, Edit, Print, Delete
                                       _cell(
                                         child: RowActionsPill(
                                           onView: () {
                                             if (partner.providerId != null) {
                                               RowHistoryDialog.show(
                                                 context,
                                                 entityType: 'ExternalServiceProvider',
                                                 entityId: partner.providerId!,
                                                 entityTitle: partner.partnerName,
                                               );
                                             }
                                           },
                                           onEdit: () => _showPartnerDialog(context, partner),
                                           onPrint: () {
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(
                                                 content: Text('طباعة بيانات الشريك: ${partner.partnerName} (${partner.partnerCode})'),
                                                 backgroundColor: AppTheme.charcoal,
                                                 duration: const Duration(seconds: 2),
                                               ),
                                             );
                                           },
                                           onDelete: () async {
                                             final confirm = await showDialog<bool>(
                                               context: context,
                                               builder: (ctx) => AlertDialog(
                                                 title: const Text('تأكيد الإجراء'),
                                                 content: Text(isActive
                                                     ? 'هل أنت متأكد من رغبتك في إيقاف تفعيل الشريك (${partner.partnerName})؟'
                                                     : 'هل أنت متأكد من إعادة تفعيل الشريك (${partner.partnerName})؟'),
                                                 actions: [
                                                   TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                                   ElevatedButton(
                                                     onPressed: () => Navigator.pop(ctx, true),
                                                     style: ElevatedButton.styleFrom(backgroundColor: isActive ? AppTheme.crimson : AppTheme.emerald),
                                                     child: Text(isActive ? 'إيقاف التفعيل' : 'تفعيل', style: const TextStyle(color: Colors.white)),
                                                   ),
                                                 ],
                                               ),
                                             );
                                             if (confirm == true && partner.providerId != null) {
                                               ref.read(partnersProvider.notifier).toggleActiveStatus(partner.providerId!, isActive);
                                             }
                                           },
                                           deleteTooltip: isActive ? 'إيقاف تفعيل الشريك (Deactivate)' : 'إعادة تفعيل الشريك (Activate)',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell({required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );

  Widget _buildCategoryBadge(String cat) {
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
        cat,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }



  void _showPartnerDialog(BuildContext context, [PartnerModel? partnerToEdit]) {
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

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        children: [
                          Icon(isEditing ? Icons.edit : Icons.add_business, color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            isEditing ? 'Edit External Partner & Bank (MD-003)' : 'Add External Partner & Bank (MD-003)',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                              const Row(
                                children: [
                                  Text(
                                    'Partner Categories (Select one or multiple) *',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.charcoal),
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
                                    label: Text(cat),
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
                                label: 'Partner / Company Name',
                                icon: Icons.business,
                                isRequired: true,
                                hint: 'e.g. National Bank of Egypt / Maersk Line / Cargo Logistics LLC',
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
                                      const Text('🏦 Banking Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: swiftCtrl,
                                              label: 'SWIFT Code',
                                              icon: Icons.code,
                                              isRequired: true,
                                              hint: 'NBEGEGXCAXXX',
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: CustomTextField(
                                              controller: bankCodeCtrl,
                                              label: 'Bank Code',
                                              icon: Icons.account_balance,
                                              hint: 'NBE',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      CustomTextField(
                                        controller: branchCtrl,
                                        label: 'Branch Name',
                                        icon: Icons.location_city,
                                        hint: 'Main Branch, Cairo',
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
                                      const Text('🚢 Shipping Line Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt)),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              controller: scacCtrl,
                                              label: 'SCAC / Carrier Code',
                                              icon: Icons.code,
                                              isRequired: true,
                                              hint: 'MAEU / MSKU',
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: CustomTextField(
                                              controller: trackingCtrl,
                                              label: 'Tracking Web URL',
                                              icon: Icons.link,
                                              hint: 'https://www.maersk.com/tracking/',
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
                                      const Text('🛂 Customs Broker License', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.orange)),
                                      const SizedBox(height: 10),
                                      CustomTextField(
                                        controller: licenseCtrl,
                                        label: 'Customs Clearance License #',
                                        icon: Icons.assignment_ind,
                                        isRequired: true,
                                        hint: 'LIC-CAI-9988',
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
                                      label: 'Tax Registration ID',
                                      icon: Icons.receipt_long,
                                      hint: 'TAX-100200',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: regCtrl,
                                      label: 'Commercial Reg #',
                                      icon: Icons.app_registration,
                                      hint: 'REG-554433',
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
                                      label: 'Primary Email',
                                      icon: Icons.email,
                                      hint: 'contact@partner.com',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: secondaryEmailCtrl,
                                      label: 'Secondary / Additional Email',
                                      icon: Icons.mark_email_read_outlined,
                                      hint: 'trade@partner.com',
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
                                      label: 'Phone Number',
                                      icon: Icons.phone,
                                      hint: '+20 2 2555 5555',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: mobileCtrl,
                                      label: 'Mobile Number',
                                      icon: Icons.smartphone,
                                      hint: '+20 100 1234567',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: faxCtrl,
                                      label: 'Fax Number',
                                      icon: Icons.print,
                                      hint: '+20 2 2577 0000',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                controller: websiteCtrl,
                                label: 'Website URL',
                                icon: Icons.language,
                                hint: 'www.partner.com',
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: addressCtrl,
                                      label: 'Address',
                                      icon: Icons.location_on,
                                      hint: 'Downtown, Cairo',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: countryCtrl,
                                      label: 'Country',
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
                          OutlinedButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: isSubmitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check, size: 18),
                            label: Text(isSubmitting ? 'Saving Changes...' : (isEditing ? 'Update Partner' : 'Save External Partner')),
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
                                  changes.add(FieldChangeItem(fieldName: 'اسم مقدم الخدمة / الشريك', oldValue: partnerToEdit.partnerName, newValue: partner.partnerName));
                                }
                                if (FieldChangeItem.isDifferent(partnerToEdit.partnerType, partner.partnerType)) {
                                  changes.add(FieldChangeItem(fieldName: 'نوع الشريك (Partner Type)', oldValue: partnerToEdit.partnerType, newValue: partner.partnerType));
                                }
                                if (FieldChangeItem.isDifferent(partnerToEdit.email, partner.email)) {
                                  changes.add(FieldChangeItem(fieldName: 'البريد الإلكتروني', oldValue: partnerToEdit.email, newValue: partner.email));
                                }
                                if (FieldChangeItem.isDifferent(partnerToEdit.phone, partner.phone)) {
                                  changes.add(FieldChangeItem(fieldName: 'الهاتف', oldValue: partnerToEdit.phone, newValue: partner.phone));
                                }
                                if (FieldChangeItem.isDifferent(partnerToEdit.address, partner.address)) {
                                  changes.add(FieldChangeItem(fieldName: 'العنوان', oldValue: partnerToEdit.address, newValue: partner.address));
                                }
                                if (FieldChangeItem.isDifferent(partnerToEdit.country, partner.country)) {
                                  changes.add(FieldChangeItem(fieldName: 'الدولة', oldValue: partnerToEdit.country, newValue: partner.country));
                                }

                                if (changes.isNotEmpty) {
                                  final confirmed = await showChangeDiffConfirmationDialog(
                                    context,
                                    title: 'مراجعة وتأكيد تعديلات مقدم الخدمة / الشريك',
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
            );
          },
        );
      },
    );
  }
}
