import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';


class LandedCostComparisonScreen extends ConsumerStatefulWidget {
  final int importFileId;
  final String importFileCode;

  const LandedCostComparisonScreen({
    super.key,
    required this.importFileId,
    required this.importFileCode,
  });

  @override
  ConsumerState<LandedCostComparisonScreen> createState() => _LandedCostComparisonScreenState();
}

class _LandedCostComparisonScreenState extends ConsumerState<LandedCostComparisonScreen> {
  bool _isLoading = true;
  String? _error;

  double _estimatedCost = 0.0;
  Map<String, dynamic>? _settlementRecord;

  // Colors based on AppTheme specifications
  final Color _charcoal = const Color(0xFF2C3E50);
  final Color _cobalt = const Color(0xFF3498DB);
  final Color _emerald = const Color(0xFF27AE60);
  final Color _crimson = const Color(0xFFC0392B);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1'));
      
      // Fetch import file for estimated cost
      try {
        final importFileRes = await dio.get('/import-files/${widget.importFileId}');
        _estimatedCost = (importFileRes.data['estimated_cost'] ?? 0.0).toDouble();
      } catch (e) {
        // Fallback if endpoint doesn't exist
        _estimatedCost = 0.0;
      }

      // Fetch settlement record
      final settlementRes = await dio.get('/financial-settlements', queryParameters: {
        'import_file_id': widget.importFileId,
      });

      final settlements = settlementRes.data;
      if (settlements != null && settlements is List && settlements.isNotEmpty) {
        _settlementRecord = settlements.first;
      } else if (settlements != null && settlements is Map<String, dynamic> && settlements.containsKey('settlement_id')) {
        _settlementRecord = settlements;
      }

    } catch (e) {
      _error = 'حدث خطأ أثناء تحميل البيانات: $e';
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
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مقارنة Landed Cost — تقديري vs فعلي [${widget.importFileCode}]', style: const TextStyle(color: Colors.white)),
        backgroundColor: _charcoal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          BackToDashboardButton(),
          SizedBox(width: 10),
        ],
      ),

      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null 
              ? Center(child: Text(_error!, style: TextStyle(color: _crimson)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
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
                const Text('لم يتم تسجيل بيانات Landed Cost بعد', style: TextStyle(fontSize: 20)),
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
          _buildSummaryCards(totalFobEgp, totalExpensesEgp, totalLandedCostEgp, fobVariance, landedVariance),
          const SizedBox(height: 32),
          const Text('تفاصيل المصروفات (Expense Breakdown)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildExpenseTable(),
          const SizedBox(height: 32),
          const Text('تكلفة الأصناف (Item Landed Cost)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildItemLandedCostTable(),
          const SizedBox(height: 32),
          _buildSummaryBanner(landedVariance),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _cobalt.withOpacity(0.1), border: Border(bottom: BorderSide(color: _cobalt, width: 4))),
            child: Center(child: Text('التكلفة التقديرية (Estimated)', style: TextStyle(fontSize: 24, color: _cobalt, fontWeight: FontWeight.bold))),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _emerald.withOpacity(0.1), border: Border(bottom: BorderSide(color: _emerald, width: 4))),
            child: Center(child: Text('التكلفة الفعلية (Actual)', style: TextStyle(fontSize: 24, color: _emerald, fontWeight: FontWeight.bold))),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(double totalFob, double totalExpenses, double totalLanded, double fobVariance, double landedVariance) {
    return Row(
      children: [
        Expanded(child: _buildCard('FOB Value', _estimatedCost, totalFob, fobVariance)),
        const SizedBox(width: 16),
        Expanded(child: _buildCard('Total Expenses', 0, totalExpenses, null)),
        const SizedBox(width: 16),
        Expanded(child: _buildCard('Total Landed Cost', _estimatedCost, totalLanded, landedVariance, highlight: true)),
      ],
    );
  }

  Widget _buildCard(String title, double est, double act, double? variance, {bool highlight = false}) {
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Est.', style: TextStyle(color: Colors.grey)),
                    Text(est.toStringAsFixed(2), style: TextStyle(fontSize: 16, color: _cobalt, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Act.', style: TextStyle(color: Colors.grey)),
                    Text(act.toStringAsFixed(2), style: TextStyle(fontSize: 16, color: _emerald, fontWeight: FontWeight.bold)),
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
    final expenses = _settlementRecord?['expense_invoices'] as List? ?? [];
    return DataTable(
      headingRowColor: WidgetStateProperty.all(_charcoal.withOpacity(0.05)),
      columns: const [
        DataColumn(label: Text('الفئة', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('المورد', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('العملة', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('القيمة FX', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('سعر الصرف', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('القيمة جم (EGP)', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: expenses.map((e) {
        final category = e['category']?.toString() ?? 'Other';
        return DataRow(
          cells: [
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _getCategoryColor(category).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(category, style: TextStyle(color: _getCategoryColor(category), fontWeight: FontWeight.bold)),
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
    final items = _settlementRecord?['item_landed_costs'] as List? ?? [];
    return DataTable(
      headingRowColor: WidgetStateProperty.all(_charcoal.withOpacity(0.05)),
      columns: const [
        DataColumn(label: Text('الكود', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('سعر الوحدة (FOB)', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('تكلفة الوحدة (Landed)', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('معامل التكلفة', style: TextStyle(fontWeight: FontWeight.bold))),
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
    if (landedVariance > 10) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _crimson.withOpacity(0.1), border: Border.all(color: _crimson), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(Icons.warning, color: _crimson),
            const SizedBox(width: 16),
            Text('تجاوزت التكلفة التقديرية بنسبة ${landedVariance.toStringAsFixed(2)}%', style: TextStyle(color: _crimson, fontSize: 18, fontWeight: FontWeight.bold)),
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
            Text('وفرت المشروع ${landedVariance.abs().toStringAsFixed(2)}% من الميزانية', style: TextStyle(color: _emerald, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
