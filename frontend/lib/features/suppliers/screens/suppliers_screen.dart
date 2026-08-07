import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/row_context_menu.dart';
import '../models/supplier_model.dart';
import '../providers/suppliers_provider.dart';
import '../../audit_logs/widgets/row_history_dialog.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(suppliersProvider.notifier).fetchSuppliers();
    });
  }

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
                        'Foreign Suppliers Directory (MD-002)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage Exporter Profile, Foreign Registration ID, CargoX / Nafeza ID & Origin Country',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Foreign Supplier'),
                  onPressed: () => _showSupplierDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                        hintText: 'Search by Supplier Name, Code, CargoX ID, Registration #, or Country...',
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
                          ref.read(showInactiveSuppliersProvider.notifier).state = val;
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
                    final q = _searchQuery;
                    return q.isEmpty ||
                        s.companyName.toLowerCase().contains(q) ||
                        s.supplierCode.toLowerCase().contains(q) ||
                        s.foreignExporterId.toLowerCase().contains(q) ||
                        s.foreignExporterCountry.toLowerCase().contains(q) ||
                        (s.brands?.toLowerCase().contains(q) ?? false);
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

    return GestureDetector(
      onSecondaryTapDown: (details) {
        RowContextMenuHelper.showContextMenu(
          context: context,
          globalPosition: details.globalPosition,
          codeToCopy: supplier.supplierCode,
          onEdit: () => _showSupplierDialog(context, supplierToEdit: supplier),
          onHistory: () => RowHistoryDialog.show(
            context,
            entityType: 'Supplier',
            entityId: supplier.supplierId!,
            entityTitle: supplier.companyName,
          ),
          isActive: isActive,
          onToggleActive: () async {
            if (supplier.supplierId != null) {
              await ref.read(suppliersProvider.notifier).toggleActiveStatus(supplier.supplierId!, isActive);
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isActive ? AppTheme.emerald : AppTheme.crimson).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Exporter ID: ${supplier.foreignExporterId} | Address: ${supplier.address} | Brands: ${supplier.brands ?? "N/A"}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
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

              // Actions: Edit, History Log & Switch
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history, color: AppTheme.charcoal, size: 20),
                    tooltip: 'View Change History Logs',
                    onPressed: () {
                      if (supplier.supplierId != null) {
                        RowHistoryDialog.show(
                          context,
                          entityType: 'Supplier',
                          entityId: supplier.supplierId!,
                          entityTitle: supplier.companyName,
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.cobalt, size: 20),
                    tooltip: 'Edit Foreign Supplier',
                    onPressed: () => _showSupplierDialog(context, supplierToEdit: supplier),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showSupplierDialog(BuildContext context, {SupplierModel? supplierToEdit}) {
    final isEditing = supplierToEdit != null;
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: supplierToEdit?.companyName ?? '');
    final typeCtrl = TextEditingController(text: supplierToEdit?.supplierType ?? 'Manufacturer');
    final regTypeCtrl = TextEditingController(text: supplierToEdit?.registrationType ?? 'Factory');
    final expIdCtrl = TextEditingController(text: supplierToEdit?.foreignExporterId ?? '');
    final countryCtrl = TextEditingController(text: supplierToEdit?.foreignExporterCountry ?? '');
    final countryCodeCtrl = TextEditingController(text: supplierToEdit?.foreignExporterCountryCode ?? '');
    final addressCtrl = TextEditingController(text: supplierToEdit?.address ?? '');
    final phoneCtrl = TextEditingController(text: supplierToEdit?.phone ?? '');
    final emailCtrl = TextEditingController(text: supplierToEdit?.email ?? '');
    final brandsCtrl = TextEditingController(text: supplierToEdit?.brands ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 600,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: AppTheme.charcoal,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(isEditing ? Icons.edit : Icons.public, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        isEditing ? 'Edit Foreign Exporter & Supplier (MD-002)' : 'Add Foreign Exporter & Supplier (MD-002)',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Form Body
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
                        label: Text(isEditing ? 'Update Supplier' : 'Save Foreign Supplier'),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final supplier = SupplierModel(
                            supplierId: supplierToEdit?.supplierId,
                            supplierCode: supplierToEdit?.supplierCode ?? '',
                            companyName: nameCtrl.text.trim(),
                            supplierType: typeCtrl.text.trim(),
                            registrationType: regTypeCtrl.text.trim(),
                            foreignExporterId: expIdCtrl.text.trim(),
                            foreignExporterCountry: countryCtrl.text.trim(),
                            foreignExporterCountryCode: countryCodeCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                            email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                            brands: brandsCtrl.text.trim().isEmpty ? null : brandsCtrl.text.trim(),
                            isActive: supplierToEdit?.isActive ?? true,
                          );

                          String? errorMessage;
                          if (isEditing && supplierToEdit.supplierId != null) {
                            errorMessage = await ref.read(suppliersProvider.notifier).updateSupplier(supplierToEdit.supplierId!, supplier);
                          } else {
                            errorMessage = await ref.read(suppliersProvider.notifier).createSupplier(supplier);
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
