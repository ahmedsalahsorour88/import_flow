import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/import_company_model.dart';
import '../providers/import_companies_provider.dart';

class ImportCompaniesScreen extends ConsumerStatefulWidget {
  const ImportCompaniesScreen({super.key});

  @override
  ConsumerState<ImportCompaniesScreen> createState() => _ImportCompaniesScreenState();
}

class _ImportCompaniesScreenState extends ConsumerState<ImportCompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
                    children: const [
                      Text(
                        'Egyptian Import Companies (MD-001)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage Egyptian Importers, Registration IDs, Active Status & Expiry Rules',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    // Show Deactivated Filter Switch
                    Row(
                      children: [
                        const Text('Include Deactivated:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.charcoal)),
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
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add_business),
                      label: const Text('Add Importer Company', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _showAddCompanyDialog(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: AppTheme.charcoal),
                  hintText: 'Search by importer name, reg number, or VAT ID...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Data Table Content
            Expanded(
              child: companiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cobalt)),
                error: (err, stack) => Center(
                  child: Text('Error loading companies: $err', style: const TextStyle(color: AppTheme.crimson)),
                ),
                data: (companies) {
                  final filtered = companies.where((c) {
                    return c.importerName.toLowerCase().contains(_searchQuery) ||
                        c.importerId.toLowerCase().contains(_searchQuery) ||
                        c.registrationNumber.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No import companies found.', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
    final isActive = company.isActive;

    return Opacity(
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
                    '${company.country} • ${company.address}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Importer ID & Badge
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Importer ID: ${company.importerId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  _buildExpiryBadge(company.daysUntilImporterIdExpiry, 'Importer Card'),
                ],
              ),
            ),

            // VAT & Badge
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VAT ID: ${company.vatId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  _buildExpiryBadge(company.daysUntilVatExpiry, 'VAT'),
                ],
              ),
            ),

            // Reg Number & Badge
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reg #: ${company.registrationNumber}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  _buildExpiryBadge(company.daysUntilRegExpiry, 'Com. Reg'),
                ],
              ),
            ),

            // Active / Deactive Toggle Button Action
            Tooltip(
              message: isActive ? 'Deactivate Company' : 'Reactivate Company',
              child: Switch(
                value: isActive,
                activeColor: AppTheme.emerald,
                inactiveThumbColor: AppTheme.crimson,
                onChanged: (newStatus) {
                  if (company.companyId != null) {
                    ref.read(importCompaniesProvider.notifier).toggleActiveStatus(company.companyId!, isActive);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryBadge(int daysLeft, String label) {
    Color bg;
    Color fg;
    String statusText;

    if (daysLeft < 0) {
      bg = AppTheme.crimson.withOpacity(0.15);
      fg = AppTheme.crimson;
      statusText = 'Expired';
    } else if (daysLeft <= 30) {
      bg = AppTheme.orange.withOpacity(0.15);
      fg = AppTheme.orange;
      statusText = '$daysLeft days left';
    } else {
      bg = AppTheme.emerald.withOpacity(0.15);
      fg = AppTheme.emerald;
      statusText = 'Valid ($daysLeft d)';
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

  void _showAddCompanyDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final countryCtrl = TextEditingController(text: 'Egypt');
    final impIdCtrl = TextEditingController();
    final vatIdCtrl = TextEditingController();
    final regNumCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    DateTime impExpiry = DateTime.now().add(const Duration(days: 365));
    DateTime vatExpiry = DateTime.now().add(const Duration(days: 365));
    DateTime regExpiry = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Add Egyptian Import Company', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Company Name *')),
                  TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address *')),
                  TextField(controller: countryCtrl, decoration: const InputDecoration(labelText: 'Country *')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: impIdCtrl, decoration: const InputDecoration(labelText: 'Importer Card ID *'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: vatIdCtrl, decoration: const InputDecoration(labelText: 'VAT Registration ID *'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: regNumCtrl, decoration: const InputDecoration(labelText: 'Commercial Reg Number *'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || impIdCtrl.text.isEmpty || vatIdCtrl.text.isEmpty || regNumCtrl.text.isEmpty) {
                  return;
                }

                final newCompany = ImportCompanyModel(
                  importerName: nameCtrl.text,
                  address: addressCtrl.text,
                  country: countryCtrl.text,
                  importerId: impIdCtrl.text,
                  importerIdExpiry: impExpiry,
                  vatId: vatIdCtrl.text,
                  vatIdExpiry: vatExpiry,
                  registrationNumber: regNumCtrl.text,
                  registrationExpiry: regExpiry,
                  phone: phoneCtrl.text,
                );

                final success = await ref.read(importCompaniesProvider.notifier).createCompany(newCompany);
                if (success && context.mounted) {
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Save Company', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
