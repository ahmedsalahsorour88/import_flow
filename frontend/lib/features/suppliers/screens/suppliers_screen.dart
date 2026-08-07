import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
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
                      icon: const Icon(Icons.public, size: 18),
                      label: const Text('Add Foreign Supplier'),
                      onPressed: () => _showAddSupplierDialog(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

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
                  hintText: 'Search by supplier name, code, foreign exporter ID or country...',
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
                  const Text('Exporter ID:', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
    final formKey = GlobalKey<FormState>();

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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: AppTheme.charcoal,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.public, color: Colors.white, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Add Foreign Exporter & Supplier (MD-002)',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: nameCtrl,
                          label: 'Company Name',
                          icon: Icons.business,
                          isRequired: true,
                          hint: 'e.g. Zhejiang Industrial Tools Co',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: typeCtrl,
                                label: 'Supplier Type',
                                icon: Icons.category,
                                hint: 'Manufacturer / Trader / Agent',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: regTypeCtrl,
                                label: 'Registration Type',
                                icon: Icons.domain_verification,
                                hint: 'Factory / Company / Individual',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: expIdCtrl,
                          label: 'Foreign Exporter ID (Nafeza)',
                          icon: Icons.badge,
                          isRequired: true,
                          hint: 'e.g. EXP-CN-998877',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: countryCtrl,
                                label: 'Country',
                                icon: Icons.flag,
                                isRequired: true,
                                hint: 'China',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: countryCodeCtrl,
                                label: 'Country Code (ISO 2-letter)',
                                icon: Icons.code,
                                isRequired: true,
                                hint: 'CN, DE, US, etc.',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: addressCtrl,
                          label: 'Full Address',
                          icon: Icons.location_on,
                          isRequired: true,
                          hint: 'Hangzhou, Zhejiang, China',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: emailCtrl,
                                label: 'Email Address',
                                icon: Icons.email,
                                hint: 'export@supplier.com',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: phoneCtrl,
                                label: 'Phone Number',
                                icon: Icons.phone,
                                hint: '+86 571 8888 8888',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: brandsCtrl,
                          label: 'Brands / Product Lines',
                          icon: Icons.branding_watermark,
                          hint: 'e.g. Zhejiang Pro Tools, Heavy Duty Line',
                        ),
                      ],
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
                      OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save Foreign Supplier'),
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty || expIdCtrl.text.isEmpty || countryCtrl.text.isEmpty || countryCodeCtrl.text.isEmpty) {
                            return;
                          }

                          final newSupplier = SupplierModel(
                            supplierCode: '',
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
