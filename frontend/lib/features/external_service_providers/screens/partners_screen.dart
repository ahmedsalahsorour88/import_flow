import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../models/partner_model.dart';
import '../providers/partners_provider.dart';

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'External Partners & Banks (MD-003)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Centralized Master for Commercial Banks, Shipping Lines, Customs Brokers, Freight Forwarders & Logistics Providers',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Show Deactivated Switch
                    Row(
                      children: [
                        const Text('Include Deactivated:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
                        const SizedBox(width: 8),
                        Switch(
                          value: showInactive,
                          activeColor: AppTheme.cobalt,
                          onChanged: (val) {
                            ref.read(showInactivePartnersProvider.notifier).state = val;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_business, size: 18),
                      label: const Text('Add External Partner'),
                      onPressed: () => _showAddPartnerDialog(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Filter Tabs
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
                  hintText: 'Search partner by name, code, SWIFT, SCAC, or license...',
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
              child: partnersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cobalt)),
                error: (err, stack) => Center(
                  child: Text('Error loading partners: $err', style: const TextStyle(color: AppTheme.crimson)),
                ),
                data: (partners) {
                  final filtered = partners.where((p) {
                    return p.partnerName.toLowerCase().contains(_searchQuery) ||
                        p.partnerCode.toLowerCase().contains(_searchQuery) ||
                        (p.swiftCode ?? '').toLowerCase().contains(_searchQuery) ||
                        (p.scacCode ?? '').toLowerCase().contains(_searchQuery) ||
                        (p.clearanceLicenseNumber ?? '').toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No partners found in this category.', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                        final partner = filtered[index];
                        return _buildPartnerRow(partner);
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

  Widget _buildPartnerRow(PartnerModel partner) {
    final isActive = partner.isActive;
    IconData icon;
    Color color;

    switch (partner.partnerType) {
      case 'Bank':
        icon = Icons.account_balance;
        color = AppTheme.emerald;
        break;
      case 'Shipping Line':
        icon = Icons.directions_boat;
        color = AppTheme.cobalt;
        break;
      case 'Customs Broker':
        icon = Icons.assignment_ind;
        color = AppTheme.orange;
        break;
      case 'Freight Forwarder':
        icon = Icons.local_shipping;
        color = AppTheme.charcoal;
        break;
      default:
        icon = Icons.domain;
        color = AppTheme.cobalt;
    }

    return Opacity(
      opacity: isActive ? 1.0 : 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isActive ? color : Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isActive ? color : Colors.grey),
            ),
            const SizedBox(width: 16),

            // Code & Name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.charcoal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          partner.partnerCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        partner.partnerName,
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
                          color: (isActive ? AppTheme.emerald : AppTheme.crimson).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Deactivated',
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
                    '${partner.partnerType} • ${partner.country} • ${partner.address ?? "No address"}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Category Details Badge
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (partner.swiftCode != null && partner.swiftCode!.isNotEmpty)
                    Text('SWIFT: ${partner.swiftCode}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.emerald))
                  else if (partner.scacCode != null && partner.scacCode!.isNotEmpty)
                    Text('SCAC: ${partner.scacCode}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.cobalt))
                  else if (partner.clearanceLicenseNumber != null && partner.clearanceLicenseNumber!.isNotEmpty)
                    Text('License: ${partner.clearanceLicenseNumber}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.orange))
                  else
                    Text('Reg: ${partner.commercialRegister ?? "N/A"}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Terms: ${partner.paymentType}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),

            // Contact Info
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partner.email ?? 'No email', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(partner.phone ?? 'No phone', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            // Active / Deactive Switch
            Tooltip(
              message: isActive ? 'Deactivate Partner' : 'Reactivate Partner',
              child: Switch(
                value: isActive,
                activeColor: AppTheme.emerald,
                inactiveThumbColor: AppTheme.crimson,
                onChanged: (newStatus) {
                  if (partner.providerId != null) {
                    ref.read(partnersProvider.notifier).toggleActiveStatus(partner.providerId!, isActive);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPartnerDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    String partnerType = 'Bank';
    final nameCtrl = TextEditingController();
    final taxIdCtrl = TextEditingController();
    final regCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    final scacCtrl = TextEditingController();
    final trackingCtrl = TextEditingController();
    final swiftCtrl = TextEditingController();
    final bankCodeCtrl = TextEditingController();
    final branchCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final countryCtrl = TextEditingController(text: 'Egypt');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                width: 620,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: const BoxDecoration(
                        color: AppTheme.charcoal,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.add_business, color: Colors.white, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Add External Partner & Bank (MD-003)',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // Form Body
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Partner Type Dropdown
                              const Text('Partner Category *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.charcoal)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: partnerType,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.category, size: 20, color: AppTheme.charcoal),
                                ),
                                items: [
                                  'Bank',
                                  'Shipping Line',
                                  'Customs Broker',
                                  'Freight Forwarder',
                                  'Inland Transport',
                                  'Inspection Agency',
                                ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      partnerType = val;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                controller: nameCtrl,
                                label: 'Partner / Company Name',
                                icon: Icons.business,
                                isRequired: true,
                                hint: 'e.g. National Bank of Egypt / Maersk Line',
                              ),
                              const SizedBox(height: 16),

                              // Dynamic Category Fields
                              if (partnerType == 'Bank') ...[
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
                                    const SizedBox(width: 16),
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
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: branchCtrl,
                                  label: 'Branch Name',
                                  icon: Icons.location_city,
                                  hint: 'Main Branch, Cairo',
                                ),
                                const SizedBox(height: 16),
                              ] else if (partnerType == 'Shipping Line') ...[
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
                                    const SizedBox(width: 16),
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
                                const SizedBox(height: 16),
                              ] else if (partnerType == 'Customs Broker') ...[
                                CustomTextField(
                                  controller: licenseCtrl,
                                  label: 'Customs Clearance License #',
                                  icon: Icons.assignment_ind,
                                  isRequired: true,
                                  hint: 'LIC-CAI-9988',
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
                                      label: 'Email Address',
                                      icon: Icons.email,
                                      hint: 'contact@partner.com',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: phoneCtrl,
                                      label: 'Phone Number',
                                      icon: Icons.phone,
                                      hint: '+20 2 2555 5555',
                                    ),
                                  ),
                                ],
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
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Save External Partner'),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              final partner = PartnerModel(
                                partnerCode: '',
                                partnerName: nameCtrl.text.trim(),
                                partnerType: partnerType,
                                taxId: taxIdCtrl.text.trim().isEmpty ? null : taxIdCtrl.text.trim(),
                                commercialRegister: regCtrl.text.trim().isEmpty ? null : regCtrl.text.trim(),
                                clearanceLicenseNumber: licenseCtrl.text.trim().isEmpty ? null : licenseCtrl.text.trim(),
                                scacCode: scacCtrl.text.trim().isEmpty ? null : scacCtrl.text.trim(),
                                trackingUrl: trackingCtrl.text.trim().isEmpty ? null : trackingCtrl.text.trim(),
                                swiftCode: swiftCtrl.text.trim().isEmpty ? null : swiftCtrl.text.trim(),
                                bankCode: bankCodeCtrl.text.trim().isEmpty ? null : bankCodeCtrl.text.trim(),
                                branchName: branchCtrl.text.trim().isEmpty ? null : branchCtrl.text.trim(),
                                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                                country: countryCtrl.text.trim(),
                              );

                              final errorMessage = await ref.read(partnersProvider.notifier).createPartner(partner);
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
      },
    );
  }
}
