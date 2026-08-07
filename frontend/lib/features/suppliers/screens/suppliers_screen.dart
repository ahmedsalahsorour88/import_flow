import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/supplier_model.dart';
import '../providers/suppliers_provider.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final showInactive = ref.watch(showInactiveSuppliersProvider);

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
                        'Foreign Exporters & Suppliers (MD-002)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage International Suppliers, Foreign Exporter Registration & Nafeza Compliance',
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
                            ref.read(showInactiveSuppliersProvider.notifier).state = val;
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
                      icon: const Icon(Icons.public),
                      label: const Text('Add Foreign Supplier', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _showAddSupplierDialog(context),
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
                  hintText: 'Search by supplier name, code, foreign exporter ID or country...',
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
              child: suppliersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cobalt)),
                error: (err, stack) => Center(
                  child: Text('Error loading suppliers: $err', style: const TextStyle(color: AppTheme.crimson)),
                ),
                data: (suppliers) {
                  final filtered = suppliers.where((s) {
                    return s.companyName.toLowerCase().contains(_searchQuery) ||
                        s.supplierCode.toLowerCase().contains(_searchQuery) ||
                        s.foreignExporterId.toLowerCase().contains(_searchQuery) ||
                        s.foreignExporterCountry.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No foreign suppliers found.', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                        final supplier = filtered[index];
                        return _buildSupplierRow(supplier);
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

  Widget _buildSupplierRow(SupplierModel supplier) {
    final isActive = supplier.isActive;

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
              child: Icon(Icons.factory, color: isActive ? AppTheme.cobalt : Colors.grey),
            ),
            const SizedBox(width: 16),

            // Supplier Code & Name
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
                          supplier.supplierCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        supplier.companyName,
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
                    '${supplier.address} • Brands: ${supplier.brands ?? "N/A"}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Exporter ID
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exporter ID:', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(supplier.foreignExporterId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Country & Code Badge
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          supplier.foreignExporterCountryCode.toUpperCase(),
                          style: const TextStyle(color: AppTheme.orange, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(supplier.foreignExporterCountry, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Type: ${supplier.supplierType} (${supplier.registrationType})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),

            // Contact Info
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(supplier.email ?? 'No email', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(supplier.phone ?? 'No phone', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            // Active / Deactive Toggle Button Action
            Tooltip(
              message: isActive ? 'Deactivate Supplier' : 'Reactivate Supplier',
              child: Switch(
                value: isActive,
                activeColor: AppTheme.emerald,
                inactiveThumbColor: AppTheme.crimson,
                onChanged: (newStatus) {
                  if (supplier.supplierId != null) {
                    ref.read(suppliersProvider.notifier).toggleActiveStatus(supplier.supplierId!, isActive);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(text: 'Manufacturer');
    final regTypeCtrl = TextEditingController(text: 'Factory');
    final expIdCtrl = TextEditingController();
    final countryCtrl = TextEditingController();
    final countryCodeCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final brandsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Add Foreign Supplier (MD-002)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Company Name *')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Supplier Type (Manufacturer/Trader)'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: regTypeCtrl, decoration: const InputDecoration(labelText: 'Reg Type (Factory/Company)'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: expIdCtrl, decoration: const InputDecoration(labelText: 'Foreign Exporter ID (Nafeza Registration) *')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: countryCtrl, decoration: const InputDecoration(labelText: 'Country *'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: countryCodeCtrl, decoration: const InputDecoration(labelText: 'Country Code (e.g. CN, DE, US) *'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address *')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: brandsCtrl, decoration: const InputDecoration(labelText: 'Brands / Product Lines')),
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
                if (nameCtrl.text.isEmpty || expIdCtrl.text.isEmpty || countryCtrl.text.isEmpty || countryCodeCtrl.text.isEmpty) {
                  return;
                }

                final newSupplier = SupplierModel(
                  supplierCode: '', // Auto-generated by backend
                  companyName: nameCtrl.text,
                  supplierType: typeCtrl.text,
                  registrationType: regTypeCtrl.text,
                  foreignExporterId: expIdCtrl.text,
                  foreignExporterCountry: countryCtrl.text,
                  foreignExporterCountryCode: countryCodeCtrl.text,
                  address: addressCtrl.text,
                  phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                  email: emailCtrl.text.isEmpty ? null : emailCtrl.text,
                  brands: brandsCtrl.text.isEmpty ? null : brandsCtrl.text,
                );

                final success = await ref.read(suppliersProvider.notifier).createSupplier(newSupplier);
                if (success && context.mounted) {
                  Navigator.pop(dialogCtx);
                }
              },
              child: const Text('Save Supplier', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
