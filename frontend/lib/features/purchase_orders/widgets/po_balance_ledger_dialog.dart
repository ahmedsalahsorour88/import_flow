import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

void showPOBalanceLedgerDialog(BuildContext context, WidgetRef ref, {required int poId, required String poCode}) {
  showDialog(
    context: context,
    builder: (ctx) => POBalanceLedgerDialog(poId: poId, poCode: poCode),
  );
}

class POBalanceLedgerDialog extends ConsumerStatefulWidget {
  final int poId;
  final String poCode;

  const POBalanceLedgerDialog({super.key, required this.poId, required this.poCode});

  @override
  ConsumerState<POBalanceLedgerDialog> createState() => _POBalanceLedgerDialogState();
}

class _POBalanceLedgerDialogState extends ConsumerState<POBalanceLedgerDialog> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _balanceData;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/purchase-orders/${widget.poId}/balance');
      if (mounted) {
        setState(() {
          _balanceData = res.data is Map<String, dynamic> ? res.data : null;
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
        width: 860,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()))
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
                          ElevatedButton(onPressed: _fetchBalance, child: const Text('إعادة المحاولة')),
                        ],
                      ),
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final orderedQty = (_balanceData?['total_ordered_quantity'] as num?)?.toDouble() ?? 0.0;
    final shippedQty = (_balanceData?['total_shipped_quantity'] as num?)?.toDouble() ?? 0.0;
    final remainingQty = (_balanceData?['total_remaining_quantity'] as num?)?.toDouble() ?? 0.0;

    final orderedUsd = (_balanceData?['total_ordered_fob_usd'] as num?)?.toDouble() ?? 0.0;
    final shippedUsd = (_balanceData?['total_shipped_fob_usd'] as num?)?.toDouble() ?? 0.0;
    final remainingUsd = (_balanceData?['total_remaining_fob_usd'] as num?)?.toDouble() ?? 0.0;

    final fulfillment = (_balanceData?['fulfillment_percentage'] as num?)?.toDouble() ?? 0.0;
    final isFullyShipped = _balanceData?['is_fully_shipped'] == true;
    final items = (_balanceData?['line_items'] as List<dynamic>?) ?? [];

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
                child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.cobalt, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ميزان أمر الشراء والشحنات الجزئية (PO Balance & Partial Shipments Ledger)',
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                    Text(
                      'أمر الشراء: ${widget.poCode}  •  نسبة استيفاء التوريد: ${fulfillment.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 16),

          // Fulfillment Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFullyShipped ? '✅ تم استيفاء شحن كامل أمر الشراء (100%)' : '⏳ جاري استكمال شحن الدفعات الجزئية',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFullyShipped ? AppTheme.emerald : AppTheme.charcoal,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      '${fulfillment.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.cobalt),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (fulfillment / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(isFullyShipped ? AppTheme.emerald : AppTheme.cobalt),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 Metric Cards: Ordered vs Shipped vs Remaining
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'إجمالي الكميات المطلوبة',
                  qtyText: '$orderedQty وحدة',
                  usdText: '\$${orderedUsd.toStringAsFixed(2)}',
                  color: AppTheme.charcoal,
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'الكميات المشحونة فعلياً',
                  qtyText: '$shippedQty وحدة',
                  usdText: '\$${shippedUsd.toStringAsFixed(2)}',
                  color: AppTheme.emerald,
                  icon: Icons.local_shipping_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'الرصيد المتبقي للتوريد',
                  qtyText: '$remainingQty وحدة',
                  usdText: '\$${remainingUsd.toStringAsFixed(2)}',
                  color: remainingQty > 0 ? AppTheme.orange : AppTheme.emerald,
                  icon: Icons.hourglass_bottom_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Items Table
          const Text('📋 تفصيل ميزان بنود أمر الشراء (Line Items Balance):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text('كود البند', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('الوصف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('الكمية المطلوبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('المشحون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('المتبقي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...items.map((it) {
                final rem = (it['remaining_quantity'] as num?)?.toDouble() ?? 0.0;
                final isDone = it['is_fully_shipped'] == true;
                return TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text(it['item_code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text(it['description'] ?? '', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${it['ordered_quantity'] ?? 0}', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${it['shipped_quantity'] ?? 0}', style: const TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('$rem', style: TextStyle(color: rem > 0 ? AppTheme.orange : AppTheme.emerald, fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDone ? AppTheme.emerald.withOpacity(0.12) : AppTheme.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isDone ? 'مكتمل ✅' : 'متبقي جزئي ⏳',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDone ? AppTheme.emerald : AppTheme.orange,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String qtyText,
    required String usdText,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text(qtyText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text('القيمة: $usdText', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
