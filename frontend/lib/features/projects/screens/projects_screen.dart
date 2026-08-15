import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Widget build(BuildContext context) {
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Projects (المشاريع)',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Starting reference for multi-shipment and multi-company import operations',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
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
                      label: const Text('Create New Project'),
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
                      label: Text(st),
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
                      hintText: 'Search project code, name, owner...',
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
                          ref.read(projectsProvider.notifier).fetchProjects(status: _selectedStatus, search: _searchQuery);
                        },
                      ),
                    ],
                  ),
                ),
                data: (projects) {
                  if (projects.isEmpty) {
                    return const Center(
                      child: Text('No projects found.', style: TextStyle(color: Colors.grey, fontSize: 15)),
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
                                6: FixedColumnWidth(85),
                                7: FixedColumnWidth(140),
                              },
                              children: [
                                // Header
                                TableRow(
                                  decoration: const BoxDecoration(color: AppTheme.charcoal),
                                  children: [
                                    'Project Code',
                                    'Project Name & Owner',
                                    'Import Company & Supplier',
                                    'Type & Category',
                                    'Budget (USD)',
                                    'Capabilities',
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

                                // Data Rows
                                ...projects.asMap().entries.map((entry) {
                                  final p = entry.value;
                                  final isEven = entry.key % 2 == 0;
                                  final isActive = p.isActive;

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
                                              'Owner: ${p.projectOwner}',
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
                                              p.companyName ?? 'Company #${p.companyId}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Supplier: ${p.supplierName ?? '#${p.supplierId}'}',
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
                                              p.importType,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${p.shipmentCategory} (${p.incotermCode ?? "Incoterm"})',
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
                                              _capBadge('Multi-Shipment', AppTheme.cobalt),
                                            if (p.allowMultiCompany) ...[
                                              const SizedBox(height: 3),
                                              _capBadge('Multi-Company', AppTheme.orange),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Status
                                      _cell(
                                        child: _statusBadge(p.status),
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
                                                content: Text('طباعة بيانات المشروع ومراكز التكلفة: ${p.projectName} (${p.projectCode})'),
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
                                                    ? 'هل أنت متأكد من رغبتك في إيقاف تفعيل المشروع (${p.projectName})؟'
                                                    : 'هل أنت متأكد من إعادة تفعيل المشروع (${p.projectName})؟'),
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
                                            if (confirm == true && p.projectId != null) {
                                              ref.read(projectsProvider.notifier).toggleActive(p.projectId!, isActive);
                                            }
                                          },
                                          deleteTooltip: isActive ? 'إيقاف تفعيل المشروع (Deactivate)' : 'إعادة تفعيل المشروع (Activate)',
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

  Widget _statusBadge(String status) {
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
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _cell({required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );

  void _showProjectDialog(BuildContext context, {ProjectModel? project}) {
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
        const SnackBar(content: Text('Please ensure Import Companies, Suppliers and Incoterms are seeded first.')),
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
          title: Text(project == null ? 'Create New Import Project' : 'Edit Project (${project.projectCode})'),
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
                      decoration: const InputDecoration(
                        labelText: 'Project Name *',
                        hintText: 'e.g. Sokhna Solar Power Expansion Phase 1',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ownerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Project Owner / Manager *',
                        hintText: 'e.g. Eng. Hassan Mahmoud',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Multi-Select Importing Companies
                    const Text(
                      'Importing Companies (الشركات المستوردة للمشروع) *',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
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
                            labelText: 'Primary Supplier *',
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
                            labelText: 'Default Incoterm *',
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
                            labelText: 'Import Type *',
                            items: [
                              'Direct Commercial',
                              'Free Zone',
                              'Temporary Release / السماح المؤقت',
                              'Drawback',
                              'Project Equipment / معدات مشروعات'
                            ].map((t) => SearchableDropdownItem<String>(value: t, label: t)).toList(),
                            onChanged: (v) => setDialogState(() => selectedImportType = v ?? 'Direct Commercial'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SearchableDropdownField<String>(
                            value: selectedPriority,
                            labelText: 'Priority *',
                            items: ['Low', 'Medium', 'High', 'Urgent / حرج']
                                .map((p) => SearchableDropdownItem<String>(value: p, label: p))
                                .toList(),
                            onChanged: (v) => setDialogState(() => selectedPriority = v ?? 'Medium'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SearchableDropdownField<String>(
                      value: selectedStatus,
                      labelText: 'Project Status *',
                      items: ['Open', 'Closed', 'On Hold']
                          .map((s) => SearchableDropdownItem<String>(value: s, label: s))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedStatus = v ?? 'Open'),
                    ),
                    const SizedBox(height: 14),

                    // Multi-Select Shipment Categories
                    const Text(
                      'Allowed Shipment Categories (أنواع الشحنات المتاحة للمشروع) *',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
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
                            label: Text(cat),
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
                      decoration: const InputDecoration(
                        labelText: 'Est. Total Budget (USD)',
                        hintText: 'e.g. 500000',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Capabilities Checkboxes (Multi-Shipment & Multi-Company)
                    CheckboxListTile(
                      title: const Text('Allow Multi-Shipment (الشحن على أكثر من شحنة)'),
                      subtitle: const Text('يسمح بتوزيع توريد مشروع على عدة شحنات ورسائل جمركية متتابعة'),
                      value: allowMultiShipment,
                      activeColor: AppTheme.cobalt,
                      onChanged: (val) => setDialogState(() => allowMultiShipment = val ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Allow Multi-Company (الربط مع أكثر من شركة أو خط شحن)'),
                      subtitle: const Text('يسمح بالتعامل مع عدة مخلصين، خطوط ملاحية وموردين فرعيين للمشروع'),
                      value: allowMultiCompany,
                      activeColor: AppTheme.cobalt,
                      onChanged: (val) => setDialogState(() => allowMultiCompany = val ?? true),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Project Notes & Description'),
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
                  if (selectedCompanyIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one importing company.')),
                    );
                    return;
                  }
                  if (selectedCategories.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one shipment category.')),
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
              child: Text(project == null ? 'Create Project' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
