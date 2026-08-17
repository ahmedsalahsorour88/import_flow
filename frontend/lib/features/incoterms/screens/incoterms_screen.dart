import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../models/incoterm_model.dart';
import '../providers/incoterms_provider.dart';

class IncotermsScreen extends ConsumerStatefulWidget {
  const IncotermsScreen({super.key});

  @override
  ConsumerState<IncotermsScreen> createState() => _IncotermsScreenState();
}

class _IncotermsScreenState extends ConsumerState<IncotermsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Live reload on mount
    Future.microtask(() {
      ref.read(incotermsProvider.notifier).fetchIncoterms();
      ref.read(costItemsProvider.notifier).fetchCostItems();
      ref.read(responsibilityMatrixProvider.notifier).fetchAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incoterms Rules',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Incoterms 2020 · Cost Items · Responsibility Matrix',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                BackToDashboardButton(),
              ],
            ),

            const SizedBox(height: 16),

            // Data Actions Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'incoterms',
              title: 'Incoterms_Master',
              onRefreshNeeded: () {
                ref.read(incotermsProvider.notifier).fetchIncoterms();
                ref.read(costItemsProvider.notifier).fetchCostItems();
              },
            ),

            const SizedBox(height: 16),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.cobalt,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.cobalt,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.handshake_outlined), text: 'Incoterms'),
                  Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Cost Items'),
                  Tab(icon: Icon(Icons.table_chart_outlined), text: 'Responsibility Matrix'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar (shown for Incoterms and Cost Items tabs)
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 2) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              })
                          : null,
                    ),
                  ),
                );
              },
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _IncotermsTab(searchQuery: _searchQuery),
                  _CostItemsTab(searchQuery: _searchQuery),
                  const _ResponsibilityMatrixTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// Tab 1: Incoterms List
// ==================================================

class _IncotermsTab extends ConsumerWidget {
  final String searchQuery;
  const _IncotermsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incotermsAsync = ref.watch(incotermsProvider);
    final showInactive = ref.watch(showInactiveIncotermsProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Show Inactive', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Switch(
                  value: showInactive,
                  activeColor: AppTheme.cobalt,
                  onChanged: (val) {
                    ref.read(showInactiveIncotermsProvider.notifier).state = val;
                  },
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Incoterm'),
              onPressed: () => _showIncotermDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: incotermsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppTheme.cobalt)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (incoterms) {
              final filtered = searchQuery.isEmpty
                  ? incoterms
                  : incoterms
                      .where((i) =>
                          i.incotermCode.toLowerCase().contains(searchQuery) ||
                          i.incotermName.toLowerCase().contains(searchQuery))
                      .toList();
              if (filtered.isEmpty) {
                return const Center(
                    child: Text('No incoterms found.',
                        style: TextStyle(color: Colors.grey)));
              }
              return _buildIncotermTable(context, ref, filtered);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncotermTable(
      BuildContext context, WidgetRef ref, List<IncotermModel> incoterms) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                    : 950,
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(100),
                  1: FlexColumnWidth(2),
                  2: FixedColumnWidth(120),
                  3: FixedColumnWidth(85),
                  4: FixedColumnWidth(150),
                },
                children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.charcoal),
                children: ['Code', 'Name', 'Version', 'Status', 'Actions']
                    .map((h) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(h,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ))
                    .toList(),
              ),
              ...incoterms.asMap().entries.map((entry) {
                final i = entry.value;
                final isEven = entry.key % 2 == 0;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven ? Colors.white : Colors.grey.shade50,
                  ),
                  children: [
                    _cell(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.cobalt.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(i.incotermCode,
                            style: const TextStyle(
                                color: AppTheme.cobalt,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ),
                    _cell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.incotermName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.charcoal)),
                          if (i.description != null)
                            Text(i.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    _cell(
                        child: Text(i.version,
                            style: const TextStyle(fontSize: 13))),
                    _cell(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: i.isActive
                              ? AppTheme.emerald.withOpacity(0.1)
                              : AppTheme.crimson.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          i.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color:
                                i.isActive ? AppTheme.emerald : AppTheme.crimson,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    _cell(
                      child: RowActionsPill(
                        onView: () => _showIncotermDialog(context, ref, incoterm: i),
                        onEdit: () => _showIncotermDialog(context, ref, incoterm: i),
                        onPrint: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('طباعة بيانات شرط التجارة الدولي: ${i.incotermCode} (${i.incotermName})'),
                              backgroundColor: AppTheme.charcoal,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        onDelete: () async {
                          final isActive = i.isActive;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الإجراء'),
                              content: Text(isActive
                                  ? 'هل أنت متأكد من رغبتك في إيقاف تفعيل شرط التجارة (${i.incotermCode})؟'
                                  : 'هل أنت متأكد من إعادة تفعيل شرط التجارة (${i.incotermCode})؟'),
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
                          if (confirm == true) {
                            await ref.read(incotermsProvider.notifier).toggleActive(i.incotermId, i.isActive);
                          }
                        },
                        deleteTooltip: i.isActive ? 'إيقاف تفعيل الشرط (Deactivate)' : 'إعادة تفعيل الشرط (Activate)',
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
}

  void _showIncotermDialog(BuildContext context, WidgetRef ref,
      {IncotermModel? incoterm}) {
    final codeCtrl =
        TextEditingController(text: incoterm?.incotermCode ?? '');
    final nameCtrl =
        TextEditingController(text: incoterm?.incotermName ?? '');
    final versionCtrl =
        TextEditingController(text: incoterm?.version ?? 'Incoterms 2020');
    final descCtrl =
        TextEditingController(text: incoterm?.description ?? '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(incoterm == null ? 'Add Incoterm' : 'Edit Incoterm'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Incoterm Code *'),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: versionCtrl,
                    decoration: const InputDecoration(labelText: 'Version'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);
                      final data = {
                        'incoterm_code': codeCtrl.text.trim().toUpperCase(),
                        'incoterm_name': nameCtrl.text.trim(),
                        'version': versionCtrl.text.trim(),
                        'description': descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                      };
                      String? error;
                      if (incoterm == null) {
                        error = await ref
                            .read(incotermsProvider.notifier)
                            .createIncoterm(data);
                      } else {
                        error = await ref
                            .read(incotermsProvider.notifier)
                            .updateIncoterm(incoterm.incotermId, data);
                      }
                      setDialogState(() => isLoading = false);
                      if (ctx.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(error),
                                  backgroundColor: AppTheme.crimson));
                        } else {
                          Navigator.pop(ctx);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(incoterm == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell({required Widget child}) => TableRowInkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      );
}

// ==================================================
// Tab 2: Cost Items
// ==================================================

class _CostItemsTab extends ConsumerWidget {
  final String searchQuery;
  const _CostItemsTab({required this.searchQuery});

  static const List<String> _categories = [
    'Freight', 'Customs', 'Port', 'Bank', 'Other'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final costItemsAsync = ref.watch(costItemsProvider);
    final showInactive = ref.watch(showInactiveCostItemsProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Show Inactive', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Switch(
                  value: showInactive,
                  activeColor: AppTheme.cobalt,
                  onChanged: (val) {
                    ref.read(showInactiveCostItemsProvider.notifier).state = val;
                  },
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Cost Item'),
              onPressed: () => _showCostItemDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: costItemsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.cobalt)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              final filtered = searchQuery.isEmpty
                  ? items
                  : items
                      .where((i) =>
                          i.costItemCode.toLowerCase().contains(searchQuery) ||
                          i.costItemName.toLowerCase().contains(searchQuery) ||
                          i.costCategory.toLowerCase().contains(searchQuery))
                      .toList();
              if (filtered.isEmpty) {
                return const Center(
                    child: Text('No cost items found.',
                        style: TextStyle(color: Colors.grey)));
              }
              return _buildCostItemTable(context, ref, filtered);
            },
          ),
        ),
      ],
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Freight':
        return AppTheme.cobalt;
      case 'Customs':
        return AppTheme.orange;
      case 'Port':
        return const Color(0xFF8E44AD);
      case 'Bank':
        return AppTheme.emerald;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCostItemTable(
      BuildContext context, WidgetRef ref, List<CostItemModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                    : 950,
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(100),
                  1: FlexColumnWidth(2),
                  2: FixedColumnWidth(110),
                  3: FixedColumnWidth(85),
                  4: FixedColumnWidth(150),
                },
                children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.charcoal),
                children: ['Code', 'Name', 'Category', 'Status', 'Actions']
                    .map((h) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(h,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ))
                    .toList(),
              ),
              ...items.asMap().entries.map((entry) {
                final item = entry.value;
                final isEven = entry.key % 2 == 0;
                final catColor = _categoryColor(item.costCategory);
                return TableRow(
                  decoration: BoxDecoration(
                      color: isEven ? Colors.white : Colors.grey.shade50),
                  children: [
                    _cell(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.costItemCode,
                            style: TextStyle(
                                color: catColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ),
                    _cell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.costItemName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.charcoal)),
                          if (item.description != null)
                            Text(item.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    _cell(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(item.costCategory,
                            style: TextStyle(
                                color: catColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                    ),
                    _cell(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isActive
                              ? AppTheme.emerald.withOpacity(0.1)
                              : AppTheme.crimson.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: item.isActive
                                ? AppTheme.emerald
                                : AppTheme.crimson,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    _cell(
                      child: RowActionsPill(
                        onView: () => _showCostItemDialog(context, ref, item: item),
                        onEdit: () => _showCostItemDialog(context, ref, item: item),
                        onPrint: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('طباعة بيانات بند التكلفة: ${item.costItemCode} (${item.costItemName})'),
                              backgroundColor: AppTheme.charcoal,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        onDelete: () async {
                          final isActive = item.isActive;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الإجراء'),
                              content: Text(isActive
                                  ? 'هل أنت متأكد من رغبتك في إيقاف تفعيل بند التكلفة (${item.costItemCode})؟'
                                  : 'هل أنت متأكد من إعادة تفعيل بند التكلفة (${item.costItemCode})؟'),
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
                          if (confirm == true) {
                            await ref.read(costItemsProvider.notifier).toggleActive(item.costItemId, item.isActive);
                          }
                        },
                        deleteTooltip: item.isActive ? 'إيقاف تفعيل بند التكلفة (Deactivate)' : 'إعادة تفعيل بند التكلفة (Activate)',
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
}

  void _showCostItemDialog(BuildContext context, WidgetRef ref,
      {CostItemModel? item}) {
    final codeCtrl = TextEditingController(text: item?.costItemCode ?? '');
    final nameCtrl = TextEditingController(text: item?.costItemName ?? '');
    String selectedCategory = item?.costCategory ?? 'Freight';
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Add Cost Item' : 'Edit Cost Item'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Cost Item Code *'),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Cost Item Name *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  SearchableDropdownField<String>(
                    value: selectedCategory,
                    labelText: 'Category *',
                    items: _categories
                        .map((c) => SearchableDropdownItem<String>(value: c, label: c))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);
                      final data = {
                        'cost_item_code': codeCtrl.text.trim().toUpperCase(),
                        'cost_item_name': nameCtrl.text.trim(),
                        'cost_category': selectedCategory,
                        'description': descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                      };
                      String? error;
                      if (item == null) {
                        error = await ref
                            .read(costItemsProvider.notifier)
                            .createCostItem(data);
                      } else {
                        error = await ref
                            .read(costItemsProvider.notifier)
                            .updateCostItem(item.costItemId, data);
                      }
                      setDialogState(() => isLoading = false);
                      if (ctx.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(error),
                              backgroundColor: AppTheme.crimson));
                        } else {
                          Navigator.pop(ctx);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(item == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell({required Widget child}) => TableRowInkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      );
}// ==================================================
// Tab 3: Responsibility Matrix
// ==================================================

class _ResponsibilityMatrixTab extends ConsumerStatefulWidget {
  const _ResponsibilityMatrixTab();

  @override
  ConsumerState<_ResponsibilityMatrixTab> createState() =>
      _ResponsibilityMatrixTabState();
}

class _ResponsibilityMatrixTabState
    extends ConsumerState<_ResponsibilityMatrixTab> {
  int? _selectedIncotermId;

  @override
  Widget build(BuildContext context) {
    final incotermsAsync = ref.watch(incotermsProvider);
    final matrixAsync = ref.watch(responsibilityMatrixProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Incoterm selector dropdown & header actions
        incotermsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (incoterms) {
            final active = incoterms.where((i) => i.isActive).toList();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Filter by Incoterm:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 280,
                      child: SearchableDropdownField<int?>(
                        value: _selectedIncotermId,
                        hintText: 'All Incoterms (11 Terms)',
                        items: [
                          const SearchableDropdownItem<int?>(
                              value: null, label: 'All Incoterms (11 Terms)'),
                          ...active.map((i) => SearchableDropdownItem<int?>(
                                value: i.incotermId,
                                label: '${i.incotermCode} - ${i.incotermName}',
                              )),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedIncotermId = val),
                      ),
                    ),
                  ],
                ),
                Text(
                  _selectedIncotermId == null
                      ? 'Showing All Matrix Responsibilities'
                      : 'Filtering responsibilities for selected term',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),

        // Matrix table
        Expanded(
          child: matrixAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.cobalt)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (matrix) {
              final filtered = _selectedIncotermId == null
                  ? matrix
                  : matrix
                      .where((r) => r.incotermId == _selectedIncotermId)
                      .toList();
              if (filtered.isEmpty) {
                return const Center(
                    child: Text('No responsibility data found.',
                        style: TextStyle(color: Colors.grey)));
              }
              return _buildMatrixTable(filtered);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatrixTable(List<IncotermResponsibilityModel> matrix) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                    : 1000,
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(100),
                  1: FlexColumnWidth(2),
                  2: FixedColumnWidth(110),
                  3: FixedColumnWidth(140),
                  4: FixedColumnWidth(100),
                  5: FlexColumnWidth(2),
                  6: FixedColumnWidth(80),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppTheme.charcoal),
                    children: [
                      'Incoterm',
                      'Cost Item',
                      'Category',
                      'Responsible (الجهة)',
                      'Included',
                      'Comment / Notes',
                      'Actions'
                    ]
                        .map((h) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Text(h,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ))
                        .toList(),
                  ),
                  ...matrix.asMap().entries.map((entry) {
                    final r = entry.value;
                    final isEven = entry.key % 2 == 0;
                    Color partyColor;
                    String partyText;
                    switch (r.responsibleParty) {
                      case 'Importer':
                        partyColor = AppTheme.cobalt;
                        partyText = 'المشتري / المستورد (YES)';
                        break;
                      case 'Exporter':
                        partyColor = AppTheme.orange;
                        partyText = 'البائع / الشاحن (NO)';
                        break;
                      default:
                        partyColor = AppTheme.emerald;
                        partyText = 'مشترك (Shared)';
                    }
                    return TableRow(
                      decoration: BoxDecoration(
                          color: isEven ? Colors.white : Colors.grey.shade50),
                      children: [
                        _cell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.cobalt.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(r.incotermCode ?? '—',
                                style: const TextStyle(
                                    color: AppTheme.cobalt,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ),
                        _cell(
                            child: Text(r.costItemName ?? '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.charcoal))),
                        _cell(
                            child: Text(r.costCategory ?? '—',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700))),
                        _cell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: partyColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(partyText,
                                style: TextStyle(
                                    color: partyColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          ),
                        ),
                        _cell(
                          child: Icon(
                            r.includedInIncoterm
                                ? Icons.check_circle
                                : Icons.remove_circle_outline,
                            color: r.includedInIncoterm
                                ? AppTheme.emerald
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                        _cell(
                          child: Text(
                            r.notes ?? '—',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                        _cell(
                          child: IconButton(
                            icon: const Icon(Icons.edit,
                                color: AppTheme.cobalt, size: 20),
                            tooltip: 'Edit Responsibility (تعديل المسؤولية)',
                            onPressed: () =>
                                _showEditResponsibilityDialog(context, ref, r),
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
  }

  void _showEditResponsibilityDialog(
      BuildContext context, WidgetRef ref, IncotermResponsibilityModel r) {
    String selectedParty = r.responsibleParty;
    bool isIncluded = r.includedInIncoterm;
    final notesCtrl = TextEditingController(text: r.notes ?? '');
    bool isLoading = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: AppTheme.cobalt),
              const SizedBox(width: 8),
              Text('Edit Responsibility · ${r.incotermCode ?? ''}'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cobalt.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppTheme.cobalt.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Incoterm: ${r.incotermCode ?? '—'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                            'Cost Item: ${r.costItemName ?? '—'} (${r.costCategory ?? '—'})',
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 12)),
                      ],
                    ),
                  ),
                  SearchableDropdownField<String>(
                    value: selectedParty,
                    labelText: 'Responsible Party (الجهة المسؤولة) *',
                    items: const [
                      SearchableDropdownItem<String>(
                          value: 'Importer',
                          label: 'المشتري / المستورد (YES)'),
                      SearchableDropdownItem<String>(
                          value: 'Exporter',
                          label: 'البائع / الشاحن (NO)'),
                      SearchableDropdownItem<String>(
                          value: 'Shared', label: 'مشترك (Shared)'),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedParty = val;
                          if (val == 'Exporter') {
                            isIncluded = true;
                          } else if (val == 'Importer') {
                            isIncluded = false;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Included in Seller Price (مدرج ضمن التكلفة)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: const Text(
                        'Does the seller cover this cost in the invoice price?',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: isIncluded,
                    activeColor: AppTheme.emerald,
                    onChanged: (val) => setDialogState(() => isIncluded = val),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Comment / Notes (تعليق أوملاحظات)',
                      hintText: 'إضافة تفاصيل أو شروط خاصة ببند التكلفة...',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      final data = {
                        'responsible_party': selectedParty,
                        'included_in_incoterm': isIncluded,
                        'notes': notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                      };

                      final error = await ref
                          .read(responsibilityMatrixProvider.notifier)
                          .updateResponsibility(r.responsibilityId, data);
                      ref.read(responsibilityMatrixProvider.notifier).fetchAll();

                      setDialogState(() => isLoading = false);
                      if (ctx.mounted) {
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(error),
                              backgroundColor: AppTheme.crimson));
                        } else {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Updated successfully'),
                                  backgroundColor: AppTheme.emerald));
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell({required Widget child}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );
}
