import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import '../../../core/widgets/searchable_dropdown_field.dart';
import '../../import_files/providers/import_files_provider.dart';

class LandedCostComparisonScreen extends ConsumerStatefulWidget {
  final int? importFileId;
  final String? importFileCode;

  const LandedCostComparisonScreen({
    super.key,
    this.importFileId,
    this.importFileCode,
  });

  @override
  ConsumerState<LandedCostComparisonScreen> createState() => _LandedCostComparisonScreenState();
}

class _LandedCostComparisonScreenState extends ConsumerState<LandedCostComparisonScreen> {
  bool _isLoading = false;
  String? _error;

  int? _selectedImportFileId;
  String _selectedImportFileCode = '';
  double _estimatedCost = 0.0;
  Map<String, dynamic>? _settlementRecord;

  // Colors based on AppTheme specifications
  final Color _charcoal = AppTheme.charcoal;
  final Color _cobalt = AppTheme.cobalt;
  final Color _emerald = AppTheme.emerald;
  final Color _crimson = AppTheme.crimson;

  @override
  void initState() {
    super.initState();
    _selectedImportFileId = widget.importFileId;
    _selectedImportFileCode = widget.importFileCode ?? '';
    Future.microtask(() {
      ref.read(importFilesProvider.notifier).fetchImportFiles();
      if (_selectedImportFileId != null && _selectedImportFileId! > 0) {
        _fetchData(_selectedImportFileId!);
      }
    });
  }

  String _selectedIncoterm = 'FOB';

  Future<void> _fetchData(int fileId) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedImportFileId = fileId;
    });

    try {
      final dio = ref.read(dioProvider);

      // Fetch import file for estimated cost and Incoterm
      try {
        final importFileRes = await dio.get('${ApiConstants.baseUrl}/import-files/$fileId');
        if (importFileRes.data != null) {
          _estimatedCost = (importFileRes.data['estimated_cost'] ?? 0.0).toDouble();
          if (importFileRes.data['import_file_code'] != null) {
            _selectedImportFileCode = importFileRes.data['import_file_code'].toString();
          }
          if (importFileRes.data['incoterm_code'] != null) {
            _selectedIncoterm = importFileRes.data['incoterm_code'].toString().toUpperCase();
          }
        }
      } catch (_) {
        _estimatedCost = 0.0;
        _selectedIncoterm = 'FOB';
      }

      // Fetch settlement record safely
      try {
        final settlementRes = await dio.get('${ApiConstants.baseUrl}/financial-settlements', queryParameters: {
          'import_file_id': fileId,
        });

        final settlements = settlementRes.data;
        if (settlements != null && settlements is List && settlements.isNotEmpty) {
          _settlementRecord = settlements.first;
          if (_settlementRecord?['incoterm_code'] != null) {
            _selectedIncoterm = _settlementRecord!['incoterm_code'].toString().toUpperCase();
          }
        } else if (settlements != null && settlements is Map<String, dynamic> && settlements.containsKey('settlement_id')) {
          _settlementRecord = settlements;
          if (_settlementRecord?['incoterm_code'] != null) {
            _selectedIncoterm = _settlementRecord!['incoterm_code'].toString().toUpperCase();
          }
        } else {
          _settlementRecord = null;
        }
      } catch (_) {
        // No settlement registered yet for this file
        _settlementRecord = null;
      }

    } catch (e) {
      _settlementRecord = null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'freight': return Colors.blue;
      case 'customs': return Colors.orange;
      case 'clearance': return Colors.teal;
      case 'transport': return Colors.purple;
      case 'storage': return Colors.amber.shade800;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fileDisplayCode = _selectedImportFileCode.isNotEmpty ? _selectedImportFileCode : (_selectedImportFileId != null ? 'IMP-#$_selectedImportFileId' : '');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          fileDisplayCode.isNotEmpty ? l10n.landedCostComparisonTitle(fileDisplayCode) : l10n.landedCostComparison,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _charcoal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          BackToDashboardButton(),
          SizedBox(width: 10),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildImportFileSelector(),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _error != null 
                    ? Center(child: Text(_error!, style: TextStyle(color: _crimson)))
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildImportFileSelector() {
    final l10n = context.l10n;
    final importFiles = ref.watch(importFilesProvider).value ?? [];

    final items = importFiles.map((file) {
      final code = file.importFileCode;
      final supplier = file.supplierName.isNotEmpty ? file.supplierName : l10n.unknownSupplierFallback;
      final company = file.companyName.isNotEmpty ? file.companyName : '';
      final label = '$code — $supplier ${company.isNotEmpty ? "($company)" : ""}';
      return SearchableDropdownItem<int>(
        value: file.importFileId,
        label: label,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SearchableDropdownField<int>(
        labelText: l10n.selectImportFileDropdownLabel,
        hintText: l10n.selectImportFileDropdownHint,
        value: _selectedImportFileId,
        items: items,
        onChanged: (fileId) {
          if (fileId != null) {
            final found = importFiles.where((f) => f.importFileId == fileId).firstOrNull;
            if (found != null) {
              _selectedImportFileCode = found.importFileCode;
            }
            _fetchData(fileId);
          } else {
            setState(() {
              _selectedImportFileId = null;
              _selectedImportFileCode = '';
              _settlementRecord = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildContent() {
    final l10n = context.l10n;
    if (_selectedImportFileId == null) {
      return Center(
        child: Text(
          l10n.selectImportFilePrompt,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    if (_settlementRecord == null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 64, color: _charcoal),
                const SizedBox(height: 16),
                Text(l10n.noLandedCostDataRegistered, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    }

    final totalFobEgp = (_settlementRecord!['total_fob_egp'] ?? 0.0).toDouble();
    final totalExpensesEgp = (_settlementRecord!['total_expenses_egp'] ?? 0.0).toDouble();
    final totalLandedCostEgp = (_settlementRecord!['total_landed_cost_egp'] ?? 0.0).toDouble();
    
    final fobVariance = _estimatedCost > 0 ? ((totalFobEgp - _estimatedCost) / _estimatedCost) * 100 : 0.0;
    final landedVariance = _estimatedCost > 0 ? ((totalLandedCostEgp - _estimatedCost) / _estimatedCost) * 100 : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildIncotermRuleCard(),
          const SizedBox(height: 24),
          _buildSummaryCards(totalFobEgp, totalExpensesEgp, totalLandedCostEgp, fobVariance, landedVariance),
          const SizedBox(height: 32),
          Text(l10n.expenseBreakdownHeader, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildExpenseTable(),
          const SizedBox(height: 32),
          Text(l10n.itemLandedCostHeader, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildItemLandedCostTable(),
          const SizedBox(height: 32),
          _buildSummaryBanner(landedVariance),
        ],
      ),
    );
  }

  Widget _buildIncotermRuleCard() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final inco = _selectedIncoterm.toUpperCase();

    String ruleTitle;
    String ruleDesc;
    List<String> exporterCovers;
    List<String> importerCovers;

    switch (inco) {
      case 'CIF':
      case 'CIP':
        ruleTitle = isArabic ? 'قاعدة تسليم CIF / CIP (التكلفة والتأمين والنولون)' : 'CIF / CIP Rule (Cost, Insurance & Freight)';
        ruleDesc = isArabic 
            ? 'فاتورة الشراء تشمل نولون الشحن الدولي والتأمين البحري. تكلفة الوصول الواصلة للمستورد تتكون من: (قيمة الفاتورة CIF + الضرائب والرسوم الجمركية + أتعاب التخليص ومصاريف الميناء + النقل الداخلي).'
            : 'Purchase invoice includes international freight and marine insurance. Importer Landed Cost = (CIF Invoice + Customs Duties & Taxes + Port & Clearance Fees + Local Transport).';
        exporterCovers = isArabic ? ['النولون الدولي', 'التأمين البحري', 'إجراءات التصدير'] : ['Ocean Freight', 'Marine Insurance', 'Export Clearance'];
        importerCovers = isArabic ? ['الجمارك والضرائب', 'أتعاب التخليص', 'رسوم الميناء DTHC', 'النقل الداخلي'] : ['Customs & Taxes', 'Clearance Fees', 'DTHC Port Fees', 'Local Inland Transport'];
        break;
      case 'CFR':
      case 'CPT':
        ruleTitle = isArabic ? 'قاعدة تسليم CFR / CPT (التكلفة والنولون)' : 'CFR / CPT Rule (Cost & Freight)';
        ruleDesc = isArabic
            ? 'فاتورة الشراء تشمل نولون الشحن الدولي فقط. تكلفة الوصول للمستورد تشمل: (قيمة الفاتورة CFR + وثيقة التأمين البحري + الضرائب والرسوم الجمركية + أتعاب التخليص + النقل الداخلي).'
            : 'Purchase invoice covers international freight. Importer Landed Cost = (CFR Invoice + Marine Insurance + Customs Duties & Taxes + Clearance + Local Transport).';
        exporterCovers = isArabic ? ['النولون الدولي', 'إجراءات التصدير'] : ['Ocean Freight', 'Export Clearance'];
        importerCovers = isArabic ? ['التأمين البحري', 'الجمارك والضرائب', 'أتعاب التخليص', 'النقل الداخلي'] : ['Marine Insurance', 'Customs & Taxes', 'Clearance', 'Local Transport'];
        break;
      case 'EXW':
        ruleTitle = isArabic ? 'قاعدة تسليم EXW (تسليم أرض المصنع)' : 'EXW Rule (Ex Works - Factory Gate)';
        ruleDesc = isArabic
            ? 'فاتورة الشراء تغطي ثمن البضاعة بأرض المصنع فقط. المستورد يتحمل كافة التكاليف من بلد المنشأ حتى الوصول: (قيمة الفاتورة + نقل المنشأ + تخليص التصدير + النولون + التأمين + الجمارك + التخليص + النقل الداخلي).'
            : 'Invoice covers factory goods only. Importer bears all origin-to-destination costs: (EXW Invoice + Origin Trucking + Export Clearance + Freight + Insurance + Customs + Clearance + Local Transport).';
        exporterCovers = isArabic ? ['تجهيز البضاعة بالمصنع'] : ['Goods Packaging at Factory'];
        importerCovers = isArabic ? ['نقل وتخليص المنشأ', 'النولون والتأمين', 'الجمارك والضرائب', 'التخليص والنقل الداخلي'] : ['Origin Trucking & Export', 'Freight & Insurance', 'Customs & Taxes', 'Clearance & Transport'];
        break;
      case 'DDP':
        ruleTitle = isArabic ? 'قاعدة تسليم DDP (التسليم خالص الرسوم والجمارك)' : 'DDP Rule (Delivered Duty Paid)';
        ruleDesc = isArabic
            ? 'فاتورة الشراء تغطي كافة التكاليف بما فيها الشحن والتأمين والرسوم الجمركية والتوصيل. المستورد لا يتحمل سوى أي مصاريف استثنائية للتخزين إن وجدت.'
            : 'Invoice covers freight, insurance, customs duties, and local delivery. Importer only bears extraordinary storage/handling fees if incurred.';
        exporterCovers = isArabic ? ['النولون والتأمين', 'الضرائب والجمارك', 'النقل حتى المستودع'] : ['Freight & Insurance', 'Customs Duties & Taxes', 'Delivery to Warehouse'];
        importerCovers = isArabic ? ['التفريغ أو التخزين الاستثنائي'] : ['Unloading / Extraordinary Storage'];
        break;
      case 'FOB':
      case 'FCA':
      case 'FAS':
      default:
        ruleTitle = isArabic ? 'قاعدة تسليم FOB / FCA (تسليم على ظهر السفينة)' : 'FOB / FCA Rule (Free On Board)';
        ruleDesc = isArabic
            ? 'فاتورة الشراء تشمل ثمن البضاعة وتحميلها على السفينة بميناء الشحن. تكلفة الوصول للمستورد تتكون من: (قيمة الفاتورة FOB + نولون الشحن + التأمين البحري + الرسوم الجمركية والضرائب + التخليص + النقل الداخلي).'
            : 'Invoice covers goods loaded on vessel at origin port. Importer Landed Cost = (FOB Invoice + Ocean Freight + Marine Insurance + Customs Duties & Taxes + Clearance + Local Transport).';
        exporterCovers = isArabic ? ['نقل وتخليص المنشأ', 'التحميل بميناء الشحن'] : ['Origin Transport & Export', 'Loading on Vessel'];
        importerCovers = isArabic ? ['النولون الدولي', 'التأمين البحري', 'الجمارك والضرائب', 'التخليص والنقل الداخلي'] : ['Ocean Freight', 'Marine Insurance', 'Customs & Taxes', 'Clearance & Local Transport'];
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cobalt.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inco,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ruleTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ruleDesc,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? '✔ مشمول في الفاتورة (على البائع):' : '✔ Included in Invoice (Exporter):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exporterCovers.join(' • '),
                        style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? '➕ إضافات تكلفة الوصول (على المستورد):' : '➕ Added Landed Cost Expenses (Importer):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        importerCovers.join(' • '),
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _cobalt.withOpacity(0.1), border: Border(bottom: BorderSide(color: _cobalt, width: 4))),
            child: Center(child: Text(l10n.estimatedCostHeader, style: TextStyle(fontSize: 22, color: _cobalt, fontWeight: FontWeight.bold))),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _emerald.withOpacity(0.1), border: Border(bottom: BorderSide(color: _emerald, width: 4))),
            child: Center(child: Text(l10n.actualCostHeader, style: TextStyle(fontSize: 22, color: _emerald, fontWeight: FontWeight.bold))),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(double totalFob, double totalExpenses, double totalLanded, double fobVariance, double landedVariance) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(child: _buildCard(l10n.fobValueCardTitle, _estimatedCost, totalFob, fobVariance)),
        const SizedBox(width: 16),
        Expanded(child: _buildCard(l10n.totalExpensesCardTitle, 0, totalExpenses, null)),
        const SizedBox(width: 16),
        Expanded(child: _buildCard(l10n.totalLandedCostCardTitle, _estimatedCost, totalLanded, landedVariance, highlight: true)),
      ],
    );
  }

  Widget _buildCard(String title, double est, double act, double? variance, {bool highlight = false}) {
    final l10n = context.l10n;
    Color? varColor;
    if (variance != null) {
      varColor = variance > 0 ? _crimson : _emerald;
    }

    return Card(
      elevation: highlight ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: highlight ? BorderSide(color: _charcoal, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.estAbbreviation, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(est.toStringAsFixed(2), style: TextStyle(fontSize: 15, color: _cobalt, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.actAbbreviation, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(act.toStringAsFixed(2), style: TextStyle(fontSize: 15, color: _emerald, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            if (variance != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: varColor?.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('${variance > 0 ? '+' : ''}${variance.toStringAsFixed(2)}%', style: TextStyle(color: varColor, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTable() {
    final l10n = context.l10n;
    final expenses = _settlementRecord?['expense_invoices'] as List? ?? [];
    return DataTable(
      headingRowColor: WidgetStateProperty.all(_charcoal.withOpacity(0.05)),
      columns: [
        DataColumn(label: Text(l10n.colExpenseCategory, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(l10n.colExpenseProvider, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(l10n.colExpenseCurrency, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(l10n.colExpenseAmountFx, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(l10n.colExpenseExchangeRate, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(l10n.colExpenseAmountEgp, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: expenses.map((e) {
        final categoryRaw = e['category']?.toString() ?? 'other';
        final categoryLocalized = l10n.expenseCategoryName(categoryRaw);
        return DataRow(
          cells: [
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _getCategoryColor(categoryRaw).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(categoryLocalized, style: TextStyle(color: _getCategoryColor(categoryRaw), fontWeight: FontWeight.bold)),
            )),
            DataCell(Text(e['provider_name']?.toString() ?? '')),
            DataCell(Text(e['currency']?.toString() ?? '')),
            DataCell(Text((e['amount_fx'] ?? 0).toString())),
            DataCell(Text((e['exchange_rate'] ?? 0).toString())),
            DataCell(Text((e['amount_egp'] ?? 0).toString())),
          ]
        );
      }).toList(),
    );
  }

  Widget _buildItemLandedCostTable() {
    final l10n = context.l10n;
    final items = _settlementRecord?['item_landed_costs'] as List? ?? [];
    return DataTable(
      headingRowColor: WidgetStateProperty.all(_charcoal.withOpacity(0.05)),
      columns: [
        DataColumn(label: Text(l10n.colItemCode, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(l10n.colItemName, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(l10n.colItemQty, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(l10n.colFobUnitPrice, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(l10n.colLandedUnitPrice, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text(l10n.colCostMarkupFactor, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: items.map((e) {
        final markup = (e['markup_factor'] ?? 1.0).toDouble();
        return DataRow(
          cells: [
            DataCell(Text(e['item_code']?.toString() ?? '')),
            DataCell(Text(e['item_name']?.toString() ?? '')),
            DataCell(Text((e['qty'] ?? 0).toString())),
            DataCell(Text((e['fob_unit_egp'] ?? 0).toStringAsFixed(2))),
            DataCell(Text((e['unit_landed_cost_egp'] ?? 0).toStringAsFixed(2))),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _charcoal, borderRadius: BorderRadius.circular(16)),
              child: Text('${markup.toStringAsFixed(2)}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
          ]
        );
      }).toList(),
    );
  }

  Widget _buildSummaryBanner(double landedVariance) {
    final l10n = context.l10n;
    if (landedVariance > 10) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _crimson.withOpacity(0.1), border: Border.all(color: _crimson), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(Icons.warning, color: _crimson),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.landedCostOverBudgetBanner(landedVariance.toStringAsFixed(2)), style: TextStyle(color: _crimson, fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    } else if (landedVariance < 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _emerald.withOpacity(0.1), border: Border.all(color: _emerald), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: _emerald),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.landedCostUnderBudgetBanner(landedVariance.abs().toStringAsFixed(2)), style: TextStyle(color: _emerald, fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
