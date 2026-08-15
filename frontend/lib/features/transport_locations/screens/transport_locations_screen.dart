import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/transport_location_model.dart';
import '../providers/transport_locations_provider.dart';

class TransportLocationsScreen extends ConsumerStatefulWidget {
  const TransportLocationsScreen({super.key});

  @override
  ConsumerState<TransportLocationsScreen> createState() => _TransportLocationsScreenState();
}

class _TransportLocationsScreenState extends ConsumerState<TransportLocationsScreen> {
  String _selectedType = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _locationTypes = ['All', 'Sea Port', 'Airport', 'Dry Port', 'Land Border'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transportLocationsProvider.notifier).fetchLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(transportLocationsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ports & Transport Locations (MD-009)',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Master reference for Sea Ports, Airports, Dry Ports & Land Borders (UN/LOCODE)',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const BackToDashboardButton(),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showLocationDialog(context),
                      icon: const Icon(Icons.add_location_alt, size: 18),
                      label: const Text('Add Transport Location'),
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

            // Data Actions Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'transport-locations',
              title: 'Transport_Locations',
              onRefreshNeeded: () => ref.read(transportLocationsProvider.notifier).fetchLocations(),
              onImportExcel: () => _handleExcelImport(context, ref),
            ),

            const SizedBox(height: 16),

            // Type Filter Chips & Search Bar
            Row(
              children: [
                // Category Chips
                Wrap(
                  spacing: 8,
                  children: _locationTypes.map((type) {
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      selectedColor: AppTheme.cobalt,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.charcoal,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType = type;
                          });
                          ref.read(transportLocationsProvider.notifier).fetchLocations(
                                locationType: type,
                                search: _searchQuery,
                              );
                        }
                      },
                    );
                  }).toList(),
                ),
                const Spacer(),
                // Search Input
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by UN/LOCODE, name, city...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                ref.read(transportLocationsProvider.notifier).fetchLocations(
                                      locationType: _selectedType,
                                      search: '',
                                    );
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                      ref.read(transportLocationsProvider.notifier).fetchLocations(
                            locationType: _selectedType,
                            search: val,
                          );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Content
            Expanded(
              child: locationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cobalt)),
                error: (err, stack) => Center(
                  child: Text('Error loading locations: $err', style: const TextStyle(color: AppTheme.crimson)),
                ),
                data: (locations) {
                  if (locations.isEmpty) {
                    return const Center(
                      child: Text('No transport locations found.', style: TextStyle(color: Colors.grey, fontSize: 15)),
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
                                  : 900,
                            ),
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(110),
                                1: FlexColumnWidth(3),
                                2: FixedColumnWidth(130),
                                3: FlexColumnWidth(2),
                                4: FlexColumnWidth(2),
                                5: FixedColumnWidth(85),
                                6: FixedColumnWidth(150),
                              },
                              children: [
                                // Table Header
                                TableRow(
                                  decoration: const BoxDecoration(color: AppTheme.charcoal),
                                  children: [
                                    'UN/LOCODE',
                                    'Location Name',
                                    'Type',
                                    'Country',
                                    'City',
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
                                ...locations.asMap().entries.map((entry) {
                                  final loc = entry.value;
                                  final isEven = entry.key % 2 == 0;
                                  final isActive = loc.isActive;

                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color: isEven ? Colors.white : Colors.grey.shade50,
                                    ),
                                    children: [
                                      // UN/LOCODE
                                      _cell(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.cobalt.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            loc.unLocode,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: AppTheme.cobalt,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Location Name & Notes
                                      _cell(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              loc.locationName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isActive ? AppTheme.charcoal : Colors.grey.shade700,
                                                decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                              ),
                                            ),
                                            if (loc.notes != null && loc.notes!.isNotEmpty)
                                              Text(
                                                loc.notes!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Type Badge
                                      _cell(
                                        child: _typeBadge(loc.locationType),
                                      ),

                                      // Country
                                      _cell(
                                        child: Text(
                                          loc.country,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ),

                                      // City
                                      _cell(
                                        child: Text(
                                          loc.city,
                                          style: const TextStyle(fontSize: 13, color: Colors.black87),
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

                                      // Actions: View (Details), Edit, Print, Delete
                                      _cell(
                                        child: RowActionsPill(
                                          onView: () => _showLocationDialog(context, location: loc),
                                          onEdit: () => _showLocationDialog(context, location: loc),
                                          onPrint: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('طباعة بيانات المنفذ/الميناء: ${loc.locationName} (${loc.unLocode})'),
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
                                                    ? 'هل أنت متأكد من رغبتك في إيقاف تفعيل الميناء/المنفذ (${loc.locationName})؟'
                                                    : 'هل أنت متأكد من إعادة تفعيل الميناء/المنفذ (${loc.locationName})؟'),
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
                                            if (confirm == true && loc.locationId != null) {
                                              ref.read(transportLocationsProvider.notifier).toggleActive(loc.locationId!, isActive);
                                            }
                                          },
                                          deleteTooltip: isActive ? 'إيقاف تفعيل المنفذ (Deactivate)' : 'إعادة تفعيل المنفذ (Activate)',
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

  Widget _typeBadge(String type) {
    Color bg;
    Color fg;
    IconData icon;

    switch (type) {
      case 'Sea Port':
        bg = AppTheme.cobalt.withOpacity(0.1);
        fg = AppTheme.cobalt;
        icon = Icons.directions_boat;
        break;
      case 'Airport':
        bg = AppTheme.orange.withOpacity(0.1);
        fg = AppTheme.orange;
        icon = Icons.flight;
        break;
      case 'Dry Port':
        bg = Colors.purple.withOpacity(0.1);
        fg = Colors.purple;
        icon = Icons.warehouse;
        break;
      case 'Land Border':
        bg = AppTheme.emerald.withOpacity(0.1);
        fg = AppTheme.emerald;
        icon = Icons.border_outer;
        break;
      default:
        bg = Colors.grey.withOpacity(0.1);
        fg = Colors.grey.shade700;
        icon = Icons.place;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _cell({required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );

  void _showLocationDialog(BuildContext context, {TransportLocationModel? location}) {
    final formKey = GlobalKey<FormState>();
    final locodeCtrl = TextEditingController(text: location?.unLocode ?? '');
    final nameCtrl = TextEditingController(text: location?.locationName ?? '');
    String selectedType = location?.locationType ?? 'Sea Port';
    final countryCtrl = TextEditingController(text: location?.country ?? '');
    final cityCtrl = TextEditingController(text: location?.city ?? '');
    final notesCtrl = TextEditingController(text: location?.notes ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(location == null ? 'Add Transport Location' : 'Edit Location (${location.unLocode})'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: locodeCtrl,
                          enabled: location == null,
                          decoration: const InputDecoration(
                            labelText: 'UN/LOCODE *',
                            hintText: 'e.g. EGALY, EGCAI',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SearchableDropdownField<String>(
                          value: selectedType,
                          labelText: 'Location Type *',
                          items: ['Sea Port', 'Airport', 'Dry Port', 'Land Border', 'ICD', 'Rail Terminal']
                              .map((t) => SearchableDropdownItem<String>(value: t, label: t))
                              .toList(),
                          onChanged: (v) => selectedType = v ?? 'Sea Port',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Location Name *',
                      hintText: 'e.g. Alexandria Port',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: countryCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Country *',
                            hintText: 'e.g. Egypt',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            hintText: 'e.g. Alexandria',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Details',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cobalt, foregroundColor: Colors.white),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (location == null) {
                  final newModel = TransportLocationModel(
                    unLocode: locodeCtrl.text.trim().toUpperCase(),
                    locationName: nameCtrl.text.trim(),
                    locationType: selectedType,
                    country: countryCtrl.text.trim(),
                    city: cityCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                  final ok = await ref.read(transportLocationsProvider.notifier).createLocation(newModel);
                  if (ok && context.mounted) Navigator.pop(dialogCtx);
                } else {
                  final updateData = {
                    'location_name': nameCtrl.text.trim(),
                    'location_type': selectedType,
                    'country': countryCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                    'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  };
                  final ok = await ref
                      .read(transportLocationsProvider.notifier)
                      .updateLocation(location.locationId!, updateData);
                  if (ok && context.mounted) Navigator.pop(dialogCtx);
                }
              }
            },
            child: Text(location == null ? 'Create Location' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExcelImport(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Importing transport locations from Excel/CSV...'), backgroundColor: AppTheme.cobalt),
    );

    try {
      final res = await ref.read(transportLocationsProvider.notifier).uploadExcelLocations(file.bytes!, file.name);
      if (!context.mounted) return;
      final errors = (res?['errors'] as List?)?.cast<String>() ?? [];
      if (errors.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Warnings'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: errors.map((e) => Text('• $e', style: const TextStyle(color: AppTheme.crimson, fontSize: 13))).toList(),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res?['message'] ?? 'Successfully imported transport locations!'), backgroundColor: AppTheme.emerald),
        );
      }
    } catch (err) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString()), backgroundColor: AppTheme.crimson),
      );
    }
  }
}
