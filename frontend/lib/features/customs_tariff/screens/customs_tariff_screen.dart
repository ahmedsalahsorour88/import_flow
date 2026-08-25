import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../models/customs_tariff_model.dart';
import '../providers/customs_tariff_provider.dart';
import '../widgets/duty_calculator_dialog.dart';
import '../widgets/nafeza_details_dialog.dart';
import '../widgets/tariff_form_dialog.dart';
import 'hs_code_search_screen.dart';

class CustomsTariffScreen extends ConsumerStatefulWidget {
  const CustomsTariffScreen({super.key});

  @override
  ConsumerState<CustomsTariffScreen> createState() =>
      _CustomsTariffScreenState();
}

class _CustomsTariffScreenState extends ConsumerState<CustomsTariffScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customsTariffProvider.notifier).fetchTariffs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tariffsAsync = ref.watch(customsTariffProvider);
    final showInactive = ref.watch(showInactiveCustomsTariffsProvider);

    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.customsTariffScreenTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.customsTariffScreenSubtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    const BackToDashboardButton(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: Text(l10n.importExcelCsvBtn),
                      onPressed: () => _handleExcelImport(context, ref),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.charcoal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.saved_search, size: 18, color: Colors.amber),
                      label: Text(
                        l10n.hsExplorerBtn,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HsCodeSearchScreen(
                              initialQuery: _searchController.text,
                            ),
                          ),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: Text(l10n.smartNafezaDiffEngineBtn),
                      onPressed: () => showTariffDialog(context, ref, initialModeIndex: 0),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.calculate, size: 18),
                      label: Text(l10n.dutyCalculatorBtn),
                      onPressed: () => showDutyCalculatorDialog(context, ref),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addTariffManualBtn),
                      onPressed: () => showTariffDialog(context, ref, initialModeIndex: 1),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data Actions Toolbar
            MasterDataToolbarWidget(
              moduleEndpoint: 'customs-tariff',
              title: 'Customs_Tariffs',
              onRefreshNeeded: () => ref.read(customsTariffProvider.notifier).fetchTariffs(),
            ),

            const SizedBox(height: 16),

            // Search & Filter Toolbar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref
                          .read(customsTariffSearchQueryProvider.notifier)
                          .state = val.trim();
                    },
                    decoration: InputDecoration(
                      hintText: l10n.searchTariffsHint,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(customsTariffSearchQueryProvider
                                        .notifier)
                                    .state = '';
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Text(
                      l10n.showInactiveTariffsLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: showInactive,
                      activeColor: AppTheme.cobalt,
                      onChanged: (val) {
                        ref
                            .read(showInactiveCustomsTariffsProvider.notifier)
                            .state = val;
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Area
            Expanded(
              child: tariffsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.cobalt),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tariffs) {
                  final query = _searchController.text.trim().toLowerCase().replaceAll('.', '');
                  final filteredTariffs = query.isEmpty
                      ? tariffs
                      : tariffs.where((t) {
                          final hsClean = t.hsCode.toLowerCase().replaceAll('.', '');
                          final desc = t.hsDescription.toLowerCase();
                          final cat = (t.customsCategory ?? '').toLowerCase();
                          final auth = (t.regulatoryAuthority ?? '').toLowerCase();
                          final note = (t.priorApprovalNote ?? '').toLowerCase();
                          return hsClean.contains(query) ||
                              desc.contains(query) ||
                              cat.contains(query) ||
                              auth.contains(query) ||
                              note.contains(query);
                        }).toList();

                  if (filteredTariffs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isNotEmpty
                                ? l10n.noTariffsMatchingQuery(_searchController.text)
                                : l10n.noTariffsFound,
                            style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildTariffTable(context, ref, filteredTariffs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Electronics':
        return AppTheme.cobalt;
      case 'Automotive':
      case 'Automotive Parts':
        return AppTheme.orange;
      case 'Pharmaceuticals':
        return AppTheme.emerald;
      case 'Agriculture & Food':
        return const Color(0xFF27AE60);
      case 'Luxury Goods':
        return AppTheme.crimson;
      case 'Home Appliances':
        return const Color(0xFF8E44AD);
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildTariffTable(
      BuildContext context, WidgetRef ref, List<CustomsTariffModel> tariffs) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1150 ? 1150.0 : constraints.maxWidth;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
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
                child: SizedBox(
                  width: tableWidth,
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(130),
                      1: FlexColumnWidth(3),
                      2: FixedColumnWidth(140),
                      3: FixedColumnWidth(180),
                      4: FixedColumnWidth(140),
                      5: FixedColumnWidth(90),
                      6: FixedColumnWidth(160),
                    },
                    children: [
                  // Header Row
                  TableRow(
                    decoration: const BoxDecoration(color: AppTheme.charcoal),
                    children: [
                      l10n.tariffHsCodeCol,
                      l10n.tariffDescAndAuthorityCol,
                      l10n.tariffCategoryCol,
                      l10n.tariffTaxRatesBreakdownCol,
                      l10n.tariffRequirementsCol,
                      l10n.tariffStatusCol,
                      l10n.tariffActionsCol,
                    ]
                        .map((h) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
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
                  ...tariffs.asMap().entries.map((entry) {
                    final tariff = entry.value;
                    final isEven = entry.key % 2 == 0;
                    final catColor = _getCategoryColor(tariff.customsCategory);

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : Colors.grey.shade50,
                      ),
                      children: [
                        // HS Code Badge
                        _cell(
                          child: InkWell(
                            onTap: () =>
                                showNafezaDetailsDialog(context, ref, tariff),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.cobalt.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppTheme.cobalt.withOpacity(0.3)),
                              ),
                              child: Text(
                                tariff.hsCode,
                                style: const TextStyle(
                                  color: AppTheme.cobalt,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Description & Regulatory Authority
                        _cell(
                          child: InkWell(
                            onTap: () =>
                                showNafezaDetailsDialog(context, ref, tariff),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tariff.hsDescription,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.charcoal,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (tariff.regulatoryAuthority != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      l10n.govAuthorityPrefix(tariff.regulatoryAuthority!),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Category
                        _cell(
                          child: tariff.customsCategory != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    tariff.customsCategory!,
                                    style: TextStyle(
                                      color: catColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                )
                              : const Text('—',
                                  style: TextStyle(color: Colors.grey)),
                        ),

                        // Tax Rates Breakdown
                        _cell(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _rateBadge(l10n.rateDutyBadge('${tariff.customsDutyRate}%'),
                                  AppTheme.cobalt),
                              _rateBadge(l10n.rateVatBadge('${tariff.vatRate}%'),
                                  AppTheme.emerald),
                              if (tariff.scheduleTaxRate > 0)
                                _rateBadge(
                                    l10n.rateSchedBadge('${tariff.scheduleTaxRate}%'),
                                    AppTheme.crimson),
                              if (tariff.developmentFeeRate > 0)
                                _rateBadge(
                                    l10n.rateDevBadge('${tariff.developmentFeeRate}%'),
                                    AppTheme.orange),
                            ],
                          ),
                        ),

                        // Requirements (COO, Inspection, ACID)
                        _cell(
                          child: Row(
                            children: [
                              _reqIcon('ACID', tariff.requiresAcid),
                              const SizedBox(width: 4),
                              _reqIcon('COO', tariff.requiresCoo),
                              const SizedBox(width: 4),
                              _reqIcon('INSP', tariff.requiresInspection),
                            ],
                          ),
                        ),

                        // Status
                        _cell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tariff.isActive
                                  ? AppTheme.emerald.withOpacity(0.1)
                                  : AppTheme.crimson.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tariff.isActive ? l10n.statusActive : l10n.statusInactive,
                              style: TextStyle(
                                color: tariff.isActive
                                    ? AppTheme.emerald
                                    : AppTheme.crimson,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),

                        // Actions: View (Nafeza Details), Edit, Print, Delete
                        _cell(
                          child: RowActionsPill(
                            onView: () => showNafezaDetailsDialog(context, ref, tariff),
                            onEdit: () => showTariffDialog(context, ref, tariff: tariff),
                            onPrint: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.printTariffSnack(tariff.hsCode, tariff.hsDescription)),
                                  backgroundColor: AppTheme.charcoal,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            onDelete: () async {
                              final isActive = tariff.isActive;
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n.confirmActionTitle),
                                  content: Text(isActive
                                      ? l10n.confirmDeactivateTariff(tariff.hsCode)
                                      : l10n.confirmActivateTariff(tariff.hsCode)),
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
                              if (confirm == true) {
                                await ref
                                    .read(customsTariffProvider.notifier)
                                    .toggleActive(tariff.tariffId, tariff.isActive);
                              }
                            },
                            deleteTooltip: tariff.isActive ? l10n.deactivateTariffTooltip : l10n.activateTariffTooltip,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _rateBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _reqIcon(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppTheme.cobalt.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color:
              active ? AppTheme.cobalt.withOpacity(0.4) : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: active ? AppTheme.cobalt : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _cell({required Widget child}) => TableRowInkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      );

  // ==================================================
  // Add / Edit Customs Tariff Dialog (MD-008) - Smart Text & Manual Modes
  // ==================================================


  // ==================================================
  // Excel / CSV Dataset Import Handler
  // ==================================================

  Future<void> _handleExcelImport(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(l10n.importingTariffDataset),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final summary = await ref
              .read(customsTariffProvider.notifier)
              .uploadExcelTariffs(file.bytes!, file.name);

          if (context.mounted) {
            Navigator.pop(context); // Close loading dialog
            final imported = summary?['imported'] ?? 0;
            final updated = summary?['updated'] ?? 0;
            final total = summary?['total_processed'] ?? 0;

            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.emerald),
                    const SizedBox(width: 8),
                    Text(l10n.importCompletedTitle),
                  ],
                ),
                content: Text(
                  l10n.importSummaryContent(total, imported, updated),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.ok),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importFailedSnack(e.toString())),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    }
  }

}
