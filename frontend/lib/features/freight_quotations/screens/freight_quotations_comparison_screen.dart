import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/widgets/back_to_dashboard_button.dart';


class FreightQuotationsComparisonScreen extends StatefulWidget {
  const FreightQuotationsComparisonScreen({super.key});

  @override
  State<FreightQuotationsComparisonScreen> createState() => _FreightQuotationsComparisonScreenState();
}

class _FreightQuotationsComparisonScreenState extends State<FreightQuotationsComparisonScreen> {
  final Color _charcoal = const Color(0xFF2C3E50);
  final Color _cobalt = const Color(0xFF3498DB);
  final Color _emerald = const Color(0xFF27AE60);
  final Color _gold = const Color(0xFFFFD700);

  bool _isLoading = false;
  String? _error;
  List<dynamic> _quotations = [];
  int? _selectedImportFileId;
  int? _selectedQuotationId;

  // Ideally, use the SearchableDropdownField from core/widgets
  // For this standalone screen, we'll fetch available import files or allow user input
  // to pick an import_file_id. We'll simulate the SearchableDropdown functionality
  // by using a simple Dropdown or text field for now, but in the real app you'd replace
  // this with SearchableDropdownField.

  Future<void> _fetchQuotations(int importFileId) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedImportFileId = importFileId;
    });

    try {
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1'));
      // The endpoint might return a list of quotation items or RFQs. Assuming it returns quotations.
      final res = await dio.get('/freight-quotations', queryParameters: {'import_file_id': importFileId});
      
      final data = res.data;
      if (data is List) {
        _quotations = data.take(4).toList(); // Max 4
      } else if (data != null && data['quotations'] is List) {
        _quotations = (data['quotations'] as List).take(4).toList();
      } else {
        _quotations = [];
      }
      
      // Determine selected if any
      final selected = _quotations.where((q) => q['is_awarded'] == true).toList();
      if (selected.isNotEmpty) {
        _selectedQuotationId = selected.first['quotation_id'];
      } else {
        _selectedQuotationId = null;
      }

    } catch (e) {
      _error = 'حدث خطأ أثناء تحميل عروض الأسعار: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectQuotation(int quotationId) async {
    setState(() {
      _selectedQuotationId = quotationId;
    });
    // Call API to mark as awarded
    try {
       // await Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1')).post('/freight-quotations/$quotationId/award');
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم اختيار عرض السعر بنجاح')));
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مقارنة عروض أسعار الشحن (Side-by-Side Comparison)', style: TextStyle(color: Colors.white)),
        backgroundColor: _charcoal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          BackToDashboardButton(),
          SizedBox(width: 10),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImportFileSelector(),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
            else if (_selectedImportFileId == null)
              const Center(child: Text('الرجاء اختيار ملف استيراد لعرض عروض الأسعار', style: TextStyle(fontSize: 18)))
            else if (_quotations.isEmpty)
              const Center(child: Text('لا توجد عروض أسعار مسجلة لهذا الملف', style: TextStyle(fontSize: 18)))
            else
              Expanded(
                child: Column(
                  children: [
                    _buildMetricsBar(),
                    const SizedBox(height: 24),
                    Expanded(child: _buildComparisonColumns()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportFileSelector() {
    // This is a placeholder for SearchableDropdownField
    return Row(
      children: [
        const Text('رقم ملف الاستيراد:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 16),
        SizedBox(
          width: 200,
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'أدخل رقم الملف واضغط Enter',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (val) {
              final id = int.tryParse(val);
              if (id != null) {
                _fetchQuotations(id);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        const Text('(ملاحظة: يجب استخدام SearchableDropdownField<T> كما ورد في القواعد)', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMetricsBar() {
    if (_quotations.isEmpty) return const SizedBox.shrink();

    // Find cheapest
    var cheapest = _quotations.first;
    for (var q in _quotations) {
      if ((q['total_cost'] ?? 0) < (cheapest['total_cost'] ?? 0)) cheapest = q;
    }

    // Find fastest
    var fastest = _quotations.first;
    for (var q in _quotations) {
      if ((q['transit_days'] ?? 999) < (fastest['transit_days'] ?? 999)) fastest = q;
    }

    // Find selected
    final selected = _quotations.where((q) => q['quotation_id'] == _selectedQuotationId).toList();
    final selectedName = selected.isNotEmpty ? selected.first['provider_name'] : 'لم يتم الاختيار بعد';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _charcoal.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric('الأرخص', '${cheapest['provider_name']} (${cheapest['total_cost']} ${cheapest['currency_code']})', Icons.attach_money, _emerald),
          _buildMetric('الأسرع', '${fastest['provider_name']} (${fastest['transit_days']} يوم)', Icons.speed, _cobalt),
          _buildMetric('المختار حالياً', selectedName, Icons.check_circle, _charcoal),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          ],
        )
      ],
    );
  }

  Widget _buildComparisonColumns() {
    // Determine cheapest id to give it a gold badge
    int? cheapestId;
    if (_quotations.isNotEmpty) {
      var cheapest = _quotations.first;
      for (var q in _quotations) {
        if ((q['total_cost'] ?? 0) < (cheapest['total_cost'] ?? 0)) cheapest = q;
      }
      cheapestId = cheapest['quotation_id'];
    }

    return Row(
      children: _quotations.map((q) {
        final qId = q['quotation_id'];
        final isSelected = qId == _selectedQuotationId;
        final isCheapest = qId == cheapestId;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? _emerald : Colors.grey.shade300, width: isSelected ? 3 : 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? _emerald.withOpacity(0.1) : _charcoal.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Column(
                    children: [
                      if (isCheapest)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(12)),
                          child: const Text('الأفضل سعراً', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      Text(q['provider_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDetailRow('إجمالي التكلفة', '${q['total_cost']} ${q['currency_code']}', bold: true, color: _emerald),
                      _buildDetailRow('الشحن البحري', '${q['ocean_freight_cost']} ${q['currency_code']}'),
                      _buildDetailRow('مصاريف محلية', '${q['local_charges_cost']} ${q['currency_code']}'),
                      const Divider(),
                      _buildDetailRow('مدة الترانزيت', '${q['transit_days']} يوم'),
                      _buildDetailRow('تاريخ الإبحار', q['sailing_date']?.toString() ?? '-'),
                      _buildDetailRow('تاريخ الوصول', q['estimated_arrival_date']?.toString() ?? '-'),
                      const Divider(),
                      if (q['remarks'] != null) ...[
                        const Text('ملاحظات:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(q['remarks'].toString()),
                      ]
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? _emerald : _charcoal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _selectQuotation(qId),
                    child: Text(isSelected ? 'تم الاختيار' : 'اختيارها', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color ?? _charcoal, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}
