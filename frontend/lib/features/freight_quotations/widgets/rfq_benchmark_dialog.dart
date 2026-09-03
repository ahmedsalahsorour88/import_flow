import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

void showRFQBenchmarkDialog(BuildContext context, WidgetRef ref, {required int rfqId, String? rfqCode}) {
  showDialog(
    context: context,
    builder: (ctx) => RFQBenchmarkDialog(rfqId: rfqId, rfqCode: rfqCode),
  );
}

class RFQBenchmarkDialog extends ConsumerStatefulWidget {
  final int rfqId;
  final String? rfqCode;

  const RFQBenchmarkDialog({super.key, required this.rfqId, this.rfqCode});

  @override
  ConsumerState<RFQBenchmarkDialog> createState() => _RFQBenchmarkDialogState();
}

class _RFQBenchmarkDialogState extends ConsumerState<RFQBenchmarkDialog> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _benchmarkData;

  @override
  void initState() {
    super.initState();
    _fetchBenchmark();
  }

  Future<void> _fetchBenchmark() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/freight-quotations/${widget.rfqId}/benchmark');
      if (mounted) {
        setState(() {
          _benchmarkData = res.data is Map<String, dynamic> ? res.data : null;
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
                    height: 260,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.crimson, size: 48),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppTheme.crimson)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _fetchBenchmark, child: const Text('إعادة المحاولة')),
                        ],
                      ),
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final ranked = (_benchmarkData?['ranked_quotes'] as List<dynamic>?) ?? [];
    final recommendation = _benchmarkData?['executive_recommendation_ar'] ?? '';
    final code = _benchmarkData?['rfq_code'] ?? widget.rfqCode ?? 'RFQ';

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
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.military_tech_outlined, color: Colors.amber.shade800, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المفاضلة التنافسية وترتيب أفضل عروض الشحن (Freight Forwarder Benchmarking)',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                    Text(
                      'طلب عروض الأسعار: $code  •  تم تحليل ${ranked.length} عروض أسعار متنافسة',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 16),

          // Executive AI Recommendation
          if (recommendation.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.workspace_premium_outlined, color: Colors.amber.shade900, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التوصية التنفيذية لاعتماد العرض الفائز:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(recommendation, style: TextStyle(color: Colors.grey.shade900, fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Podium / Top 3 Cards
          if (ranked.isNotEmpty)
            Row(
              children: ranked.take(3).map((q) => Expanded(child: _buildPodiumCard(q))).toList(),
            ),
          const SizedBox(height: 20),

          // Full Benchmarking Table
          const Text('📊 المقارنة الشاملة لكافة عروض الأسعار:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text('المركز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('شركة الشحن / الوكيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('السعر الإجمالي (\$)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('سماح الوصول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('مدة الإبحار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('التقييم المركب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...ranked.map((q) => TableRow(
                decoration: BoxDecoration(
                  color: q['is_winner'] == true ? Colors.green.shade50 : Colors.white,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      q['rank'] == 1 ? '🥇 الأول' : q['rank'] == 2 ? '🥈 الثاني' : q['rank'] == 3 ? '🥉 الثالث' : '#${q['rank']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(q['forwarder_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('\$${(q['total_cost_usd'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.charcoal)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${q['free_days_pod'] ?? 0} يوم', style: const TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${q['transit_days'] ?? 0} يوم', style: const TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('${(q['composite_score'] ?? 0).toStringAsFixed(1)} / 100',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cobalt, fontSize: 12)),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(Map<String, dynamic> q) {
    final rank = q['rank'] ?? 1;
    final isWinner = rank == 1;
    final Color badgeColor = rank == 1 ? Colors.amber.shade700 : rank == 2 ? Colors.grey.shade600 : Colors.brown.shade400;
    final String rankTitle = rank == 1 ? '🥇 الفائز (المركز الأول)' : rank == 2 ? '🥈 المركز الثاني' : '🥉 المركز الثالث';
    final strengths = (q['strengths'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWinner ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isWinner ? Colors.amber.shade400 : Colors.grey.shade300, width: isWinner ? 1.8 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rankTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: badgeColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            q['forwarder_name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '\$${(q['total_cost_usd'] ?? 0)}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isWinner ? AppTheme.emerald : AppTheme.charcoal),
          ),
          const SizedBox(height: 4),
          Text('سماح: ${q['free_days_pod'] ?? 0} يوم  •  ترانزيت: ${q['transit_days'] ?? 0} يوم',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          const Divider(height: 14),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: strengths.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(s.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
