import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/copyable_data_helper.dart';

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
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SelectionArea(
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
                            ElevatedButton(
                              onPressed: _fetchBenchmark,
                              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildContent(isArabic),
        ),
      ),
    );
  }

  void _copyBenchmarkTSV(BuildContext context, bool isArabic) {
    final ranked = (_benchmarkData?['ranked_quotes'] as List<dynamic>?) ?? [];
    final code = _benchmarkData?['rfq_code'] ?? widget.rfqCode ?? 'RFQ';
    final buffer = StringBuffer();
    if (isArabic) {
      buffer.writeln('مقارنة عروض أسعار الشحن التنافسية — طلب $code');
      buffer.writeln('المركز\tشركة الشحن\tالسعر الإجمالي (\$)\tسماح الوصول (أيام)\tمدة الإبحار (أيام)\tالتقييم المركب (100)');
    } else {
      buffer.writeln('Freight Forwarder Benchmarking Comparison — $code');
      buffer.writeln('Rank\tForwarder\tTotal Price (\$)\tFree Days POD\tTransit Days\tComposite Score (/100)');
    }

    for (final q in ranked) {
      final rank = q['rank'] ?? '';
      final forwarder = q['forwarder_name'] ?? '';
      final price = q['total_cost_usd'] ?? 0;
      final freeDays = q['free_days_pod'] ?? 0;
      final transit = q['transit_days'] ?? 0;
      final score = (q['composite_score'] ?? 0).toString();
      buffer.writeln('$rank\t$forwarder\t$price\t$freeDays\t$transit\t$score');
    }

    CopyHelper.copy(
      context,
      buffer.toString(),
      customMessage: isArabic
          ? 'تم نسخ جدول مقارنة عروض الأسعار بنجاح'
          : 'Quotations benchmark copied successfully',
    );
  }

  Widget _buildContent(bool isArabic) {
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
                    Text(
                      isArabic
                          ? 'المفاضلة التنافسية وترتيب أفضل عروض الشحن'
                          : 'Freight Forwarder Benchmarking & Ranking',
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                    ),
                    Text(
                      isArabic
                          ? 'طلب عروض الأسعار: $code  •  تم تحليل ${ranked.length} عروض أسعار متنافسة'
                          : 'RFQ Code: $code  •  Analyzed ${ranked.length} competing quotations',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: AppTheme.cobalt, size: 20),
                tooltip: isArabic ? 'نسخ المقارنة (Excel)' : 'Copy Benchmark (Excel)',
                onPressed: () => _copyBenchmarkTSV(context, isArabic),
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
                          isArabic
                              ? 'التوصية التنفيذية لاعتماد العرض الفائز:'
                              : 'Executive Recommendation for Winning Quote:',
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
              children: ranked.take(3).map((q) => Expanded(child: _buildPodiumCard(q, isArabic))).toList(),
            ),
          const SizedBox(height: 20),

          // Full Benchmarking Table
          Text(
            isArabic
                ? '📊 المقارنة الشاملة لكافة عروض الأسعار:'
                : '📊 Comprehensive Quotations Comparison:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal),
          ),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  Padding(padding: const EdgeInsets.all(8), child: Text(isArabic ? 'المركز' : 'Rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(isArabic ? 'شركة الشحن / الوكيل' : 'Forwarder / Carrier', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(isArabic ? 'السعر الإجمالي (\$)' : 'Total Price (\$)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(isArabic ? 'سماح الوصول' : 'POD Free Time', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(isArabic ? 'مدة الإبحار' : 'Transit Time', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(isArabic ? 'التقييم المركب' : 'Composite Score', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
                      q['rank'] == 1
                          ? (isArabic ? '🥇 الأول' : '🥇 1st')
                          : q['rank'] == 2
                              ? (isArabic ? '🥈 الثاني' : '🥈 2nd')
                              : q['rank'] == 3
                                  ? (isArabic ? '🥉 الثالث' : '🥉 3rd')
                                  : '#${q['rank']}',
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
                    child: Text(
                      isArabic ? '${q['free_days_pod'] ?? 0} يوم' : '${q['free_days_pod'] ?? 0} days',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      isArabic ? '${q['transit_days'] ?? 0} يوم' : '${q['transit_days'] ?? 0} days',
                      style: const TextStyle(fontSize: 12),
                    ),
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

  Widget _buildPodiumCard(Map<String, dynamic> q, bool isArabic) {
    final rank = q['rank'] ?? 1;
    final isWinner = rank == 1;
    final Color badgeColor = rank == 1 ? Colors.amber.shade700 : rank == 2 ? Colors.grey.shade600 : Colors.brown.shade400;
    final String rankTitle = rank == 1
        ? (isArabic ? '🥇 الفائز (المركز الأول)' : '🥇 Winner (1st Place)')
        : rank == 2
            ? (isArabic ? '🥈 المركز الثاني' : '🥈 2nd Place')
            : (isArabic ? '🥉 المركز الثالث' : '🥉 3rd Place');
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
          Text(
            isArabic
                ? 'سماح: ${q['free_days_pod'] ?? 0} يوم  •  ترانزيت: ${q['transit_days'] ?? 0} يوم'
                : 'Free Days: ${q['free_days_pod'] ?? 0}  •  Transit: ${q['transit_days'] ?? 0} days',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
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
