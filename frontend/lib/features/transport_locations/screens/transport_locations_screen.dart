import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
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
  int _currentPage = 1;
  int _pageSize = 50;

  final List<String> _locationTypes = ['All', 'Sea Port', 'Airport', 'Dry Port', 'Land Border'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transportLocationsProvider.notifier).fetchLocations();
    });
  }

  String _getLocationTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'All':
        return l10n.locationTypeAll;
      case 'Sea Port':
        return l10n.locationTypeSeaPort;
      case 'Airport':
        return l10n.locationTypeAirport;
      case 'Dry Port':
        return l10n.locationTypeDryPort;
      case 'Land Border':
        return l10n.locationTypeLandBorder;
      case 'ICD':
        return l10n.locationTypeIcd;
      case 'Rail Terminal':
        return l10n.locationTypeRailTerminal;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.transportLocationsScreenTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.transportLocationsScreenSubtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
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
                      label: Text(l10n.addTransportLocationBtn),
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
                      label: Text(_getLocationTypeLabel(type, l10n)),
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
                            _currentPage = 1;
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
                      hintText: l10n.searchTransportLocationsHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _currentPage = 1;
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
                        _currentPage = 1;
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
                  child: Text(l10n.locationsFetchError(err.toString()), style: const TextStyle(color: AppTheme.crimson)),
                ),
                data: (locations) {
                  if (locations.isEmpty) {
                    return Center(
                      child: Text(l10n.noTransportLocationsFound, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                    );
                  }

                  final totalItems = locations.length;
                  final totalPages = (totalItems / _pageSize).ceil();
                  final safeCurrentPage = _currentPage > totalPages && totalPages > 0 ? totalPages : _currentPage;
                  final startIndex = (safeCurrentPage - 1) * _pageSize;
                  final endIndex = (startIndex + _pageSize < totalItems) ? startIndex + _pageSize : totalItems;
                  final pagedLocations = totalItems > 0 && startIndex < totalItems
                      ? locations.sublist(startIndex, endIndex)
                      : <TransportLocationModel>[];

                  return Column(
                    children: [
                      Expanded(
                        child: Container(
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
                                    l10n.unLocodeCol,
                                    l10n.locationNameCol,
                                    l10n.locationTypeCol,
                                    l10n.countryCol,
                                    l10n.cityCol,
                                    l10n.statusCol,
                                    l10n.actionsCol,
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
                                ...pagedLocations.asMap().entries.map((entry) {
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
                                        child: _typeBadge(loc.locationType, l10n),
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
                                            isActive ? l10n.statusActive : l10n.statusInactive,
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
                                                content: Text(l10n.printLocationSnack(loc.locationName, loc.unLocode)),
                                                backgroundColor: AppTheme.charcoal,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          onDelete: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: Text(l10n.confirmActionTitle),
                                                content: Text(isActive
                                                    ? l10n.confirmDeactivateLocation(loc.locationName)
                                                    : l10n.confirmActivateLocation(loc.locationName)),
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
                                            if (confirm == true && loc.locationId != null) {
                                              ref.read(transportLocationsProvider.notifier).toggleActive(loc.locationId!, isActive);
                                            }
                                          },
                                          deleteTooltip: isActive ? l10n.deactivateLocationTooltip : l10n.activateLocationTooltip,
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
                  ),
                ),
                const SizedBox(height: 10),
                  // Pagination Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.showingLocationsCount(totalItems == 0 ? 0 : startIndex + 1, endIndex, totalItems, _getLocationTypeLabel(_selectedType, l10n)),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                        Row(
                          children: [
                            Text(l10n.rowsPerPageLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            DropdownButton<int>(
                              value: _pageSize,
                              underline: const SizedBox(),
                              isDense: true,
                              items: [25, 50, 100, 200]
                                  .map((s) => DropdownMenuItem(value: s, child: Text('$s', style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _pageSize = val;
                                    _currentPage = 1;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.first_page, size: 20),
                              onPressed: safeCurrentPage > 1 ? () => setState(() => _currentPage = 1) : null,
                              tooltip: l10n.firstPageTooltip,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: safeCurrentPage > 1 ? () => setState(() => _currentPage = safeCurrentPage - 1) : null,
                              tooltip: l10n.previousPageTooltip,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                l10n.pageOfTotal(safeCurrentPage, totalPages == 0 ? 1 : totalPages),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              onPressed: safeCurrentPage < totalPages ? () => setState(() => _currentPage = safeCurrentPage + 1) : null,
                              tooltip: l10n.nextPageTooltip,
                            ),
                            IconButton(
                              icon: const Icon(Icons.last_page, size: 20),
                              onPressed: safeCurrentPage < totalPages ? () => setState(() => _currentPage = totalPages) : null,
                              tooltip: l10n.lastPageTooltip,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String type, AppLocalizations l10n) {
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
            _getLocationTypeLabel(type, l10n),
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
    final l10n = context.l10n;
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
        title: Text(location == null ? l10n.addLocationDialogTitle : l10n.editLocationDialogTitle(location.unLocode)),
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
                          decoration: InputDecoration(
                            labelText: l10n.unLocodeLabel,
                            hintText: l10n.unLocodeHint,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SearchableDropdownField<String>(
                          value: selectedType,
                          labelText: l10n.locationTypeLabel,
                          items: ['Sea Port', 'Airport', 'Dry Port', 'Land Border', 'ICD', 'Rail Terminal']
                              .map((t) => SearchableDropdownItem<String>(value: t, label: _getLocationTypeLabel(t, l10n)))
                              .toList(),
                          onChanged: (v) => selectedType = v ?? 'Sea Port',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.locationNameLabel,
                      hintText: l10n.locationNameHint,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: countryCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.countryLabelRequired,
                            hintText: l10n.countryHint,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: cityCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.cityLabelRequired,
                            hintText: l10n.cityHint,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.locationNotesLabel,
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
            child: Text(l10n.cancel),
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
            child: Text(location == null ? l10n.createLocationSubmitBtn : l10n.saveChangesSubmitBtn),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExcelImport(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
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
      SnackBar(content: Text(l10n.importingLocationsDataset), backgroundColor: AppTheme.cobalt),
    );

    try {
      final res = await ref.read(transportLocationsProvider.notifier).uploadExcelLocations(file.bytes!, file.name);
      if (!context.mounted) return;
      final errors = (res?['errors'] as List?)?.cast<String>() ?? [];
      if (errors.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.importWarningsTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: errors.map((e) => Text('• $e', style: const TextStyle(color: AppTheme.crimson, fontSize: 13))).toList(),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok))],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res?['message'] ?? l10n.locationsImportSuccess), backgroundColor: AppTheme.emerald),
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
