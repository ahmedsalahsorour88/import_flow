import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/custom_text_field.dart';

import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                Row(
                  children: [
                    const BackToDashboardButton(),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Foreign Supplier'),
                      onPressed: () => _showSupplierDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Master Data Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'suppliers',
              title: 'Foreign_Suppliers',
              onRefreshNeeded: () => ref.refresh(suppliersProvider.notifier).fetchSuppliers(),
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
                          ref.read(suppliersProvider.notifier).fetchSuppliers();
                        },
                      ),
                    ],
                  ),
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
    String selectedSupplierType = supplierToEdit?.supplierType ?? 'Manufacturer';
    String selectedRegType = supplierToEdit?.registrationType ?? 'Factory Registration';

    final supplierTypeOptions = [
      'Manufacturer',
      'Foreign Supplier / Trader',
      'Authorized Agent / Distributor',
      'Exporter',
    ];

    final regTypeOptions = [
      'Factory Registration',
      'Foreign Exporter Number (Nafeza)',
      'VAT Registration / Tax Number',
      'Commercial Register',
    ];

    final expIdCtrl = TextEditingController(text: supplierToEdit?.foreignExporterId ?? '');
    final countryCtrl = TextEditingController(text: supplierToEdit?.foreignExporterCountry ?? '');
    final countryCodeCtrl = TextEditingController(text: supplierToEdit?.foreignExporterCountryCode ?? '');
    final addressCtrl = TextEditingController(text: supplierToEdit?.address ?? '');
    final phoneCtrl = TextEditingController(text: supplierToEdit?.phone ?? '');
    final mobileCtrl = TextEditingController(text: supplierToEdit?.mobile ?? '');
    final faxCtrl = TextEditingController(text: supplierToEdit?.fax ?? '');
    final emailCtrl = TextEditingController(text: supplierToEdit?.email ?? '');
    final secondaryEmailCtrl = TextEditingController(text: supplierToEdit?.secondaryEmail ?? '');
    final websiteCtrl = TextEditingController(text: supplierToEdit?.website ?? '');
    final brandsCtrl = TextEditingController(text: supplierToEdit?.brands ?? '');
    final notesCtrl = TextEditingController(text: supplierToEdit?.notes ?? '');

    bool hasIso = supplierToEdit?.hasIso ?? false;
    bool registeredDecree43 = supplierToEdit?.registeredDecree43 ?? false;
    bool whiteListRegistered = supplierToEdit?.whiteListRegistered ?? false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                width: 650,
                height: MediaQuery.of(context).size.height * 0.9,
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
                                hint: 'e.g. G.I. Industrial Holding S.p.A.',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // Supplier Type Dropdown
                                  Expanded(
                                    child: SearchableDropdownField<String>(
                                      value: supplierTypeOptions.contains(selectedSupplierType) ? selectedSupplierType : supplierTypeOptions.first,
                                      labelText: 'Supplier Type *',
                                      items: supplierTypeOptions
                                          .map((type) => SearchableDropdownItem<String>(
                                                value: type,
                                                label: type,
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() => selectedSupplierType = val);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Registration Type Dropdown
                                  Expanded(
                                    child: SearchableDropdownField<String>(
                                      value: regTypeOptions.contains(selectedRegType) ? selectedRegType : regTypeOptions.first,
                                      labelText: 'Registration Type *',
                                      items: regTypeOptions
                                          .map((type) => SearchableDropdownItem<String>(
                                                value: type,
                                                label: type,
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() => selectedRegType = val);
                                        }
                                      },
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
                                      hint: 'Italy, China, Germany, etc.',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: countryCodeCtrl,
                                      label: 'Country Code (ISO 2-letter)',
                                      icon: Icons.code,
                                      isRequired: true,
                                      hint: 'IT, CN, DE, US, etc.',
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
                                hint: 'Via G. Agnelli, 7 - 33053 Latisana (UD) - Italy',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: emailCtrl,
                                      label: 'Primary Email',
                                      icon: Icons.email,
                                      hint: 'export@supplier.com',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: secondaryEmailCtrl,
                                      label: 'Secondary / Additional Email',
                                      icon: Icons.mark_email_read_outlined,
                                      hint: 'sales@supplier.com',
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
                                      label: 'Telephone Number',
                                      icon: Icons.phone,
                                      hint: '+39 0432 823011',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: mobileCtrl,
                                      label: 'Mobile Number',
                                      icon: Icons.smartphone,
                                      hint: '+39 335 1234567',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: faxCtrl,
                                      label: 'Fax Number',
                                      icon: Icons.print,
                                      hint: '+39 0432 773855',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: websiteCtrl,
                                label: 'Website URL',
                                icon: Icons.language,
                                hint: 'www.gind.it',
                              ),
                              const SizedBox(height: 16),
                              // Compliance Flags Section
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Compliance & Certifications:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('ISO Certified (لديه شهادة ISO)'),
                                      value: hasIso,
                                      activeColor: AppTheme.cobalt,
                                      onChanged: (val) => setDialogState(() => hasIso = val ?? false),
                                    ),
                                    CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Registered under Decree 43 / GOEIC (مسجل بقرار 43 للهيئة العامة للرقابة)'),
                                      value: registeredDecree43,
                                      activeColor: AppTheme.cobalt,
                                      onChanged: (val) => setDialogState(() => registeredDecree43 = val ?? false),
                                    ),
                                    CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('White List Registered Exporter (مسجل بالقائمة الاستيرادية البيضاء)'),
                                      value: whiteListRegistered,
                                      activeColor: AppTheme.emerald,
                                      onChanged: (val) => setDialogState(() => whiteListRegistered = val ?? false),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: brandsCtrl,
                                label: 'Brands / Product Lines',
                                icon: Icons.branding_watermark,
                                hint: 'e.g. Clint, Novair, ProPower',
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: notesCtrl,
                                label: 'Notes',
                                icon: Icons.notes,
                                hint: 'Any additional supplier details...',
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
                                supplierType: selectedSupplierType,
                                registrationType: selectedRegType,
                                foreignExporterId: expIdCtrl.text.trim(),
                                foreignExporterCountry: countryCtrl.text.trim(),
                                foreignExporterCountryCode: countryCodeCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                mobile: mobileCtrl.text.trim().isEmpty ? null : mobileCtrl.text.trim(),
                                fax: faxCtrl.text.trim().isEmpty ? null : faxCtrl.text.trim(),
                                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                                secondaryEmail: secondaryEmailCtrl.text.trim().isEmpty ? null : secondaryEmailCtrl.text.trim(),
                                website: websiteCtrl.text.trim().isEmpty ? null : websiteCtrl.text.trim(),
                                hasIso: hasIso,
                                registeredDecree43: registeredDecree43,
                                whiteListRegistered: whiteListRegistered,
                                brands: brandsCtrl.text.trim().isEmpty ? null : brandsCtrl.text.trim(),
                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
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
      },
    );
  }
}
