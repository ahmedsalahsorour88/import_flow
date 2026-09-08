import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';

void showPartnerScorecardDialog(BuildContext context, WidgetRef ref, {
  required int providerId,
  required String providerName,
  required String providerType,
}) {
  showDialog(
    context: context,
    builder: (ctx) => PartnerScorecardDialog(
      providerId: providerId,
      providerName: providerName,
      providerType: providerType,
    ),
  );
}

class PartnerScorecardDialog extends ConsumerStatefulWidget {
  final int providerId;
  final String providerName;
  final String providerType;

  const PartnerScorecardDialog({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.providerType,
  });

  @override
  ConsumerState<PartnerScorecardDialog> createState() => _PartnerScorecardDialogState();
}

class _PartnerScorecardDialogState extends ConsumerState<PartnerScorecardDialog> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _scorecard;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _fetchScorecard();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _fetchScorecard() async {
    _cancelToken?.cancel();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(
        '/external-service-providers/${widget.providerId}/scorecard',
        cancelToken: cancelToken,
      );
      if (mounted) {
        setState(() {
          _scorecard = res.data is Map<String, dynamic> ? res.data : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (cancelToken.isCancelled) return;
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
    final l10n = context.l10n;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SelectionArea(
        child: Container(
          width: 800,
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
                            ElevatedButton(onPressed: _fetchScorecard, child: Text(l10n.retryConnectionBtn)),
                          ],
                        ),
                      ),
                    )
                  : _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    final compositeScore = (_scorecard?['composite_score'] as num?)?.toDouble() ?? 0.0;
    final tier = _scorecard?['performance_tier'] ?? 'Gold A';
    final stars = (_scorecard?['star_rating'] as num?)?.toDouble() ?? 4.0;
    final totalJobs = _scorecard?['total_jobs_evaluated'] ?? 0;
    final summary = _scorecard?['evaluation_summary_ar'] ?? '';
    final metrics = (_scorecard?['metrics'] as Map<String, dynamic>?) ?? {};
    final strengths = (_scorecard?['strengths'] as List<dynamic>?) ?? [];
    final improvements = (_scorecard?['improvement_areas'] as List<dynamic>?) ?? [];

    Color tierColor;
    if (tier.toString().contains('Platinum')) {
      tierColor = AppTheme.emerald;
    } else if (tier.toString().contains('Gold')) {
      tierColor = AppTheme.cobalt;
    } else if (tier.toString().contains('Silver')) {
      tierColor = AppTheme.orange;
    } else {
      tierColor = AppTheme.crimson;
    }

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
                  color: tierColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.workspace_premium_outlined, color: tierColor, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scorecardDialogTitle,
                      style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.scorecardPartnerSubtitle(widget.providerName, widget.providerType),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 18),

          // Score and Tier Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tierColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tierColor.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${compositeScore.toStringAsFixed(1)} / 100',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: tierColor),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < stars.floor()
                              ? Icons.star
                              : (index < stars ? Icons.star_half : Icons.star_border),
                          color: Colors.amber.shade700,
                          size: 18,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: tierColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.scorecardTierLabel(tier.toString()),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.scorecardTotalJobs(totalJobs is int ? totalJobs : int.tryParse(totalJobs.toString()) ?? 0),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(summary, style: TextStyle(color: Colors.grey.shade900, fontSize: 12.5, height: 1.3)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Detailed KPI Metrics Tiles
          if (metrics.isNotEmpty) ...[
            Text('📈 ${l10n.scorecardKpiHeader}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.charcoal)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: metrics.entries.map((entry) {
                final key = entry.key;
                final val = entry.value;
                String label = key;
                if (key == 'avg_clearance_turnaround_days') label = l10n.scorecardAvgClearanceDays;
                if (key == 'green_channel_rate_pct') label = l10n.scorecardGreenChannelRate;
                if (key == 'sla_adherence_rate_pct') label = l10n.scorecardSlaAdherenceRate;
                if (key == 'avg_arrival_delay_days') label = l10n.scorecardAvgArrivalDelayDays;
                if (key == 'schedule_reliability_pct') label = l10n.scorecardScheduleReliability;

                return Container(
                  width: 230,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                      const SizedBox(height: 4),
                      Text(
                        val is num ? val.toStringAsFixed(1) : val.toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
          ],

          // Strengths & Improvement
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (strengths.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💪 ${l10n.scorecardStrengthsHeader}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.emerald)),
                      const SizedBox(height: 6),
                      ...strengths.map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 15, color: AppTheme.emerald),
                            const SizedBox(width: 6),
                            Expanded(child: Text(s.toString(), style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              if (improvements.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ ${l10n.scorecardImprovementsHeader}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.orange)),
                      const SizedBox(height: 6),
                      ...improvements.map((im) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 15, color: AppTheme.orange),
                            const SizedBox(width: 6),
                            Expanded(child: Text(im.toString(), style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
