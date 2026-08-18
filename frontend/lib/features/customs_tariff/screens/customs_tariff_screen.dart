import '../widgets/duty_calculator_dialog.dart';
import '../widgets/tariff_form_dialog.dart';
import '../widgets/nafeza_details_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/master_data_toolbar.dart';
import '../../../core/widgets/row_actions_pill.dart';
import '../models/customs_tariff_model.dart';
import '../providers/customs_tariff_provider.dart';
import 'hs_code_search_screen.dart';

class CustomsTariffScreen extends ConsumerStatefulWidget {
  const CustomsTariffScreen({super.key});

  @override
  ConsumerState<CustomsTariffScreen> createState() =>
      _CustomsTariffScreenState();
}

class _CustomsTariffScreenState extends ConsumerState<CustomsTariffScreen> {
  final TextEditingController _searchController = TextEditingController();

  double _numToDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }

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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customs Tariff & HS Codes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoal,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Egyptian Customs Duty Rates, VAT, Schedule Taxes, Development Fees & Import Regulations',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
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
                      label: const Text('Import Excel/CSV'),
                      onPressed: () => _handleExcelImport(context, ref),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.charcoal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.saved_search, size: 18, color: Colors.amber),
                      label: const Text('🔍 استعلام وبحث شامل (HS Explorer)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      label: const Text('✨ إدخال بند ومحلل الفروقات الذكي (Smart Nafeza & Diff Engine)'),
                      onPressed: () => showTariffDialog(context, ref, initialModeIndex: 0),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.calculate, size: 18),
                      label: const Text('Duty Calculator'),
                      onPressed: () => showDutyCalculatorDialog(context, ref),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cobalt,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('+ إضافة بند يدوي (Manual Form)'),
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
                      hintText:
                          'Search by HS Code, Description, or Category...',
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
                    const Text('Show Inactive',
                        style: TextStyle(fontWeight: FontWeight.w600)),
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
                                ? 'لم يتم العثور على أي بند يطابق البحث: "${_searchController.text}"'
                                : 'لا توجد بنود جمركية مسجلة.',
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
                minWidth: MediaQuery.of(context).size.width > 1200
                    ? MediaQuery.of(context).size.width - 250
                    : 1150,
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(110),
                  1: FlexColumnWidth(3),
                  2: FixedColumnWidth(130),
                  3: FixedColumnWidth(180),
                  4: FixedColumnWidth(130),
                  5: FixedColumnWidth(80),
                  6: FixedColumnWidth(160),
                },
                children: [
                  // Header Row
                  TableRow(
                    decoration: const BoxDecoration(color: AppTheme.charcoal),
                    children: [
                      'HS Code',
                      'Description & Authority',
                      'Category',
                      'Tax Rates Breakdown',
                      'Requirements',
                      'Status',
                      'Actions'
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
                                      'Gov: ${tariff.regulatoryAuthority}',
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
                              _rateBadge('Duty', '${tariff.customsDutyRate}%',
                                  AppTheme.cobalt),
                              _rateBadge('VAT', '${tariff.vatRate}%',
                                  AppTheme.emerald),
                              if (tariff.scheduleTaxRate > 0)
                                _rateBadge(
                                    'Sched',
                                    '${tariff.scheduleTaxRate}%',
                                    AppTheme.crimson),
                              if (tariff.developmentFeeRate > 0)
                                _rateBadge(
                                    'Dev',
                                    '${tariff.developmentFeeRate}%',
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
                              tariff.isActive ? 'Active' : 'Inactive',
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
                                  content: Text('طباعة بيانات البند الجمركي: ${tariff.hsCode} (${tariff.hsDescription})'),
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
                                  title: const Text('تأكيد الإجراء'),
                                  content: Text(isActive
                                      ? 'هل أنت متأكد من رغبتك في إيقاف تفعيل البند الجمركي (${tariff.hsCode})؟'
                                      : 'هل أنت متأكد من إعادة تفعيل البند الجمركي (${tariff.hsCode})؟'),
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
                                await ref
                                    .read(customsTariffProvider.notifier)
                                    .toggleActive(tariff.tariffId, tariff.isActive);
                              }
                            },
                            deleteTooltip: tariff.isActive ? 'إيقاف تفعيل البند (Deactivate)' : 'إعادة تفعيل البند (Activate)',
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

  Widget _rateBadge(String label, String rate, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $rate',
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
  // Nafeza Official Detail Modal ("تفاصيل البند") matching user screenshot
  // ==================================================


  Widget _taxDetailRow(String label, String rateStr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          Text(
            rateStr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.cobalt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNafezaRulesList(
      CustomsTariffModel tariff, List<Map<String, dynamic>> agreements) {
    final List<String> rules = [];

    // Preferential Agreements from Database
    for (final ag in agreements) {
      final name = ag['agreement_name'] ?? 'اتفاقية تجارية';
      final red = _numToDouble(ag['reduction_percentage'], 1.0);
      final pctStr = (red * 100).toStringAsFixed(0);
      final cond = ag['conditions_note'] != null &&
              ag['conditions_note'].toString().isNotEmpty
          ? ' - ${ag['conditions_note']}'
          : '';
      rules.add('ر ${ag['agreement_id'] ?? 6722} - $name تخفيض $pctStr%$cond');
    }

    // Prior Approval Note & Regulatory Conditions matching screenshot
    if (tariff.priorApprovalNote != null &&
        tariff.priorApprovalNote!.isNotEmpty) {
      rules.add('ق 4518 - ${tariff.priorApprovalNote}');
    } else if (tariff.regulatoryAuthority != null &&
        tariff.regulatoryAuthority!.isNotEmpty) {
      rules.add(
          'ق 4518 - لا يصرح باستيراد صنف إلا بموافقة مختومة بخاتم شعار الجمهورية من ${tariff.regulatoryAuthority}');
    }

    // Standard Nafeza Inspection Rule if required
    if (tariff.requiresInspection) {
      rules.add(
          'ق 4547 - يشترط للإفراج عن الصنف وارد تجار أن يكون إنتاج مصانع مسجلة من شركات مالكة للعلامة أو مطبقاً للائحة الفحص المعتمدة');
    }

    // General VAT Rule matching screenshot (ر 7042 - يحصل ضريبة قيمة مضافة بمقدار14% [عام])
    rules.add(
        'ر 7042 - يحصل ضريبة قيمة مضافة بمقدار ${tariff.vatRate.toStringAsFixed(0)}% [عام]');

    // Additional Notes
    if (tariff.notes != null && tariff.notes!.isNotEmpty) {
      rules.add('ق 9994 - ${tariff.notes}');
    }

    return Column(
      children: rules.map((ruleText) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            border: Border(
              right: BorderSide(color: Color(0xFF1B65A8), width: 3.5),
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              ruleText,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.charcoal,
                height: 1.4,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==================================================
  // Add Preferential Trade Agreement Dialog
  // ==================================================





  Future<void> _handleExcelImport(BuildContext context, WidgetRef ref) async {
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
              builder: (ctx) => const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Importing Customs Tariff Dataset...'),
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
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.emerald),
                    SizedBox(width: 8),
                    Text('Import Completed'),
                  ],
                ),
                content: Text(
                  'Successfully processed $total HS Codes!\n'
                  '• New Tariffs Created: $imported\n'
                  '• Existing Tariffs Updated: $updated',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
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
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: AppTheme.crimson,
          ),
        );
      }
    }
  }

}
