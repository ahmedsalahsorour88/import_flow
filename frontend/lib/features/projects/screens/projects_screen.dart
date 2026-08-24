import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../audit_logs/widgets/row_history_dialog.dart';
import '../../import_companies/providers/import_companies_provider.dart';
import '../../incoterms/providers/incoterms_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../models/project_model.dart';
import '../providers/projects_provider.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = ['All', 'Open', 'Closed', 'On Hold'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).fetchProjects();
      ref.read(importCompaniesProvider.notifier).fetchCompanies();
      ref.read(suppliersProvider.notifier).fetchSuppliers();
      ref.read(incotermsProvider.notifier).fetchIncoterms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getStatusLabel(BuildContext context, String status) {
    final l10n = context.l10n;
    switch (status) {
      case 'All':
        return l10n.statusAll;
      case 'Open':
        return l10n.statusOpen;
      case 'Closed':
        return l10n.statusClosed;
      case 'On Hold':
        return l10n.statusOnHold;
      default:
        return status;
    }
  }

  String _getImportTypeLabel(BuildContext context, String importType) {
    final l10n = context.l10n;
    if (importType.contains('Direct Commercial') || importType == 'Direct Commercial') {
      return l10n.importTypeDirectCommercial;
    }
    if (importType.contains('Free Zone') || importType == 'Free Zone') {
      return l10n.importTypeFreeZone;
    }
    if (importType.contains('Temporary Release') || importType.contains('السماح المؤقت')) {
      return l10n.importTypeTemporaryRelease;
    }
    if (importType.contains('Drawback') || importType == 'Drawback') {
      return l10n.importTypeDrawback;
    }
    if (importType.contains('Project Equipment') || importType.contains('معدات مشروعات')) {
      return l10n.importTypeProjectEquipment;
    }
    return importType;
  }

  String _getCategoryLabel(BuildContext context, String category) {
    final l10n = context.l10n;
    switch (category.trim()) {
      case 'FCL Container':
        return l10n.categoryFclContainer;
      case 'LCL Breakbulk':
        return l10n.categoryLclBreakbulk;
      case 'Air Freight':
        return l10n.categoryAirFreight;
      case 'Bulk Cargo':
        return l10n.categoryBulkCargo;
      case 'Multimodal':
        return l10n.categoryMultimodal;
      default:
        return category;
    }
  }

  String _getPriorityLabel(BuildContext context, String priority) {
    final l10n = context.l10n;
    switch (priority) {
      case 'Low':
        return l10n.priorityLow;
      case 'Medium':
        return l10n.priorityMedium;
      case 'High':
        return l10n.priorityHigh;
      case 'Urgent':
      case 'Urgent / حرج':
        return l10n.priorityUrgent;
      default:
        return priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final projectsAsync = ref.watch(projectsProvider);

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
                      l10n.projectsScreenTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.projectsScreenSubtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const BackToDashboardButton(),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showProjectDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.createNewProjectBtn),
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
              moduleEndpoint: 'projects',
              title: 'Projects_CostCenters',
              onRefreshNeeded: () => ref.refresh(projectsProvider.notifier).fetchProjects(),
            ),

            const SizedBox(height: 16),

            // Filters & Search Bar
            Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: _statuses.map((st) {
                    final isSelected = _selectedStatus == st;
                    return ChoiceChip(
                      label: Text(_getStatusLabel(context, st)),
                      selected: isSelected,
                      selectedColor: AppTheme.cobalt,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.charcoal,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = st;
                          });
                          ref.read(projectsProvider.notifier).fetchProjects(
                                status: st,
                                search: _searchQuery,
                              );
                        }
                      },
                    );
                  }).toList(),
                ),
                const Spacer(),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.projectsSearchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                ref.read(projectsProvider.notifier).fetchProjects(
                                      status: _selectedStatus,
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
                      ref.read(projectsProvider.notifier).fetchProjects(
                            status: _selectedStatus,
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
              child: projectsAsync.when(
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
                          l10n.projectsFetchError(err.toString()),
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
                        label: Text(l10n.retryConnection, style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ref.read(projectsProvider.notifier).fetchProjects(status: _selectedStatus, search: _searchQuery);
                        },
                      ),
                    ],
                  ),
                ),
                data: (projects) {
                  if (projects.isEmpty) {
                    return Center(
                      child: Text(l10n.noProjectsFound, style: const TextStyle(color: Colors.grey, fontSize: 15)),
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
                                  : 1050,
                            ),
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(120),
                                1: FlexColumnWidth(3),
                                2: FlexColumnWidth(2.5),
                                3: FlexColumnWidth(2),
                                4: FixedColumnWidth(110),
                                5: FixedColumnWidth(130),
                                6: FixedColumnWidth(95),
                                7: FixedColumnWidth(140),
                              },
                              children: [
                                // Header
                                TableRow(
                                  decoration: const BoxDecoration(color: AppTheme.charcoal),
                                  children: [
                                    l10n.projectCodeCol,
                                    l10n.projectNameAndOwnerCol,
                                    l10n.companyAndSupplierCol,
                                    l10n.typeAndCategoryCol,
                                    l10n.budgetUsdCol,
                                    l10n.capabilitiesCol,
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

                                // Data Rows
                                ...projects.asMap().entries.map((entry) {
                                  final p = entry.value;
                                  final isEven = entry.key % 2 == 0;
                                  final isActive = p.isActive;

                                  final categoriesText = p.shipmentCategory
                                      .split(',')
                                      .map((c) => _getCategoryLabel(context, c))
                                      .join(', ');

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
                                            color: AppTheme.cobalt.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            p.projectCode,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: AppTheme.cobalt,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Project Name & Owner
                                      _cell(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.projectName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isActive ? AppTheme.charcoal : Colors.grey.shade700,
                                                decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              l10n.projectOwnerLabel(p.projectOwner),
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Import Company & Supplier
                                      _cell(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.companyName ?? l10n.projectCompanyFallback(p.companyId),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              l10n.projectSupplierLabel(p.supplierName ?? '#${p.supplierId}'),
                                              style: const TextStyle(fontSize: 11, color: AppTheme.cobalt),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Type & Category
                                      _cell(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getImportTypeLabel(context, p.importType),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$categoriesText (${p.incotermCode ?? "Incoterm"})',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Budget USD
                                      _cell(
                                        child: Text(
                                          p.totalBudgetUsd != null
                                              ? '\$${p.totalBudgetUsd!.toStringAsFixed(2)}'
                                              : 'N/A',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emerald),
                                        ),
                                      ),

                                      // Capabilities Badges (Multi-Shipment / Multi-Company)
                                      _cell(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (p.allowMultiShipment)
                                              _capBadge(l10n.capMultiShipment, AppTheme.cobalt),
                                            if (p.allowMultiCompany) ...[
                                              const SizedBox(height: 3),
                                              _capBadge(l10n.capMultiCompany, AppTheme.orange),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Status
                                      _cell(
                                        child: _statusBadge(context, p.status),
                                      ),

                                      // Actions
                                      _cell(
                                        child: RowActionsPill(
                                          onView: () {
                                            if (p.projectId != null) {
                                              RowHistoryDialog.show(
                                                context,
                                                entityType: 'Project',
                                                entityId: p.projectId!,
                                                entityTitle: p.projectName,
                                              );
                                            }
                                          },
                                          onEdit: () => _showProjectDialog(context, project: p),
                                          onPrint: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(l10n.projectPrintSnack(p.projectName, p.projectCode)),
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
                                                    ? l10n.confirmDeactivateProject(p.projectName)
                                                    : l10n.confirmActivateProject(p.projectName)),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: Text(l10n.cancel),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: isActive ? AppTheme.crimson : AppTheme.emerald,
                                                    ),
                                                    child: Text(
                                                      isActive ? l10n.deactivateBtn : l10n.activateBtn,
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true && p.projectId != null) {
                                              ref.read(projectsProvider.notifier).toggleActive(p.projectId!, isActive);
                                            }
                                          },
                                          deleteTooltip: isActive ? l10n.deactivateProjectTooltip : l10n.activateProjectTooltip,
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

  Widget _capBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Open':
        bg = AppTheme.emerald.withOpacity(0.1);
        fg = AppTheme.emerald;
        break;
      case 'Closed':
        bg = Colors.grey.withOpacity(0.1);
        fg = Colors.grey.shade700;
        break;
      case 'On Hold':
        bg = AppTheme.orange.withOpacity(0.1);
        fg = AppTheme.orange;
        break;
      default:
        bg = AppTheme.cobalt.withOpacity(0.1);
        fg = AppTheme.cobalt;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        _getStatusLabel(context, status),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _cell({required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );

  void _showProjectDialog(BuildContext context, {ProjectModel? project}) {
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: project?.projectName ?? '');
    final ownerCtrl = TextEditingController(text: project?.projectOwner ?? '');
    final budgetCtrl = TextEditingController(text: project?.totalBudgetUsd?.toString() ?? '');
    final notesCtrl = TextEditingController(text: project?.notes ?? '');

    final companies = ref.read(importCompaniesProvider).value ?? [];
    final suppliers = ref.read(suppliersProvider).value ?? [];
    final incoterms = ref.read(incotermsProvider).value ?? [];

    if (companies.isEmpty || suppliers.isEmpty || incoterms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projectPrerequisitesMissing)),
      );
      return;
    }

    final Set<int> selectedCompanyIds = project != null && project.companyIds.isNotEmpty
        ? project.companyIds.toSet()
        : (companies.isNotEmpty && companies.first.companyId != null ? {companies.first.companyId!} : <int>{});

    int selectedSupplierId = project?.supplierId ?? suppliers.first.supplierId!;
    int selectedIncotermId = project?.incotermId ?? incoterms.first.incotermId;
    String selectedImportType = project?.importType ?? 'Direct Commercial';
    String selectedPriority = project?.priority ?? 'Medium';
    String selectedStatus = project?.status ?? 'Open';
    bool allowMultiShipment = project?.allowMultiShipment ?? true;
    bool allowMultiCompany = project?.allowMultiCompany ?? true;

    final List<String> availableCategories = [
      'FCL Container',
      'LCL Breakbulk',
      'Air Freight',
      'Bulk Cargo',
      'Multimodal'
    ];

    final Set<String> selectedCategories = project != null && project.shipmentCategory.isNotEmpty
        ? project.shipmentCategory.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet()
        : {'FCL Container'};

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(project == null ? l10n.createProjectDialogTitle : l10n.editProjectDialogTitle(project.projectCode)),
          content: SizedBox(
            width: 650,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.projectNameLabel,
                        hintText: l10n.projectNameHint,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ownerCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.projectOwnerLabelField,
                        hintText: l10n.projectOwnerHint,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 14),

                    // Multi-Select Importing Companies
                    Text(
                      l10n.importingCompaniesFieldLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: companies.map((c) {
                          final isSelected = c.companyId != null && selectedCompanyIds.contains(c.companyId);
                          return FilterChip(
                            label: Text(c.importerName),
                            selected: isSelected,
                            selectedColor: AppTheme.cobalt.withOpacity(0.2),
                            checkmarkColor: AppTheme.cobalt,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.cobalt : AppTheme.charcoal,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (bool selected) {
                              if (c.companyId == null) return;
                              setDialogState(() {
                                if (selected) {
                                  selectedCompanyIds.add(c.companyId!);
                                } else {
                                  if (selectedCompanyIds.length > 1) {
                                    selectedCompanyIds.remove(c.companyId);
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Supplier & Incoterm
                    Row(
                      children: [
                        Expanded(
                          child: SearchableDropdownField<int?>(
                            value: selectedSupplierId,
                            labelText: l10n.primarySupplierLabel,
                            items: suppliers
                                .map((s) => SearchableDropdownItem<int?>(
                                      value: s.supplierId,
                                      label: s.companyName,
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedSupplierId = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SearchableDropdownField<int?>(
                            value: selectedIncotermId,
                            labelText: l10n.defaultIncotermLabel,
                            items: incoterms
                                .map((i) => SearchableDropdownItem<int?>(
                                      value: i.incotermId,
                                      label: '${i.incotermCode} (${i.incotermName})',
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedIncotermId = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: SearchableDropdownField<String>(
                            value: selectedImportType,
                            labelText: l10n.importTypeLabel,
                            items: [
                              'Direct Commercial',
                              'Free Zone',
                              'Temporary Release',
                              'Drawback',
                              'Project Equipment'
                            ].map((t) => SearchableDropdownItem<String>(
                                  value: t,
                                  label: _getImportTypeLabel(context, t),
                                )).toList(),
                            onChanged: (v) => setDialogState(() => selectedImportType = v ?? 'Direct Commercial'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SearchableDropdownField<String>(
                            value: selectedPriority,
                            labelText: l10n.priorityLabel,
                            items: ['Low', 'Medium', 'High', 'Urgent']
                                .map((p) => SearchableDropdownItem<String>(
                                      value: p,
                                      label: _getPriorityLabel(context, p),
                                    ))
                                .toList(),
                            onChanged: (v) => setDialogState(() => selectedPriority = v ?? 'Medium'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SearchableDropdownField<String>(
                      value: selectedStatus,
                      labelText: l10n.projectStatusLabel,
                      items: ['Open', 'Closed', 'On Hold']
                          .map((s) => SearchableDropdownItem<String>(
                                value: s,
                                label: _getStatusLabel(context, s),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedStatus = v ?? 'Open'),
                    ),
                    const SizedBox(height: 14),

                    // Multi-Select Shipment Categories
                    Text(
                      l10n.allowedShipmentCategoriesLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: availableCategories.map((cat) {
                          final isSelected = selectedCategories.contains(cat);
                          return FilterChip(
                            label: Text(_getCategoryLabel(context, cat)),
                            selected: isSelected,
                            selectedColor: AppTheme.cobalt.withOpacity(0.2),
                            checkmarkColor: AppTheme.cobalt,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.cobalt : AppTheme.charcoal,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
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
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: budgetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.estTotalBudgetUsdLabel,
                        hintText: l10n.estTotalBudgetUsdHint,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Capabilities Checkboxes (Multi-Shipment & Multi-Company)
                    CheckboxListTile(
                      title: Text(l10n.allowMultiShipmentTitle),
                      subtitle: Text(l10n.allowMultiShipmentSubtitle),
                      value: allowMultiShipment,
                      activeColor: AppTheme.cobalt,
                      onChanged: (val) => setDialogState(() => allowMultiShipment = val ?? true),
                    ),
                    CheckboxListTile(
                      title: Text(l10n.allowMultiCompanyTitle),
                      subtitle: Text(l10n.allowMultiCompanySubtitle),
                      value: allowMultiCompany,
                      activeColor: AppTheme.cobalt,
                      onChanged: (val) => setDialogState(() => allowMultiCompany = val ?? true),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: l10n.projectNotesLabel),
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
                  if (selectedCompanyIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.selectAtLeastOneCompanyError)),
                    );
                    return;
                  }
                  if (selectedCategories.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.selectAtLeastOneCategoryError)),
                    );
                    return;
                  }

                  final budget = double.tryParse(budgetCtrl.text.trim());
                  final categoryString = selectedCategories.join(', ');
                  final companyIdsList = selectedCompanyIds.toList();

                  if (project == null) {
                    final newModel = ProjectModel(
                      projectCode: '',
                      projectName: nameCtrl.text.trim(),
                      projectOwner: ownerCtrl.text.trim(),
                      companyId: companyIdsList.first,
                      companyIds: companyIdsList,
                      supplierId: selectedSupplierId,
                      incotermId: selectedIncotermId,
                      importType: selectedImportType,
                      priority: selectedPriority,
                      shipmentCategory: categoryString,
                      allowMultiShipment: allowMultiShipment,
                      allowMultiCompany: allowMultiCompany,
                      totalBudgetUsd: budget,
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    );
                    final ok = await ref.read(projectsProvider.notifier).createProject(newModel);
                    if (ok && context.mounted) Navigator.pop(dialogCtx);
                  } else {
                    final updateData = {
                      'project_name': nameCtrl.text.trim(),
                      'project_owner': ownerCtrl.text.trim(),
                      'company_id': companyIdsList.first,
                      'company_ids': companyIdsList,
                      'supplier_id': selectedSupplierId,
                      'incoterm_id': selectedIncotermId,
                      'import_type': selectedImportType,
                      'priority': selectedPriority,
                      'shipment_category': categoryString,
                      'allow_multi_shipment': allowMultiShipment,
                      'allow_multi_company': allowMultiCompany,
                      'total_budget_usd': budget,
                      'status': selectedStatus,
                      'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    };
                    final ok = await ref
                        .read(projectsProvider.notifier)
                        .updateProject(project.projectId!, updateData);
                    if (ok && context.mounted) Navigator.pop(dialogCtx);
                  }
                }
              },
              child: Text(project == null ? l10n.createProjectSubmitBtn : l10n.saveChangesSubmitBtn),
            ),
          ],
        ),
      ),
    );
  }
}
