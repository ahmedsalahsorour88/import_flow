import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

void showRouteIntelligenceDialog(BuildContext context, WidgetRef ref, {
  required int supplierId,
  required String supplierName,
}) {
  showDialog(
    context: context,
    builder: (ctx) => RouteIntelligenceDialog(
      supplierId: supplierId,
      supplierName: supplierName,
    ),
  );
}

class RouteIntelligenceDialog extends ConsumerStatefulWidget {
  final int supplierId;
  final String supplierName;

  const RouteIntelligenceDialog({
    super.key,
    required this.supplierId,
    required this.supplierName,
  });

  @override
  ConsumerState<RouteIntelligenceDialog> createState() => _RouteIntelligenceDialogState();
}

class _RouteIntelligenceDialogState extends ConsumerState<RouteIntelligenceDialog> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _card;

  @override
  void initState() {
    super.initState();
    _fetchIntelligenceCard();
  }

  Future<void> _fetchIntelligenceCard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/route-intelligence/supplier/${widget.supplierId}');
      if (mounted) {
        setState(() {
          _card = res.data is Map<String, dynamic> ? res.data : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? SizedBox(
                    height: 250,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.crimson, size: 48),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppTheme.crimson)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchIntelligenceCard,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final country = _card?['country_name'] ?? '';
    final code = _card?['country_code'] ?? '';
    final avgCycleDays = _card?['average_cycle_days'] ?? 0;
    final recommendation = _card?['executive_recommendation_ar'] ?? '';
    final historicalPrices = (_card?['historical_prices'] as List<dynamic>?) ?? [];
    final recentFreight = _card?['recent_freight'] as Map<String, dynamic>?;
    final clearance = _card?['customs_clearance'] as Map<String, dynamic>?;
    final notes = (_card?['operational_notes'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cobalt.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.cobalt, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بطاقة ذكاء المسار والمورد والتاريخ التفاوضي (Route Intelligence Card)',
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                    Text(
                      'المورد: ${widget.supplierName}  •  الدولة: $country ($code)',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Executive AI Recommendation Banner
          if (recommendation.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cobalt.withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.cobalt, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'توصية الذكاء الاصطناعي للاعتماد والتفاوض:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(recommendation, style: TextStyle(color: Colors.grey.shade900, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Top KPI Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'متوسط دورة الاستيراد',
                  '$avgCycleDays يوم',
                  Icons.timelapse_outlined,
                  AppTheme.cobalt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'آخر نولون مسجل',
                  recentFreight != null ? '\$${(recentFreight['freight_cost_usd'] ?? 0)}' : 'غير مسجل',
                  Icons.directions_boat_outlined,
                  AppTheme.emerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'آخر أتعاب تخليص',
                  clearance != null ? '${(clearance['clearance_fee_egp'] ?? 0)} ج.م' : 'غير مسجل',
                  Icons.receipt_outlined,
                  AppTheme.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Historical Item Prices
          const Text('📊 تاريخ أسعار الأصناف من هذا المورد (Historical Item Prices):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
          const SizedBox(height: 8),
          if (historicalPrices.isEmpty)
            Text('لا توجد مشتريات سابقة مسجلة لأصناف هذا المورد بعد.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
          else
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(padding: EdgeInsets.all(8), child: Text('كود الصنف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8), child: Text('الوصف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8), child: Text('آخر سعر وحدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8), child: Text('أمر الشراء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                ...historicalPrices.map((p) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text(p['item_code'] ?? '', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text(p['item_description'] ?? '', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${p['currency'] ?? 'USD'} ${p['last_unit_price'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text(p['order_code'] ?? '', style: const TextStyle(fontSize: 12))),
                  ],
                )),
              ],
            ),
          const SizedBox(height: 18),

          // Operational Notes & Warnings
          if (notes.isNotEmpty) ...[
            const Text('⚠️ الملاحظات التشغيلية والتحذيرات السابقة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.crimson)),
            const SizedBox(height: 8),
            ...notes.map((n) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.crimson),
                  const SizedBox(width: 8),
                  Expanded(child: Text(n.toString(), style: const TextStyle(fontSize: 12.5))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.charcoal)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
